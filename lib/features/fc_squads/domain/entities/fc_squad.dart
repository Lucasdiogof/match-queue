import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_manager.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';

enum SquadSlotType {
  starting('STARTING'),
  bench('BENCH'),
  reserve('RESERVE');

  const SquadSlotType(this.key);

  final String key;

  static SquadSlotType fromKey(Object? key) => switch (key) {
    'BENCH' => SquadSlotType.bench,
    'RESERVE' => SquadSlotType.reserve,
    _ => SquadSlotType.starting,
  };
}

/// Slot PREENCHIDO. Slot vazio não existe como dado -- é a ausência desta
/// entrada, exatamente como no banco.
///
/// [chemistry] e [positionEligible] só existem para titulares (STARTING) --
/// banco e reserva nunca entram na química (Etapa 13), então ficam `null`/
/// `true` para eles.
class SquadSlot extends Equatable {
  const SquadSlot({
    required this.type,
    required this.slotCode,
    required this.card,
    this.chemistry,
    this.positionEligible = true,
  });

  final SquadSlotType type;
  final String slotCode;
  final PlayerCard card;
  final int? chemistry;
  final bool positionEligible;

  @override
  List<Object?> get props => <Object?>[
    type,
    slotCode,
    card,
    chemistry,
    positionEligible,
  ];
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
    this.reserveCount = 0,
    this.overall,
    this.chemistry = 0,
  });

  final String id;
  final String fcAccountId;
  final String name;
  final String formationCode;
  final bool isDefault;
  final int startingCount;
  final int benchCount;
  final int reserveCount;

  /// Média dos titulares preenchidos. `null` sem nenhum titular.
  final int? overall;

  /// 0-33, só titulares. Nunca inclui banco/reserva.
  final int chemistry;

  @override
  List<Object?> get props => <Object?>[
    id,
    fcAccountId,
    name,
    formationCode,
    isDefault,
    startingCount,
    benchCount,
    reserveCount,
    overall,
    chemistry,
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
    this.reserveSize = 0,
    this.overall,
    this.chemistry = 0,
    this.chemistryRuleVersion,
    this.filledStarters = 0,
    this.starterCount = 11,
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
  final int reserveSize;

  /// Média dos titulares preenchidos, `null` sem nenhum (nunca 0).
  final int? overall;

  /// 0-33, soma da química de cada titular. Banco/reserva nunca entram.
  final int chemistry;

  /// Versão da regra de química usada para calcular [chemistry]/
  /// [SquadSlot.chemistry] -- hoje sempre `FC_MODERN_V1`.
  final String? chemistryRuleVersion;
  final int filledStarters;
  final int starterCount;
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

  SquadSlot? slotAt(SquadSlotType type, String slotCode) {
    for (final slot in slots) {
      if (slot.type == type && slot.slotCode == slotCode) {
        return slot;
      }
    }
    return null;
  }

  int get startingCount =>
      slots.where((s) => s.type == SquadSlotType.starting).length;

  int get benchCount =>
      slots.where((s) => s.type == SquadSlotType.bench).length;

  int get reserveCount =>
      slots.where((s) => s.type == SquadSlotType.reserve).length;

  bool get isComplete => startingCount == formation.slots.length;

  bool get hasAnySlotFilled => slots.isNotEmpty;

  static String benchCodeAt(int index) => 'BENCH_${index + 1}';

  static String reserveCodeAt(int index) => 'RESERVE_${index + 1}';

  @override
  List<Object?> get props => <Object?>[
    id,
    fcAccountId,
    name,
    formation,
    slots,
    isDefault,
    benchSize,
    reserveSize,
    overall,
    chemistry,
    chemistryRuleVersion,
    filledStarters,
    starterCount,
    manager,
    managerLeague,
  ];
}
