import 'package:fifa_queue/core/design_system/components/app_badge.dart';
import 'package:fifa_queue/features/history/domain/entities/match_search_status.dart';
import 'package:fifa_queue/features/history/domain/entities/stats_period.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';

extension MatchSearchStatusL10n on MatchSearchStatus {
  String label(AppLocalizations l10n) => switch (this) {
    MatchSearchStatus.matchFound => l10n.historyStatusMatchFoundLabel,
    MatchSearchStatus.cancelled => l10n.historyStatusCancelledLabel,
    MatchSearchStatus.expired => l10n.historyStatusExpiredLabel,
  };

  String filterLabel(AppLocalizations l10n) => switch (this) {
    MatchSearchStatus.matchFound => l10n.historyStatusMatchFound,
    MatchSearchStatus.cancelled => l10n.historyStatusCancelled,
    MatchSearchStatus.expired => l10n.historyStatusExpired,
  };

  AppBadgeTone get tone => switch (this) {
    MatchSearchStatus.matchFound => AppBadgeTone.success,
    MatchSearchStatus.cancelled => AppBadgeTone.neutral,
    MatchSearchStatus.expired => AppBadgeTone.warning,
  };
}

extension StatsPeriodL10n on StatsPeriod {
  String label(AppLocalizations l10n) => switch (this) {
    StatsPeriod.all => l10n.historyPeriodAll,
    StatsPeriod.last7Days => l10n.historyPeriod7,
    StatsPeriod.last30Days => l10n.historyPeriod30,
    StatsPeriod.last90Days => l10n.historyPeriod90,
  };
}

/// Duração compacta e neutra de idioma ("47s", "3min", "3min 12s"). As
/// abreviações min/s são comuns a PT/EN/ES, então não passam pelo l10n.
String formatSearchDuration(int seconds) {
  if (seconds < 60) {
    return '${seconds}s';
  }
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return rest == 0 ? '${minutes}min' : '${minutes}min ${rest}s';
}

/// Taxa 0..1 como percentual inteiro; "—" quando nula.
String formatSuccessRate(double? rate) =>
    rate == null ? '—' : '${(rate * 100).round()}%';
