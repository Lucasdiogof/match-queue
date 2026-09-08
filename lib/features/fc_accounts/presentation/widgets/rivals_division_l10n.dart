import 'package:fifa_queue/features/fc_accounts/domain/entities/rivals_division.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';

extension RivalsDivisionL10n on RivalsDivision {
  String label(AppLocalizations l10n) => switch (this) {
    RivalsDivision.div10 => l10n.rivalsDivisionDiv10,
    RivalsDivision.div9 => l10n.rivalsDivisionDiv9,
    RivalsDivision.div8 => l10n.rivalsDivisionDiv8,
    RivalsDivision.div7 => l10n.rivalsDivisionDiv7,
    RivalsDivision.div6 => l10n.rivalsDivisionDiv6,
    RivalsDivision.div5 => l10n.rivalsDivisionDiv5,
    RivalsDivision.div4 => l10n.rivalsDivisionDiv4,
    RivalsDivision.div3 => l10n.rivalsDivisionDiv3,
    RivalsDivision.div2 => l10n.rivalsDivisionDiv2,
    RivalsDivision.div1 => l10n.rivalsDivisionDiv1,
    RivalsDivision.elite => l10n.rivalsDivisionElite,
  };
}
