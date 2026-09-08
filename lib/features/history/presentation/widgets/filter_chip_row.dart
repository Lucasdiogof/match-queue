import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Uma linha de [AppChip]s com altura fixa e scroll horizontal quando nao
/// cabem -- em vez de um [Wrap] que quebra linha e desalinha a toolbar de
/// filtros do Historico (periodo/tipo/status empilhados com alturas
/// diferentes conforme a largura da tela). Puramente layout: nenhuma regra
/// de filtro muda, so como as opcoes sao desenhadas.
class FilterChipRow extends StatelessWidget {
  const FilterChipRow({required this.children, super.key});

  final List<Widget> children;

  static const double height = 40;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      itemCount: children.length,
      separatorBuilder: (context, index) =>
          const SizedBox(width: AppSpacing.sm),
      itemBuilder: (context, index) => children[index],
    ),
  );
}
