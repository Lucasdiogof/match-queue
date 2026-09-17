import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/account/domain/entities/platform.dart';
import 'package:fifa_queue/features/account/presentation/cubit/account_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Multi-selecao: quem joga no PC e no console marca os dois e aparece nas
/// duas buscas. Nao existe mais a opcao "nenhuma" -- pelo menos uma tem que
/// ficar marcada, entao o sheet so confirma com a lista nao vazia (o RPC
/// recusa igual, esta checagem aqui e so pra nao levar o usuario ate o erro).
///
/// Confirma no botao em vez de salvar a cada toque: com multi-selecao, salvar
/// por toque geraria uma escrita por plataforma e um estado intermediario
/// vazio no meio da troca (desmarcar uma pra marcar outra).
Future<void> showPlatformPickerSheet({
  required BuildContext context,
  required List<Platform> selected,
}) async {
  final cubit = context.read<AccountCubit>();
  final result = await showAppBottomSheet<List<Platform>>(
    context: context,
    builder: (sheetContext) => _PlatformPickerBody(initial: selected),
  );
  if (result != null) {
    await cubit.updatePlatforms(result);
  }
}

class _PlatformPickerBody extends StatefulWidget {
  const _PlatformPickerBody({required this.initial});

  final List<Platform> initial;

  @override
  State<_PlatformPickerBody> createState() => _PlatformPickerBodyState();
}

class _PlatformPickerBodyState extends State<_PlatformPickerBody> {
  late final Set<Platform> _selected = <Platform>{...widget.initial};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppBottomSheet(
      title: l10n.accountPlatformPickerTitle,
      subtitle: l10n.accountPlatformPickerSubtitle,
      actions: <Widget>[
        AppButton(
          label: l10n.actionSave,
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selected.toList()),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.ghost(
          label: l10n.actionCancel,
          expanded: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final platform in Platform.values)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(platform.displayLabel),
              value: _selected.contains(platform),
              onChanged: (checked) => setState(() {
                if (checked ?? false) {
                  _selected.add(platform);
                } else {
                  _selected.remove(platform);
                }
              }),
            ),
        ],
      ),
    );
  }
}
