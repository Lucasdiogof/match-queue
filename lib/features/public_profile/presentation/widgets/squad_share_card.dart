import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/features/public_profile/domain/entities/public_profile.dart';
import 'package:flutter/material.dart';

/// Template visual da escalação (formação, titulares, overall, química).
/// So titulares nesta V1 -- banco fica fora do card publico (mesma decisao
/// da RPC), documentado no handoff da Etapa 16.
class SquadShareCard extends StatelessWidget {
  const SquadShareCard({required this.squad, this.accountName, super.key});

  final PublicSquad squad;
  final String? accountName;

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(squad.name, style: context.textStyles.titleLarge),
                    if (accountName != null)
                      Text(
                        accountName!,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (squad.overall != null)
                _BadgeStat(label: 'OVR', value: '${squad.overall}'),
              const SizedBox(width: AppSpacing.sm),
              _BadgeStat(label: 'CHEM', value: '${squad.chemistry}'),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            squad.formationDisplayName,
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const AppDivider(spacing: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final starter in squad.starters)
                _StarterChip(starter: starter),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeStat extends StatelessWidget {
  const _BadgeStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Text(
        value,
        style: context.textStyles.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        label,
        style: context.textStyles.labelSmall?.copyWith(
          color: context.colors.textTertiary,
        ),
      ),
    ],
  );
}

class _StarterChip extends StatelessWidget {
  const _StarterChip({required this.starter});

  final PublicSquadStarter starter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 104,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceHighest,
        borderRadius: AppRadii.borderSm,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                '${starter.rating}',
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                starter.position,
                style: context.textStyles.labelSmall?.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
          ClipOval(
            child: starter.imageUrl != null
                ? Image.network(
                    starter.imageUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _PlayerFallback(name: starter.playerName),
                  )
                : _PlayerFallback(name: starter.playerName),
          ),
          Text(
            starter.playerName,
            style: context.textStyles.bodySmall,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            'CHEM ${starter.chemistry}',
            style: context.textStyles.labelSmall?.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerFallback extends StatelessWidget {
  const _PlayerFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    color: context.colors.surfaceElevated,
    alignment: Alignment.center,
    child: Icon(
      Icons.person,
      size: AppSizing.iconMd,
      color: context.colors.textTertiary,
    ),
  );
}
