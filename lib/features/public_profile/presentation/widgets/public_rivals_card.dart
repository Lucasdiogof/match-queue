import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/rivals_division_l10n.dart';
import 'package:fifa_queue/features/game/presentation/widgets/competitive_mode_card.dart';
import 'package:flutter/material.dart';

/// Mesmo card de Rivals do perfil de um companheiro de time, so que
/// alimentado pelo payload PUBLICO (divisao + record manual). Divisao
/// traduzida -- antes ia crua ("DIV_1") direto do enum do banco.
class PublicRivalsCard extends StatelessWidget {
  const PublicRivalsCard({
    required this.rivalsDivision,
    required this.wins,
    required this.losses,
    super.key,
  });

  final String? rivalsDivision;
  final int wins;
  final int losses;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final division = RivalsDivision.tryFromKey(rivalsDivision);

    return CompetitiveModeCard(
      mode: CompetitiveMode.rivals,
      title: l10n.rivalsSectionTitle,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              division?.label(l10n) ?? l10n.fcAccountDivisionNone,
              style: const TextStyle(
                color: AppColors.darkTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$wins–$losses',
            style: const TextStyle(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
