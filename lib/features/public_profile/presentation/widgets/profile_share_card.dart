import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/features/public_profile/domain/entities/public_profile.dart';
import 'package:flutter/material.dart';

/// Template visual do perfil (avatar, nome, Conta, Rivals, WL, record).
/// Sempre com fallback decente quando falta imagem -- nunca quebra layout.
class ProfileShareCard extends StatelessWidget {
  const ProfileShareCard({required this.profile, super.key});

  final PublicProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 360,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppAvatar(
                label: profile.displayName ?? '?',
                imageUrl: profile.avatarUrl,
                size: AppSizing.avatarLg,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      profile.displayName ?? '',
                      style: context.textStyles.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (profile.accountName != null)
                      Text(
                        profile.accountName!,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (profile.rivalsDivision != null ||
              profile.rivals != null ||
              profile.weekendLeague != null ||
              profile.stats != null) ...<Widget>[
            const AppDivider(spacing: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                if (profile.rivalsDivision != null)
                  _Stat(label: 'Rivals', value: profile.rivalsDivision!),
                if (profile.rivals != null)
                  _Stat(
                    label: 'Rivals W/L',
                    value: '${profile.rivals!.wins}-${profile.rivals!.losses}',
                  ),
                if (profile.weekendLeague != null)
                  _Stat(
                    label: 'WL',
                    value:
                        '${profile.weekendLeague!.wins}-${profile.weekendLeague!.losses}',
                  ),
                if (profile.stats != null)
                  _Stat(
                    label: 'W-L',
                    value: '${profile.stats!.wins}-${profile.stats!.losses}',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: context.colors.surfaceHighest,
      borderRadius: AppRadii.borderXs,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: context.textStyles.labelSmall?.copyWith(
            color: context.colors.textTertiary,
          ),
        ),
        Text(value, style: context.textStyles.titleSmall),
      ],
    ),
  );
}
