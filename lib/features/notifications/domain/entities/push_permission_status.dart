enum PushPermissionStatus {
  /// Ainda nao perguntamos. E o unico estado em que faz sentido mostrar o
  /// convite antes de disparar o dialogo do sistema.
  notDetermined,
  granted,

  /// iOS: entrega silenciosa na central de notificacoes, sem alerta.
  provisional,
  denied,

  /// A plataforma nao suporta push nesta build (Web sem configuracao, por
  /// exemplo). Diferente de "negado": nao ha o que o usuario possa fazer.
  unsupported;

  bool get canReceive =>
      this == PushPermissionStatus.granted ||
      this == PushPermissionStatus.provisional;

  bool get canAsk => this == PushPermissionStatus.notDetermined;
}

enum DevicePlatform {
  android('ANDROID'),
  ios('IOS'),
  web('WEB');

  const DevicePlatform(this.key);

  final String key;
}
