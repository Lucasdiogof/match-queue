import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/notifications/domain/entities/notification_category.dart';
import 'package:fifa_queue/features/notifications/domain/entities/push_notification_type.dart';

class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    this.queueTurnEnabled = true,
    this.searchExpiringEnabled = true,
    this.searchExpiredEnabled = true,
    this.priorityRequestedEnabled = true,
    this.matchmakingEnabled = true,
    this.teamsEnabled = true,
    this.weekendLeagueEnabled = true,
    this.rivalsEnabled = true,
    this.rankingsEnabled = true,
  });

  /// Ausencia de linha no backend significa tudo habilitado, entao o default
  /// do cliente precisa ser o mesmo para nao piscar valores diferentes.
  static const NotificationPreferences enabled = NotificationPreferences();

  final bool queueTurnEnabled;
  final bool searchExpiringEnabled;
  final bool searchExpiredEnabled;
  final bool priorityRequestedEnabled;

  /// Master switch da categoria Matchmaking -- as 3 colunas granulares acima
  /// continuam existindo, mas a UI so oferece este toggle unico (item 20).
  final bool matchmakingEnabled;
  final bool teamsEnabled;
  final bool weekendLeagueEnabled;
  final bool rivalsEnabled;
  final bool rankingsEnabled;

  bool isEnabled(PushNotificationType type) => switch (type) {
    PushNotificationType.yourTurn => matchmakingEnabled && queueTurnEnabled,
    PushNotificationType.searchExpiring =>
      matchmakingEnabled && searchExpiringEnabled,
    PushNotificationType.searchExpired =>
      matchmakingEnabled && searchExpiredEnabled,
    PushNotificationType.priorityRequested =>
      matchmakingEnabled && priorityRequestedEnabled,
  };

  bool isCategoryEnabled(NotificationCategory category) => switch (category) {
    NotificationCategory.matchmaking => matchmakingEnabled,
    NotificationCategory.teams => teamsEnabled,
    NotificationCategory.weekendLeague => weekendLeagueEnabled,
    NotificationCategory.rivals => rivalsEnabled,
    NotificationCategory.rankings => rankingsEnabled,
  };

  NotificationPreferences copyWithType(PushNotificationType type, bool value) =>
      switch (type) {
        PushNotificationType.yourTurn => _copyWith(queueTurnEnabled: value),
        PushNotificationType.searchExpiring => _copyWith(
          searchExpiringEnabled: value,
        ),
        PushNotificationType.searchExpired => _copyWith(
          searchExpiredEnabled: value,
        ),
        PushNotificationType.priorityRequested => _copyWith(
          priorityRequestedEnabled: value,
        ),
      };

  NotificationPreferences copyWithCategory(
    NotificationCategory category,
    bool value,
  ) => switch (category) {
    NotificationCategory.matchmaking => _copyWith(matchmakingEnabled: value),
    NotificationCategory.teams => _copyWith(teamsEnabled: value),
    NotificationCategory.weekendLeague => _copyWith(
      weekendLeagueEnabled: value,
    ),
    NotificationCategory.rivals => _copyWith(rivalsEnabled: value),
    NotificationCategory.rankings => _copyWith(rankingsEnabled: value),
  };

  NotificationPreferences _copyWith({
    bool? queueTurnEnabled,
    bool? searchExpiringEnabled,
    bool? searchExpiredEnabled,
    bool? priorityRequestedEnabled,
    bool? matchmakingEnabled,
    bool? teamsEnabled,
    bool? weekendLeagueEnabled,
    bool? rivalsEnabled,
    bool? rankingsEnabled,
  }) => NotificationPreferences(
    queueTurnEnabled: queueTurnEnabled ?? this.queueTurnEnabled,
    searchExpiringEnabled: searchExpiringEnabled ?? this.searchExpiringEnabled,
    searchExpiredEnabled: searchExpiredEnabled ?? this.searchExpiredEnabled,
    priorityRequestedEnabled:
        priorityRequestedEnabled ?? this.priorityRequestedEnabled,
    matchmakingEnabled: matchmakingEnabled ?? this.matchmakingEnabled,
    teamsEnabled: teamsEnabled ?? this.teamsEnabled,
    weekendLeagueEnabled: weekendLeagueEnabled ?? this.weekendLeagueEnabled,
    rivalsEnabled: rivalsEnabled ?? this.rivalsEnabled,
    rankingsEnabled: rankingsEnabled ?? this.rankingsEnabled,
  );

  @override
  List<Object?> get props => <Object?>[
    queueTurnEnabled,
    searchExpiringEnabled,
    searchExpiredEnabled,
    priorityRequestedEnabled,
    matchmakingEnabled,
    teamsEnabled,
    weekendLeagueEnabled,
    rivalsEnabled,
    rankingsEnabled,
  ];
}
