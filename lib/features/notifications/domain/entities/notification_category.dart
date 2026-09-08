/// As 5 categorias de preferencia (item 20): agrupam os tipos de evento sem
/// virar um toggle por tipo. Espelha public.app_notification_category no
/// banco -- mesma ordem, mesmas chaves.
enum NotificationCategory {
  matchmaking('MATCHMAKING'),
  teams('TEAMS'),
  weekendLeague('WEEKEND_LEAGUE'),
  rivals('RIVALS'),
  rankings('RANKINGS');

  const NotificationCategory(this.key);

  final String key;

  static NotificationCategory? tryFromKey(Object? key) {
    for (final category in NotificationCategory.values) {
      if (category.key == key) {
        return category;
      }
    }
    return null;
  }
}
