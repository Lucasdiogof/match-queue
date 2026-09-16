import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/player_card_face.dart';
import 'package:flutter/material.dart';

/// Detalhe de carta do Mercado -- deliberadamente mais enxuto que o detalhe
/// completo do Squad Builder (showPlayerCardDetailSheet): aqui o motivo de
/// abrir e ver quanto a carta vale, nao montar escalacao. Rating, posicao e
/// atributos ja estao desenhados na propria arte da carta (PlayerCardFace),
/// entao repeti-los em badges/grade seria ruido -- playstyles e tipo de
/// carta (BASE_LAUNCH etc.) tambem saem por isso. [priceSection] e sempre
/// o widget de preco/favoritar, injetado pelo chamador (aba Mercado ou
/// Favoritos) para poder reagir ao proprio cubit de cada aba.
Future<void> showMarketCardSheet({
  required BuildContext context,
  required PlayerCard card,
  required Widget priceSection,
}) => showAppBottomSheet<void>(
  context: context,
  builder: (_) => AppBottomSheet(
    title: card.displayName,
    subtitle: <String?>[
      card.clubName,
      card.leagueName,
      card.nationName,
    ].whereType<String>().join(' · '),
    isChildScrollable: true,
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: PlayerCardFace(card: card),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          priceSection,
        ],
      ),
    ),
  ),
);
