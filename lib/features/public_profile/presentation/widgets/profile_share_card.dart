import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/features/public_profile/domain/entities/public_profile.dart';
import 'package:flutter/material.dart';

/// Template visual da identidade (avatar, nome, Conta). Rivals e Champions
/// tem cards proprios na tela ([RivalsCard]/[WeekendLeagueHistoryCard]) --
/// nao duplicados aqui em texto cru. Sempre com fallback decente quando
/// falta imagem -- nunca quebra layout.
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
        ],
      ),
    );
  }
}
