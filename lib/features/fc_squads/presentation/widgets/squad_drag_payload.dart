import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_squad.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squad_player_card.dart';
import 'package:flutter/material.dart';

/// Carga do drag: de onde a carta está saindo. O destino nunca precisa
/// declarar nada de si mesmo -- quem recebe o drop já sabe seu próprio
/// slot/tipo (é o widget local que chama a RPC de swap).
class SquadDragPayload extends Equatable {
  const SquadDragPayload({
    required this.type,
    required this.slotCode,
    required this.card,
  });

  final SquadSlotType type;
  final String slotCode;
  final PlayerCard card;

  @override
  List<Object?> get props => <Object?>[type, slotCode, card];
}

/// Envolve [SquadPlayerCard] com origem (Draggable, só se preenchido) e
/// destino (DragTarget, sempre) de drag and drop -- aditivo ao tap, que
/// continua funcionando exatamente como antes (item 36): soltar em cima de
/// outro slot chama [onAccept] com a MESMA RPC atômica de swap que o
/// tap-to-swap já usa, nunca um clear+set em dois passos.
///
/// Durante o arraste, o destino se pinta de verde (elegível/qualquer slot de
/// banco-reserva) ou âmbar (fora de posição) -- mas o drop NUNCA é
/// bloqueado, mesmo fora de posição (item 38).
///
/// [useLongPress] evita competir com o scroll horizontal do banco/reservas:
/// lá, iniciar o arraste exige toque longo; no campo (sem scroll) o arraste
/// começa direto.
class DraggableSquadSlot extends StatelessWidget {
  const DraggableSquadSlot({
    required this.type,
    required this.slotCode,
    required this.width,
    this.positionCode,
    this.card,
    this.state = SquadPlayerCardState.empty,
    this.chemistry,
    this.isSaving = false,
    this.useLongPress = false,
    this.onTap,
    this.onLongPress,
    this.onAccept,
    super.key,
  });

  final SquadSlotType type;
  final String slotCode;
  final double width;

  /// `null` para banco/reserva: nenhuma posição imposta, qualquer carta
  /// serve e o destaque de drag é sempre "elegível".
  final String? positionCode;
  final PlayerCard? card;
  final SquadPlayerCardState state;
  final int? chemistry;
  final bool isSaving;
  final bool useLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final void Function(SquadDragPayload payload)? onAccept;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final card = this.card;

    final target = DragTarget<SquadDragPayload>(
      onWillAcceptWithDetails: (details) =>
          !(details.data.type == type && details.data.slotCode == slotCode),
      onAcceptWithDetails: (details) => onAccept?.call(details.data),
      builder: (context, candidateData, rejectedData) {
        final incoming = candidateData.isNotEmpty ? candidateData.first : null;
        final eligible = incoming == null || positionCode == null
            ? true
            : incoming.card.canPlayIn(positionCode!);

        final child = SquadPlayerCard(
          positionCode: positionCode ?? (card?.primaryPosition ?? ''),
          width: width,
          card: card,
          state: state,
          isSaving: isSaving,
          chemistry: chemistry,
          onTap: onTap,
          onLongPress: onLongPress,
        );

        if (incoming == null) {
          return child;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AppRadii.borderSm,
                    color: (eligible ? colors.success : colors.warning)
                        .withValues(alpha: 0.22),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (card == null) {
      return target;
    }

    final payload = SquadDragPayload(
      type: type,
      slotCode: slotCode,
      card: card,
    );
    final feedback = Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: 0.9,
        child: SquadPlayerCard(
          positionCode: positionCode ?? card.primaryPosition,
          width: width,
          card: card,
          state: SquadPlayerCardState.filled,
        ),
      ),
    );
    final childWhenDragging = Opacity(opacity: 0.3, child: target);

    return useLongPress
        ? LongPressDraggable<SquadDragPayload>(
            data: payload,
            feedback: feedback,
            childWhenDragging: childWhenDragging,
            child: target,
          )
        : Draggable<SquadDragPayload>(
            data: payload,
            feedback: feedback,
            childWhenDragging: childWhenDragging,
            child: target,
          );
  }
}
