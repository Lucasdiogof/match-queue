import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:flutter/material.dart';

class SquadNameResult {
  const SquadNameResult({required this.name, this.formationCode});

  final String name;
  final String? formationCode;
}

/// Serve para criar e para renomear: a diferença é só a formação aparecer ou
/// não, então não vale duplicar a tela.
Future<SquadNameResult?> showSquadNameSheet({
  required BuildContext context,
  required String title,
  String? subtitle,
  String initialName = '',
  List<FormationDefinition> formations = const <FormationDefinition>[],
  String? initialFormationCode,
}) => showAppBottomSheet<SquadNameResult>(
  context: context,
  builder: (sheetContext) => _SquadNameForm(
    title: title,
    subtitle: subtitle,
    initialName: initialName,
    formations: formations,
    initialFormationCode: initialFormationCode,
  ),
);

class _SquadNameForm extends StatefulWidget {
  const _SquadNameForm({
    required this.title,
    required this.initialName,
    required this.formations,
    this.subtitle,
    this.initialFormationCode,
  });

  final String title;
  final String? subtitle;
  final String initialName;
  final List<FormationDefinition> formations;
  final String? initialFormationCode;

  @override
  State<_SquadNameForm> createState() => _SquadNameFormState();
}

class _SquadNameFormState extends State<_SquadNameForm> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );
  late String? _formationCode =
      widget.initialFormationCode ??
      (widget.formations.isEmpty ? null : _preferredDefault());

  /// 4-4-2 é o default sugerido; se o catálogo não tiver, cai na primeira.
  String _preferredDefault() {
    for (final formation in widget.formations) {
      if (formation.code == '4-4-2') {
        return formation.code;
      }
    }
    return widget.formations.first.code;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid {
    final name = _controller.text.trim();
    return name.isNotEmpty && name.length <= 40;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppBottomSheet(
      title: widget.title,
      subtitle: widget.subtitle,
      actions: <Widget>[
        AppButton(
          label: l10n.actionSave,
          onPressed: _isValid
              ? () => Navigator.of(context).pop(
                  SquadNameResult(
                    name: _controller.text.trim(),
                    formationCode: _formationCode,
                  ),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.ghost(
          label: l10n.actionCancel,
          expanded: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            label: l10n.squadNameLabel,
            hintText: l10n.squadNameHint,
            controller: _controller,
            autofocus: true,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
          ),
          if (widget.formations.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.squadFormationLabel.toUpperCase(),
              style: context.textStyles.labelSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 120,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    for (final formation in widget.formations)
                      AppChip(
                        label: formation.displayName,
                        isSelected: _formationCode == formation.code,
                        onPressed: () =>
                            setState(() => _formationCode = formation.code),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
