import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:flutter/material.dart';

/// Managers: auditado antes de implementar, como pedido.
///
/// `fc_managers` existe e tem uma RPC de busca (`search_fc_managers`), mas
/// hoje só guarda 24 registros `provider=LOCAL` com nomes fictícios
/// (dev/teste, usados só pelo seletor de técnico do Squad Builder) -- nunca
/// foi alimentado por uma fonte real de managers do FC 27, ao contrário de
/// `fc_player_cards` (Wrexist, real). Mostrar esses 24 como "o catálogo de
/// managers" seria inventar dado. Esta tela avisa o bloqueio em vez de
/// fingir uma listagem.
class ManagersCatalogPage extends StatelessWidget {
  const ManagersCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.catalogManagersEntryLabel),
      body: AppBackground(
        dense: true,
        child: AppEmptyState(
          icon: Icons.groups_2_outlined,
          title: l10n.managersBlockedTitle,
          message: l10n.managersBlockedMessage,
        ),
      ),
    );
  }
}
