import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:flutter/material.dart';

/// Faixas alfabéticas para nação/liga (gameplay flows refresh, itens 8-10).
/// Sem bucket "Popular": não existe critério real de popularidade no
/// catálogo hoje, e o pedido é explícito em não inventar um.
const List<(String label, String from, String to)> _alphabetRanges =
    <(String, String, String)>[
      ('A-C', 'A', 'C'),
      ('D-F', 'D', 'F'),
      ('G-I', 'G', 'I'),
      ('J-L', 'J', 'L'),
      ('M-O', 'M', 'O'),
      ('P-R', 'P', 'R'),
      ('S-U', 'S', 'U'),
      ('V-Z', 'V', 'Z'),
    ];

String _rangeLabelFor(String name) {
  final letter = name.isEmpty ? 'Z' : name[0].toUpperCase();
  for (final range in _alphabetRanges) {
    if (letter.compareTo(range.$2) >= 0 && letter.compareTo(range.$3) <= 0) {
      return range.$1;
    }
  }
  return _alphabetRanges.last.$1;
}

/// Seleção em 2 passos: faixa alfabética -> lista (com busca) dentro da
/// faixa. Usado por Nação (lista final) e por Liga quando é o primeiro
/// passo do fluxo hierárquico de Clube (item 10).
Future<String?> showAlphabeticalPickerSheet({
  required BuildContext context,
  required String title,
  required List<String> names,
}) => showAppBottomSheet<String>(
  context: context,
  builder: (sheetContext) =>
      _AlphabeticalPickerBody(title: title, names: names),
);

/// Lista simples, já rolável dentro de altura máxima (fix do overflow real
/// -- item 7). Usada quando a contagem não justifica agrupamento (Liga,
/// ~57 itens) e como passo final de Clube (clubes de UMA liga já escolhida).
Future<String?> showFlatCatalogPickerSheet({
  required BuildContext context,
  required String title,
  required List<String> names,
}) => showAppBottomSheet<String>(
  context: context,
  builder: (sheetContext) => _NameListBody(title: title, names: names),
);

class _AlphabeticalPickerBody extends StatefulWidget {
  const _AlphabeticalPickerBody({required this.title, required this.names});

  final String title;
  final List<String> names;

  @override
  State<_AlphabeticalPickerBody> createState() =>
      _AlphabeticalPickerBodyState();
}

class _AlphabeticalPickerBodyState extends State<_AlphabeticalPickerBody> {
  String? _selectedRange;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final range = _selectedRange;

    if (range == null) {
      final counts = <String, int>{};
      for (final name in widget.names) {
        final label = _rangeLabelFor(name);
        counts[label] = (counts[label] ?? 0) + 1;
      }
      final availableRanges = _alphabetRanges
          .where((r) => (counts[r.$1] ?? 0) > 0)
          .toList(growable: false);

      return AppBottomSheet(
        title: widget.title,
        isChildScrollable: true,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: availableRanges.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final r = availableRanges[index];
            return AppButton.secondary(
              label: '${r.$1} (${counts[r.$1]})',
              expanded: true,
              onPressed: () => setState(() => _selectedRange = r.$1),
            );
          },
        ),
      );
    }

    final filtered =
        widget.names.where((n) => _rangeLabelFor(n) == range).toList()..sort();

    return AppBottomSheet(
      title: range,
      isChildScrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _selectedRange = null),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(l10n.actionBack),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Flexible(
            child: filtered.isEmpty
                ? Text(l10n.squadPlayerPickerEmpty)
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => AppButton.secondary(
                      label: filtered[index],
                      expanded: true,
                      onPressed: () =>
                          Navigator.of(context).pop(filtered[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NameListBody extends StatelessWidget {
  const _NameListBody({required this.title, required this.names});

  final String title;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sorted = [...names]..sort();

    return AppBottomSheet(
      title: title,
      isChildScrollable: true,
      child: sorted.isEmpty
          ? Text(l10n.squadPlayerPickerEmpty)
          : ListView.separated(
              shrinkWrap: true,
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => AppButton.secondary(
                label: sorted[index],
                expanded: true,
                onPressed: () => Navigator.of(context).pop(sorted[index]),
              ),
            ),
    );
  }
}
