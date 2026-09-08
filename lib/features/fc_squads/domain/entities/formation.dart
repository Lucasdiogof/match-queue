import 'package:equatable/equatable.dart';

/// Uma vaga da formação, vinda do catálogo do backend.
///
/// [x] e [y] são normalizados (0..1) de propósito: pixel não sobrevive à
/// troca de tela, proporção sim. [y] = 0 é o próprio gol e 1 é o gol
/// adversário; quem inverte para desenhar o goleiro embaixo é a UI.
class FormationSlot extends Equatable {
  const FormationSlot({
    required this.slotCode,
    required this.positionCode,
    required this.x,
    required this.y,
    required this.sortOrder,
  });

  final String slotCode;
  final String positionCode;
  final double x;
  final double y;
  final int sortOrder;

  @override
  List<Object?> get props => <Object?>[slotCode, positionCode, x, y, sortOrder];
}

class FormationDefinition extends Equatable {
  const FormationDefinition({
    required this.code,
    required this.displayName,
    required this.slots,
  });

  final String code;
  final String displayName;
  final List<FormationSlot> slots;

  @override
  List<Object?> get props => <Object?>[code, displayName, slots];
}
