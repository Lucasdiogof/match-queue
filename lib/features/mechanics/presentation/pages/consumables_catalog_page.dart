import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:flutter/material.dart';

/// Consumíveis: auditado antes de implementar.
///
/// Nenhuma tabela do catálogo hoje modela contrato, cartão de treino ou
/// qualquer outro consumível de Ultimate Team fora do Chemistry Style
/// (que já tem seção própria em Mecânicas, e não é duplicado aqui). Não há
/// dado real pra listar, então esta tela avisa isso em vez de inventar.
class ConsumablesCatalogPage extends StatelessWidget {
  const ConsumablesCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.catalogConsumablesEntryLabel),
      body: AppBackground(
        dense: true,
        child: AppEmptyState(
          icon: Icons.inventory_2_outlined,
          title: l10n.consumablesBlockedTitle,
          message: l10n.consumablesBlockedMessage,
        ),
      ),
    );
  }
}
