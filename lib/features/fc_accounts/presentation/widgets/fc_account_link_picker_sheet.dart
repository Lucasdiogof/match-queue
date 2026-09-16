import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:flutter/material.dart';

/// "Quais Contas FC entram neste time?" -- usado ao entrar por convite
/// (gameplay flows refresh, item 16). Mesmo padrão de seleção usado dentro
/// do formulário de criar time: pré-seleciona se só houver uma conta, exige
/// pelo menos uma marcada pra confirmar. Com mais de uma conta, a que
/// estiver ativa no momento (selectedAccountId) também já nasce marcada --
/// continua multi-selecao (o usuario pode adicionar outras), so nao faz
/// quem ja estava usando uma conta especifica comecar do zero.
Future<Set<String>?> showFcAccountLinkPickerSheet({
  required BuildContext context,
  required List<FcAccount> accounts,
  String? selectedAccountId,
}) => showAppBottomSheet<Set<String>>(
  context: context,
  isDismissible: false,
  builder: (sheetContext) => _FcAccountLinkPickerBody(
    accounts: accounts,
    selectedAccountId: selectedAccountId,
  ),
);

class _FcAccountLinkPickerBody extends StatefulWidget {
  const _FcAccountLinkPickerBody({
    required this.accounts,
    this.selectedAccountId,
  });

  final List<FcAccount> accounts;
  final String? selectedAccountId;

  @override
  State<_FcAccountLinkPickerBody> createState() =>
      _FcAccountLinkPickerBodyState();
}

class _FcAccountLinkPickerBodyState extends State<_FcAccountLinkPickerBody> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    final activeId = widget.selectedAccountId;
    _selected = widget.accounts.length == 1
        ? <String>{widget.accounts.first.id}
        : <String>{
            if (activeId != null &&
                widget.accounts.any((a) => a.id == activeId))
              activeId,
          };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppBottomSheet(
      title: l10n.teamCreateFcAccountsSectionTitle,
      isChildScrollable: true,
      actions: <Widget>[
        AppButton(
          label: l10n.actionContinue,
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selected),
        ),
      ],
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          for (final account in widget.accounts)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(account.name),
              value: _selected.contains(account.id),
              onChanged: (checked) => setState(() {
                if (checked ?? false) {
                  _selected.add(account.id);
                } else {
                  _selected.remove(account.id);
                }
              }),
            ),
        ],
      ),
    );
  }
}
