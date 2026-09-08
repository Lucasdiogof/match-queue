import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_manager.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';

enum SquadSlotType {
  starting('STARTING'),
  bench('BENCH');

  const SquadSlotType(this.key);

  final String key;

  static SquadSlotType fromKey(Object? key) =>
      key == 'BENCH' ? SquadSlotType.bench : SquadSlotType.starting;
}

/// Slot PREENCHIDO. Slot vazio não existe como dado -- é a ausência desta
/// entrada, exatamente como no banco.
class SquadSlot extends Equatable {
  const SquadSlot({
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

/// Linha de lista: o suficiente para "Meus Elencos" sem carregar o builder.
class FcSquadSummary extends Equatable {
  const FcSquadSummary({
    required this.id,
    required this.fcAccountId,
    required this.name,
    required this.formationCode,
    required this.isDefault,
    required this.startingCount,
    required this.benchCount,
  });

  final String id;
  final String fcAccountId;
  final String name;
  final String formationCode;
  final bool isDefault;
  final int startingCount;
  final int benchCount;

  @override
  List<Object?> get props => <Object?>[
    id,
    fcAccountId,
    name,
    formationCode,
    isDefault,
    startingCount,
    benchCount,
  ];
}

/// Estado completo do Squad Builder: uma chamada só traz squad, formação,
/// slots e técnico (evita N+1 e evita a UI ter conhecimento próprio de
/// formação).
class FcSquadDetail extends Equatable {
  const FcSquadDetail({
    required this.id,
    required this.fcAccountId,
    required this.name,
    required this.formation,
    required this.slots,
    required this.isDefault,
    required this.benchSize,
    this.manager,
    this.managerLeague,
  });

  final String id;
  final String fcAccountId;
  final String name;
  final FormationDefinition formation;
  final List<SquadSlot> slots;
  final bool isDefault;
  final int benchSize;
  final FcManager? manager;
  final FcLeague? managerLeague;

  PlayerCard? cardAt(SquadSlotType type, String slotCode) {
    for (final slot in slots) {
      if (slot.type == type && slot.slotCode == slotCode) {
        return slot.card;
      }
    }
    return null;
  }

  int get startingCount =>
      slots.where((s) => s.type == SquadSlotType.starting).length;

  int get benchCount =>
      slots.where((s) => s.type == SquadSlotType.bench).length;

  bool get isComplete => startingCount == formation.slots.length;

  static String benchCodeAt(int index) => 'BENCH_${index + 1}';

  @override
  List<Object?> get props => <Object?>[
    id,
    fcAccountId,
    name,
    formation,
    slots,
    isDefault,
    benchSize,
    manager,
    managerLeague,
  ];
}
