import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_gradients.dart';
import 'package:fifa_queue/core/design_system/tokens/app_radii.dart';
import 'package:fifa_queue/core/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// Header das telas raiz do shell (Central, Times, Jogar, Historico, Perfil).
///
/// So o titulo. As linhas de apoio sairam de proposito: "Catalogo, mecanicas
/// e controles do FC 27" descrevia para quem ja estava olhando a tela, e
/// empurrava o conteudo real para baixo em todo scroll. A hierarquia agora
/// vem de tamanho e de um acento curto, nao de uma segunda frase.
///
/// O acento e uma barra de 3px: presente o bastante para dar identidade,
/// pequeno o bastante para nao virar decoracao. Gradiente aqui e destaque
/// pontual -- e o unico do header.
class FeatureHeader extends StatelessWidget {
  const FeatureHeader({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: AppSpacing.xs,
      bottom: AppSpacing.lg,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: context.colors.textPrimary,
            ),
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: AppSpacing.md),
          trailing!,
        ],
      ],
    ),
  );
}
