/// Tipos de alerta que o backend sabe emitir hoje.
///
/// MATCH_FOUND e CANCELLED nao estao aqui de proposito: quem age ja sabe o
/// que fez, e os companheiros com o app aberto veem pelo Realtime. Push so
/// existe para o que a pessoa perderia estando fora do app.
enum PushNotificationType {
  yourTurn('YOUR_TURN'),
  searchExpiring('SEARCH_EXPIRING'),
  searchExpired('SEARCH_EXPIRED'),
  priorityRequested('PRIORITY_REQUESTED');

  const PushNotificationType(this.key);

  final String key;

  static PushNotificationType? fromKey(Object? key) {
    for (final type in PushNotificationType.values) {
      if (type.key == key) {
        return type;
      }
    }
    return null;
  }
}
