import 'package:fifa_queue/core/config/app_config.dart';
import 'package:flutter/foundation.dart';

sealed class InviteShareTarget {
  const InviteShareTarget();
}

final class InviteShareUrl extends InviteShareTarget {
  const InviteShareUrl(this.url);

  final String url;
}

final class InviteShareCodeOnly extends InviteShareTarget {
  const InviteShareCodeOnly(this.code);

  final String code;
}

/// Centraliza como o codigo de convite vira uma URL compartilhavel.
///
/// Nao ha dominio de producao definido ainda -- ver docs/database.md e o
/// relatorio da Etapa 4. Em vez de inventar um host, a ordem de prioridade
/// e: APP_LINK_HOST (quando configurado) > origin atual no Web > soh o
/// codigo (mobile sem host configurado, nada de URL HTTPS falsa).
class InviteLinkBuilder {
  const InviteLinkBuilder(this._config);

  final AppConfig _config;

  static const String _joinPath = '/join';

  InviteShareTarget build(String inviteCode) {
    if (_config.hasAppLinkHost) {
      return InviteShareUrl('https://${_config.appLinkHost}$_joinPath/$inviteCode');
    }
    if (kIsWeb) {
      return InviteShareUrl('${Uri.base.origin}$_joinPath/$inviteCode');
    }
    return InviteShareCodeOnly(inviteCode);
  }
}
