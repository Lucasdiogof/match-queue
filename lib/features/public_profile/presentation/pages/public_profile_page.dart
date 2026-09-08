import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/core/platform/share_service.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';
import 'package:fifa_queue/features/public_profile/domain/repositories/public_profile_repository.dart';
import 'package:fifa_queue/features/public_profile/presentation/cubit/public_profile_view_cubit.dart';
import 'package:fifa_queue/features/public_profile/presentation/cubit/public_profile_view_state.dart';
import 'package:fifa_queue/features/public_profile/presentation/widgets/profile_share_card.dart';
import 'package:fifa_queue/features/public_profile/presentation/widgets/share_capture.dart';
import 'package:fifa_queue/features/public_profile/presentation/widgets/squad_share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Funciona sem sessao nenhuma -- nunca redireciona anon pro login. Um
/// usuario autenticado tambem pode abrir a mesma rota (vendo o proprio
/// perfil, com um CTA extra, ou o de outra pessoa).
class PublicProfilePage extends StatelessWidget {
  const PublicProfilePage({required this.identifier, super.key});

  final String identifier;

  @override
  Widget build(BuildContext context) => BlocProvider<PublicProfileViewCubit>(
    create: (_) => PublicProfileViewCubit(
      getIt<PublicProfileRepository>(),
      getIt<AuthRepository>(),
    )..load(identifier),
    child: _PublicProfileBody(identifier: identifier),
  );
}

class _PublicProfileBody extends StatefulWidget {
  const _PublicProfileBody({required this.identifier});

  final String identifier;

  @override
  State<_PublicProfileBody> createState() => _PublicProfileBodyState();
}

class _PublicProfileBodyState extends State<_PublicProfileBody> {
  final GlobalKey _profileCardKey = GlobalKey();
  final GlobalKey _squadCardKey = GlobalKey();

  Future<void> _shareProfileImage(BuildContext context) =>
      _shareImage(context, _profileCardKey, 'perfil-${widget.identifier}.png');

  Future<void> _shareSquadImage(BuildContext context) =>
      _shareImage(context, _squadCardKey, 'escalacao-${widget.identifier}.png');

  Future<void> _shareImage(
    BuildContext context,
    GlobalKey key,
    String fileName,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await ShareCapture.captureBoundary(key);
      if (bytes == null) {
        throw Exception('capture failed');
      }
      await getIt<ShareService>().shareImage(bytes, fileName: fileName);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.publicProfileShareImageError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.publicProfilePageTitle),
      body: BlocBuilder<PublicProfileViewCubit, PublicProfileViewState>(
        builder: (context, state) {
          switch (state.status) {
            case PublicProfileViewStatus.loading:
              return const AppLoading();
            case PublicProfileViewStatus.notFound:
              return AppEmptyState(
                title: l10n.publicProfileNotFoundTitle,
                message: l10n.publicProfileNotFoundMessage,
              );
            case PublicProfileViewStatus.failure:
              return AppErrorState(
                title: l10n.errorUnexpected,
                message:
                    state.failure?.localizedMessage(l10n) ??
                    l10n.errorUnexpected,
                retryLabel: l10n.actionRetry,
                onRetry: () => context.read<PublicProfileViewCubit>().load(
                  widget.identifier,
                ),
              );
            case PublicProfileViewStatus.ready:
              final profile = state.profile!;
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: <Widget>[
                  if (state.isOwner) ...<Widget>[
                    AppButton.secondary(
                      label: l10n.publicProfileEditSharingCta,
                      icon: Icons.settings_outlined,
                      onPressed: () =>
                          context.push(AppRoutes.profileSharing.path),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  RepaintBoundary(
                    key: _profileCardKey,
                    child: ProfileShareCard(profile: profile),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton.secondary(
                    label: l10n.publicProfileShareImageAction,
                    icon: Icons.image_outlined,
                    onPressed: () => _shareProfileImage(context),
                  ),
                  if (profile.squad != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xl),
                    RepaintBoundary(
                      key: _squadCardKey,
                      child: SquadShareCard(
                        squad: profile.squad!,
                        accountName: profile.accountName,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton.secondary(
                      label: l10n.publicProfileShareImageAction,
                      icon: Icons.image_outlined,
                      onPressed: () => _shareSquadImage(context),
                    ),
                  ],
                ],
              );
          }
        },
      ),
    );
  }
}
