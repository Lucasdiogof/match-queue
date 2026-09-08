import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:flutter/material.dart';

enum SquadPlayerCardState { empty, filled, selected, outOfPosition }

/// Carta no campo ou no banco.
///
/// Sem arte de carta de propósito: nada aqui imita um visual oficial de EA
/// FC. É um card próprio do FIFA Queue, com iniciais no lugar da foto
/// enquanto o catálogo real não existe -- e o dia em que existir só troca o
/// miolo, não o formato.
class SquadPlayerCard extends StatelessWidget {
  const SquadPlayerCard({
    required this.positionCode,
    required this.width,
    this.card,
    this.state = SquadPlayerCardState.empty,
    this.isSaving = false,
    this.chemistry,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  /// Proporção fixa para todos os slots: nenhuma posição ganha card maior.
  static const double aspectRatio = 0.74;

  final String positionCode;
  final double width;
  final PlayerCard? card;
  final SquadPlayerCardState state;
  final bool isSaving;

  /// 0-3, só para titulares (Etapa 13). `null` para banco/reserva -- eles
  /// nunca entram na química, então não fazem sentido mostrar um número.
  final int? chemistry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isSelected = state == SquadPlayerCardState.selected;
    final isEmpty = card == null;

    final border = switch (state) {
      SquadPlayerCardState.selected => colors.textPrimary,
      SquadPlayerCardState.outOfPosition => colors.warning,
      _ => isEmpty ? colors.borderSubtle : colors.borderStrong,
    };

    return Semantics(
      button: true,
      selected: isSelected,
      label: isEmpty
          ? '$positionCode, vazio'
          : '${card!.displayName}, $positionCode, ${card!.rating}'
                '${chemistry == null ? '' : ', química $chemistry'}',
      child: SizedBox(
        width: width,
        height: width / aspectRatio,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Material(
              color: isEmpty
                  ? colors.surface.withValues(alpha: 0.72)
                  : colors.surfaceElevated,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadii.borderSm,
                side: BorderSide(color: border, width: isSelected ? 2 : 1),
              ),
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                child: Padding(
                  padding: EdgeInsets.all(width * 0.06),
                  child: isSaving
                      ? Center(
                          child: SizedBox(
                            width: width * 0.28,
                            height: width * 0.28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.textSecondary,
                            ),
                          ),
                        )
                      : isEmpty
                      ? _Empty(positionCode: positionCode, width: width)
                      : _Filled(
                          card: card!,
                          positionCode: positionCode,
                          width: width,
                        ),
                ),
              ),
            ),
            if (state == SquadPlayerCardState.outOfPosition)
              Positioned(
                top: -4,
                right: -4,
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: width * 0.24,
                  color: colors.warning,
                ),
              ),
            if (chemistry != null)
              Positioned(
                bottom: 2,
                left: 2,
                child: _ChemistryPips(value: chemistry!, width: width),
              ),
          ],
        ),
      ),
    );
  }
}

/// Três pontinhos (0-3) representando a química individual do titular. Nunca
/// aparece em banco/reserva (item 34/57) -- [chemistry] já vem `null` deles.
class _ChemistryPips extends StatelessWidget {
  const _ChemistryPips({required this.value, required this.width});

  final int value;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dotColor = switch (value) {
      0 => colors.textTertiary,
      1 => colors.warning,
      _ => colors.success,
    };
    final dot = width * 0.09;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < 3; i++)
          Container(
            width: dot,
            height: dot,
            margin: EdgeInsets.only(right: dot * 0.4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < value ? dotColor : colors.borderSubtle,
            ),
          ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.positionCode, required this.width});

  final String positionCode;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.add, size: width * 0.34, color: colors.textTertiary),
        SizedBox(height: width * 0.06),
        Text(
          positionCode,
          maxLines: 1,
          style: TextStyle(
            fontSize: width * 0.20,
            height: 1,
            letterSpacing: 0.4,
            fontWeight: FontWeight.w600,
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _Filled extends StatelessWidget {
  const _Filled({
    required this.card,
    required this.positionCode,
    required this.width,
  });

  final PlayerCard card;
  final String positionCode;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${card.rating}',
              style: TextStyle(
                fontSize: width * 0.26,
                height: 1,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            Text(
              positionCode,
              style: TextStyle(
                fontSize: width * 0.16,
                height: 1,
                fontWeight: FontWeight.w600,
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
        Center(
          child: Container(
            width: width * 0.40,
            height: width * 0.40,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.surfaceHighest,
              shape: BoxShape.circle,
              border: Border.all(color: colors.borderSubtle),
            ),
            // Carta real com foto usa a imagem; sem foto (ou catalogo de
            // dev, provider LOCAL) cai nas iniciais -- nunca um placeholder
            // quebrado (item 122).
            child: card.playerImageUrl == null
                ? _Initials(card: card, width: width)
                : Image.network(
                    card.playerImageUrl!,
                    fit: BoxFit.cover,
                    width: width * 0.40,
                    height: width * 0.40,
                    errorBuilder: (context, error, stackTrace) =>
                        _Initials(card: card, width: width),
                  ),
          ),
        ),
        Text(
          card.displayName,
          maxLines: 1,
          textAlign: TextAlign.center,
          // Nome longo trunca de forma controlada; o campo nunca alarga.
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: width * 0.155,
            height: 1.1,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.card, required this.width});

  final PlayerCard card;
  final double width;

  @override
  Widget build(BuildContext context) => Text(
    card.initials,
    style: TextStyle(
      fontSize: width * 0.17,
      height: 1,
      fontWeight: FontWeight.w600,
      color: context.colors.textSecondary,
    ),
  );
}
