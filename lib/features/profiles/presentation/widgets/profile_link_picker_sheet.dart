import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/profiles/domain/entities/profile.dart';
import 'package:flutter/material.dart';

/// "Quais Contas FC entram neste time?" -- usado ao entrar por convite
/// (gameplay flows refresh, item 16). Mesmo padrão de seleção usado dentro
/// do formulário de criar time: pré-seleciona se só houver uma conta, exige
/// pelo menos uma marcada pra confirmar. Com mais de uma conta, a que
/// estiver ativa no momento (selectedProfileId) também já nasce marcada --
/// continua multi-selecao (o usuario pode adicionar outras), so nao faz
/// quem ja estava usando uma conta especifica comecar do zero.
Future<Set<String>?> showProfileLinkPickerSheet({
  required BuildContext context,
  required List<Profile> profiles,
  String? selectedProfileId,
}) => showAppBottomSheet<Set<String>>(
  context: context,
  isDismissible: false,
  builder: (sheetContext) => _ProfileLinkPickerBody(
    profiles: profiles,
    selectedProfileId: selectedProfileId,
  ),
);

class _ProfileLinkPickerBody extends StatefulWidget {
  const _ProfileLinkPickerBody({
    required this.profiles,
    this.selectedProfileId,
  });

  final List<Profile> profiles;
  final String? selectedProfileId;

  @override
  State<_ProfileLinkPickerBody> createState() => _ProfileLinkPickerBodyState();
}

class _ProfileLinkPickerBodyState extends State<_ProfileLinkPickerBody> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    final activeId = widget.selectedProfileId;
    _selected = widget.profiles.length == 1
        ? <String>{widget.profiles.first.id}
        : <String>{
            if (activeId != null &&
                widget.profiles.any((a) => a.id == activeId))
              activeId,
          };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppBottomSheet(
      title: l10n.teamCreateProfilesSectionTitle,
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
          for (final profile in widget.profiles)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(profile.name),
              value: _selected.contains(profile.id),
              onChanged: (checked) => setState(() {
                if (checked ?? false) {
                  _selected.add(profile.id);
                } else {
                  _selected.remove(profile.id);
                }
              }),
            ),
        ],
      ),
    );
  }
}
