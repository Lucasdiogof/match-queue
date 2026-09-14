import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/player_card_face.dart';
import 'package:flutter/material.dart';

enum SquadPlayerCardState { empty, filled, selected, outOfPosition }

/// Carta no campo. Preenchida, usa a MESMA carta visual do resto do app
/// ([PlayerCardFace] -- picker, catalogo, compartilhar): a pessoa ja
/// escolheu aquela carta, faz sentido ver a mesma arte no campo em vez de
/// uma versao simplificada so com foto e nome.
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
    this.onRemove,
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

  /// Some do slot com um toque -- alternativa mais descobrível ao toque
  /// longo, que continua funcionando igual. `null` quando o slot está vazio
  /// (nada para remover).
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isSelected = state == SquadPlayerCardState.selected;
    final card = this.card;

    return Semantics(
      button: true,
      selected: isSelected,
      label: card == null
          ? '$positionCode, vazio'
          : '${card.displayName}, $positionCode, ${card.rating}'
                '${chemistry == null ? '' : ', química $chemistry'}',
      child: SizedBox(
        width: width,
        height: width / aspectRatio,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            if (card == null)
              _EmptySlot(
                positionCode: positionCode,
                onTap: onTap,
                onLongPress: onLongPress,
              )
            else
              Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  PlayerCardFace(
                    card: card,
                    isSelected: isSelected,
                    onTap: isSaving ? null : onTap,
                    onLongPress: isSaving ? null : onLongPress,
                  ),
                  if (isSaving)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: AppRadii.borderMd,
                          color: colors.surface.withValues(alpha: 0.72),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: width * 0.28,
                            height: width * 0.28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
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
                bottom: 4,
                left: 4,
                child: _ChemistryPips(value: chemistry!, width: width),
              ),
            if (card != null && onRemove != null && !isSaving)
              Positioned(
                top: -8,
                right: -8,
                child: _RemoveButton(width: width, onPressed: onRemove!),
              ),
          ],
        ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.width, required this.onPressed});

  final double width;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final size = (width * 0.26).clamp(20.0, 28.0);
    return Material(
      color: context.colors.surfaceElevated,
      shape: const CircleBorder(side: BorderSide(color: Colors.black26)),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.close,
            size: size * 0.65,
            color: context.colors.textPrimary,
          ),
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
              border: Border.all(color: Colors.black38, width: 0.5),
            ),
          ),
      ],
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.positionCode, this.onTap, this.onLongPress});

  final String positionCode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      // Mesmo raio e cor de fundo da carta preenchida (PlayerCardFace): o
      // slot vazio deve ler como "a carta que vai entrar ali", nao como uma
      // caixa generica -- por isso raio md em vez de sm, igual ao card real.
      color: colors.surfaceElevated,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.borderMd,
        side: BorderSide(color: colors.borderSubtle),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
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
          },
        ),
      ),
    );
  }
}
