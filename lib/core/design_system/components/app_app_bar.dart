import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_gradients.dart';
import 'package:fifa_queue/core/design_system/tokens/app_radii.dart';
import 'package:fifa_queue/core/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    this.title,
    this.subtitle,
    this.leading,
    this.actions = const <Widget>[],
    this.showDivider = false,
    this.accentTitle = false,
    super.key,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool showDivider;

  /// Titulo com o mesmo acento (barra de 3px em gradiente) que o antigo
  /// FeatureHeader tinha no corpo -- usado pelas raizes do shell (Central,
  /// Times, Jogar, Convites, Perfil, Historico), que agora tem o titulo
  /// grande na propria AppBar em vez de um FeatureHeader separado no corpo,
  /// mas nao queriam abrir mao da identidade visual que o acento dava.
  final bool accentTitle;

  /// Sem título nenhum (telas raiz do shell, que já têm o próprio título no
  /// corpo via [FeatureHeader]), a barra existe só pra caber as ações --
  /// não precisa da altura toda de uma barra com texto.
  @override
  Size get preferredSize =>
      Size.fromHeight(title == null ? 44 : (subtitle == null ? 56 : 72));

  @override
  Widget build(BuildContext context) => AppBar(
    leading: leading,
    automaticallyImplyLeading: leading == null,
    toolbarHeight: preferredSize.height,
    titleSpacing: AppSpacing.lg,
    title: title == null
        ? null
        : accentTitle
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 3,
                height: 26,
                decoration: const BoxDecoration(
                  gradient: AppGradients.brandAccent,
                  borderRadius: AppRadii.borderPill,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(title!, style: context.textStyles.titleLarge),
              if (subtitle != null)
                Text(subtitle!, style: context.textStyles.bodySmall),
            ],
          ),
    actions: <Widget>[
      ...actions,
      const SizedBox(width: AppSpacing.sm),
    ],
    bottom: showDivider
        ? PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: context.colors.borderSubtle),
          )
        : null,
  );
}
