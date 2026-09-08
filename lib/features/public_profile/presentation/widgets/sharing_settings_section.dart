import 'dart:async' show Timer, unawaited;

import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/platform/public_profile_link_builder.dart';
import 'package:fifa_queue/core/platform/share_service.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:fifa_queue/features/public_profile/domain/repositories/public_profile_repository.dart';
import 'package:fifa_queue/features/public_profile/presentation/cubit/sharing_settings_cubit.dart';
import 'package:fifa_queue/features/public_profile/presentation/cubit/sharing_settings_state.dart';
import 'package:fifa_queue/features/public_profile/presentation/widgets/public_account_picker_sheet.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SharingSettingsSection extends StatelessWidget {
  const SharingSettingsSection({
    this.preselectFcAccountId,
    this.preselectShowSquad = false,
    super.key,
  });

  final String? preselectFcAccountId;
  final bool preselectShowSquad;

  @override
  Widget build(BuildContext context) => BlocProvider<SharingSettingsCubit>(
    create: (_) {
      final cubit = SharingSettingsCubit(getIt<PublicProfileRepository>());
      unawaited(
        cubit.load().then((_) {
          if (preselectFcAccountId != null || preselectShowSquad) {
            cubit.applyPreselect(
              fcAccountId: preselectFcAccountId,
              showSquad: preselectShowSquad,
            );
          }
        }),
      );
      return cubit;
    },
    child: const _SharingSettingsBody(),
  );
}

class _SharingSettingsBody extends StatefulWidget {
  const _SharingSettingsBody();

  @override
  State<_SharingSettingsBody> createState() => _SharingSettingsBodyState();
}

class _SharingSettingsBodyState extends State<_SharingSettingsBody> {
  final TextEditingController _slugController = TextEditingController();
  Timer? _debounce;
  String? _lastLoadedSlug;

  @override
  void dispose() {
    _debounce?.cancel();
    _slugController.dispose();
    super.dispose();
  }

  void _onSlugChanged(BuildContext context, String value) {
    context.read<SharingSettingsCubit>().setSlugDraft(value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) {
        return;
      }
      context.read<SharingSettingsCubit>().checkSlugAvailability(value);
    });
  }

  Future<void> _save(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<SharingSettingsCubit>().save();
    if (ok && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.publicProfileSaved)));
    }
  }

  Future<void> _copyLink(BuildContext context, String slug) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final target = getIt<PublicProfileLinkBuilder>().build(slug);
    final text = switch (target) {
      PublicProfileShareUrl(:final url) => url,
      PublicProfileShareSlugOnly(:final slug) => slug,
    };
    await getIt<ShareService>().copyToClipboard(text);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.publicProfileLinkCopied)),
    );
  }

  Future<void> _share(BuildContext context, String slug) async {
    final target = getIt<PublicProfileLinkBuilder>().build(slug);
    final text = switch (target) {
      PublicProfileShareUrl(:final url) => url,
      PublicProfileShareSlugOnly(:final slug) => slug,
    };
    await getIt<ShareService>().share(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<SharingSettingsCubit, SharingSettingsState>(
      listener: (context, state) {
        if (state.status == SharingSettingsStatus.ready &&
            state.saved.slug != _lastLoadedSlug) {
          _lastLoadedSlug = state.saved.slug;
          _slugController.text = state.saved.slug ?? '';
        }
      },
      builder: (context, state) {
        if (state.isLoading || state.status == SharingSettingsStatus.initial) {
          return const AppCard(
            child: SizedBox(height: 96, child: AppLoading()),
          );
        }

        if (state.status == SharingSettingsStatus.failure) {
          return AppCard(
            child: AppBanner(
              tone: AppBannerTone.danger,
              message:
                  state.failure?.localizedMessage(l10n) ?? l10n.errorUnexpected,
            ),
          );
        }

        final draft = state.draft;
        final linkTarget = draft.slug != null
            ? getIt<PublicProfileLinkBuilder>().build(draft.slug!)
            : null;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.publicProfileSectionTitle.toUpperCase(),
                style: context.textStyles.labelSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppBadge(
                label: draft.isEnabled
                    ? l10n.publicProfileStatusActive
                    : l10n.publicProfileStatusInactive,
                tone: draft.isEnabled
                    ? AppBadgeTone.success
                    : AppBadgeTone.neutral,
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.actionFailure != null) ...<Widget>[
                AppBanner(
                  tone: AppBannerTone.danger,
                  message: state.actionFailure!.localizedMessage(l10n),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.publicProfileMasterSwitchLabel,
                          style: context.textStyles.bodyLarge,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          l10n.publicProfileMasterSwitchHint,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: draft.isEnabled,
                    onChanged: (value) =>
                        context.read<SharingSettingsCubit>().setEnabled(value),
                  ),
                ],
              ),
              if (draft.isEnabled) ...<Widget>[
                const AppDivider(spacing: AppSpacing.lg),
                AppTextField(
                  label: l10n.publicProfileSlugLabel,
                  controller: _slugController,
                  hintText: l10n.publicProfileSlugHint,
                  helperText: _slugHelperText(l10n, state.slugAvailability),
                  onChanged: (value) => _onSlugChanged(context, value),
                ),
                const SizedBox(height: AppSpacing.md),
                BlocBuilder<FcAccountsCubit, FcAccountsState>(
                  builder: (context, fcState) {
                    final selected = fcState.accounts
                        .where((a) => a.id == draft.fcAccountId)
                        .toList();
                    final label = selected.isEmpty
                        ? l10n.publicProfileAccountEmpty
                        : selected.first.name;
                    return _NavRow(
                      icon: Icons.sports_esports_outlined,
                      label: l10n.publicProfileAccountLabel,
                      value: label,
                      onTap: fcState.accounts.isEmpty
                          ? null
                          : () => showPublicAccountPickerSheet(
                              context: context,
                              accounts: fcState.accounts,
                              selectedAccountId: draft.fcAccountId,
                            ),
                    );
                  },
                ),
                const AppDivider(spacing: AppSpacing.lg),
                _ToggleRow(
                  label: l10n.publicProfileToggleSquad,
                  value: draft.showSquad,
                  onChanged: (value) =>
                      context.read<SharingSettingsCubit>().setShowSquad(value),
                ),
                _ToggleRow(
                  label: l10n.publicProfileToggleWeekendLeague,
                  value: draft.showWeekendLeague,
                  onChanged: (value) => context
                      .read<SharingSettingsCubit>()
                      .setShowWeekendLeague(value),
                ),
                _ToggleRow(
                  label: l10n.publicProfileToggleRivals,
                  value: draft.showRivals,
                  onChanged: (value) =>
                      context.read<SharingSettingsCubit>().setShowRivals(value),
                ),
                _ToggleRow(
                  label: l10n.publicProfileToggleStats,
                  value: draft.showStats,
                  onChanged: (value) =>
                      context.read<SharingSettingsCubit>().setShowStats(value),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: l10n.publicProfileSaveAction,
                  icon: Icons.save_outlined,
                  isLoading: state.isSaving,
                  onPressed: state.isSaving ? null : () => _save(context),
                ),
                if (state.saved.isEnabled &&
                    state.saved.slug != null) ...<Widget>[
                  const AppDivider(spacing: AppSpacing.lg),
                  if (linkTarget is PublicProfileShareUrl)
                    Text(
                      linkTarget.url,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: AppButton.secondary(
                          label: l10n.publicProfileCopyLinkAction,
                          icon: Icons.copy_outlined,
                          onPressed: () =>
                              _copyLink(context, state.saved.slug!),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppButton(
                          label: l10n.publicProfileShareAction,
                          icon: Icons.ios_share,
                          onPressed: () => _share(context, state.saved.slug!),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  String? _slugHelperText(
    AppLocalizations l10n,
    SlugAvailability availability,
  ) => switch (availability) {
    SlugAvailability.checking => l10n.publicProfileSlugChecking,
    SlugAvailability.available => l10n.publicProfileSlugAvailable,
    SlugAvailability.unavailable => l10n.publicProfileSlugUnavailable,
    SlugAvailability.invalid => l10n.publicProfileSlugInvalid,
    SlugAvailability.idle => null,
  };
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: <Widget>[
            Icon(icon, size: AppSizing.iconMd, color: colors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: context.textStyles.bodyLarge)),
            Text(
              value,
              style: context.textStyles.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: <Widget>[
        Expanded(child: Text(label, style: context.textStyles.bodyLarge)),
        Switch(value: value, onChanged: onChanged),
      ],
    ),
  );
}
