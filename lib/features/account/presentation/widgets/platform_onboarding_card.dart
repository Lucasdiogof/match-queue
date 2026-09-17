import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/features/account/domain/entities/platform.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/account/presentation/cubit/account_cubit.dart';
import 'package:fifa_queue/features/account/presentation/cubit/account_state.dart';
import 'package:fifa_queue/features/account/presentation/widgets/platform_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Ocupa o lugar do antigo card de "crie seu primeiro Perfil": agora o unico
/// passo que falta pra conta poder jogar e dizer em qual(is) plataforma(s)
/// ela joga, porque a fila e por plataforma.
class PlatformOnboardingCard extends StatelessWidget {
  const PlatformOnboardingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      variant: AppCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.accountPlatformOnboardingTitle,
            style: context.textStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.accountPlatformOnboardingMessage,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          BlocBuilder<AccountCubit, AccountState>(
            buildWhen: (previous, current) =>
                previous.account != current.account,
            builder: (context, state) => AppButton(
              label: l10n.accountPlatformOnboardingAction,
              icon: Icons.videogame_asset_outlined,
              onPressed: () => showPlatformPickerSheet(
                context: context,
                selected: state.account?.platforms ?? const <Platform>[],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
