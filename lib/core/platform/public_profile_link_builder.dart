import 'package:fifa_queue/core/config/app_config.dart';
import 'package:flutter/foundation.dart';

sealed class PublicProfileShareTarget {
  const PublicProfileShareTarget();
}

final class PublicProfileShareUrl extends PublicProfileShareTarget {
  const PublicProfileShareUrl(this.url);

  final String url;
}

final class PublicProfileShareSlugOnly extends PublicProfileShareTarget {
  const PublicProfileShareSlugOnly(this.slug);

  final String slug;
}

/// Mesma logica do `InviteLinkBuilder`: APP_LINK_HOST configurado > origin
/// atual no Web > so o slug (mobile sem host configurado -- nunca inventa
/// URL HTTPS falsa). O deep link do app abrindo a mesma rota publica ja
/// cobre o caso mobile -- universal links nativos completos (que dependeriam
/// de apple-app-site-association hospedado) ficam fora do escopo da Etapa 16.
class PublicProfileLinkBuilder {
  const PublicProfileLinkBuilder(this._config);

  final AppConfig _config;

  static const String _publicPath = '/u';

  PublicProfileShareTarget build(String slug) {
    if (_config.hasAppLinkHost) {
      return PublicProfileShareUrl(
        'https://${_config.appLinkHost}$_publicPath/$slug',
      );
    }
    if (kIsWeb) {
      return PublicProfileShareUrl('${Uri.base.origin}$_publicPath/$slug');
    }
    return PublicProfileShareSlugOnly(slug);
  }
}
