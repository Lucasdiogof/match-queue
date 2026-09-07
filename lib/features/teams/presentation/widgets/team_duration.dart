import 'package:fifa_queue/l10n/generated/app_localizations.dart';

class TeamDurationOptions {
  const TeamDurationOptions._();

  static const List<int> values = <int>[30, 60, 120, 180, 300];
}

String teamDurationLabel(AppLocalizations l10n, int seconds) {
  if (seconds < 60) {
    return l10n.teamDurationSeconds(seconds);
  }
  return l10n.teamDurationMinutes(seconds ~/ 60);
}
