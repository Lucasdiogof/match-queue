import 'dart:async';

import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/app_locales.dart';
import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:fifa_queue/features/profile/domain/repositories/profile_repository.dart';
import 'package:fifa_queue/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Espelha o idioma efetivo para `profiles.locale` no backend, **só escrita**.
///
/// Precedência: a preferência local (LocaleCubit) manda na UI; a cópia remota
/// existe unicamente para o worker de push redigir a notificação no idioma
/// certo. Nunca é lida de volta — ler reabriria um laço com a preferência
/// local. Escreve no login e a cada troca de idioma; é best-effort.
class LocaleSyncListener extends StatefulWidget {
  const LocaleSyncListener({required this.child, super.key});

  final Widget child;

  @override
  State<LocaleSyncListener> createState() => _LocaleSyncListenerState();
}

class _LocaleSyncListenerState extends State<LocaleSyncListener> {
  @override
  void initState() {
    super.initState();
    if (context.read<AuthCubit>().state.isAuthenticated) {
      unawaited(_sync(context.read<LocaleCubit>().state));
    }
  }

  Future<void> _sync(Locale? explicit) async {
    if (!context.read<AuthCubit>().state.isAuthenticated) {
      return;
    }
    final tag = _effectiveTag(explicit);
    try {
      await getIt<ProfileRepository>().updateLocale(tag);
    } on Object catch (error) {
      getIt<AppLogger>().warning('Falha ao sincronizar locale do profile: $error');
    }
  }

  String _effectiveTag(Locale? explicit) {
    final locale =
        explicit ??
        AppLocales.resolve(
          WidgetsBinding.instance.platformDispatcher.locale,
          AppLocales.supported,
        );
    return locale.toLanguageTag();
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: <BlocListener<dynamic, dynamic>>[
      BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            !previous.isAuthenticated && current.isAuthenticated,
        listener: (context, _) =>
            unawaited(_sync(context.read<LocaleCubit>().state)),
      ),
      BlocListener<LocaleCubit, Locale?>(
        listener: (context, locale) => unawaited(_sync(locale)),
      ),
    ],
    child: widget.child,
  );
}
