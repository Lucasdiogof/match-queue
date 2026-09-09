import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_breakpoints.dart';
import 'package:fifa_queue/core/design_system/tokens/app_radii.dart';
import 'package:fifa_queue/core/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool isScrollControlled = true,
}) => showModalBottomSheet<T>(
  context: context,
  isDismissible: isDismissible,
  isScrollControlled: isScrollControlled,
  useSafeArea: true,
  constraints: const BoxConstraints(
    maxWidth: AppBreakpoints.maxBottomSheetWidth,
  ),
  builder: builder,
);

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    required this.child,
    this.title,
    this.subtitle,
    this.actions = const <Widget>[],
    this.isChildScrollable = false,
    super.key,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final List<Widget> actions;

  /// `true` quando [child] é uma lista potencialmente longa (ex.: nações,
  /// ligas, clubes) que já vem embrulhada num `ListView`/scrollable próprio.
  /// Sem isso, o sheet crescia até o conteúdo inteiro caber -- para uma
  /// lista de centenas de itens isso estoura a viewport (RenderFlex
  /// overflow). Com `true`, a sheet ganha altura máxima e [child] recebe o
  /// espaço restante via `Expanded`, cabendo ao próprio [child] rolar.
  /// Título/subtítulo/ações continuam fixos fora da área rolável.
  final bool isChildScrollable;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    final header = <Widget>[
      if (title != null) Text(title!, style: context.textStyles.headlineSmall),
      if (subtitle != null) ...<Widget>[
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle!, style: context.textStyles.bodyMedium),
      ],
      if (title != null || subtitle != null)
        const SizedBox(height: AppSpacing.xl),
    ];
    final footer = <Widget>[
      if (actions.isNotEmpty) ...<Widget>[
        const SizedBox(height: AppSpacing.xl),
        ...actions,
      ],
    ];

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: isChildScrollable
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ...header,
                Flexible(child: child),
                ...footer,
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[...header, child, ...footer],
            ),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: isChildScrollable
              ? BoxConstraints(maxHeight: maxHeight)
              : const BoxConstraints(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderStrong,
                    borderRadius: AppRadii.borderPill,
                  ),
                ),
              ),
              isChildScrollable ? Flexible(child: content) : content,
            ],
          ),
        ),
      ),
    );
  }
}
