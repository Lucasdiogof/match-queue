import 'package:fifa_queue/features/fc_squads/domain/entities/fc_squad.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';

abstract interface class FcSquadRepository {
  Future<List<FcSquadSummary>> listSquads(String fcAccountId);

  Future<List<FormationDefinition>> listFormations();

  Future<FcSquadDetail> getBuilder(String squadId);

  Future<FcSquadDetail> createSquad({
    required String fcAccountId,
    required String name,
    required String formationCode,
  });

  Future<FcSquadDetail> renameSquad({
    required String squadId,
    required String name,
  });

  Future<FcSquadDetail> setFormation({
    required String squadId,
    required String formationCode,
  });

  Future<FcSquadDetail> setDefault(String squadId);

  Future<void> archiveSquad(String squadId);

  Future<FcSquadDetail> setSlot({
    required String squadId,
    required SquadSlotType type,
    required String slotCode,
    required String playerCardId,
  });

  Future<FcSquadDetail> clearSlot({
    required String squadId,
    required SquadSlotType type,
    required String slotCode,
  });

  Future<FcSquadDetail> swapSlots({
    required String squadId,
    required SquadSlotType fromType,
    required String fromCode,
    required SquadSlotType toType,
    required String toCode,
  });

  Future<FcSquadDetail> setManager({
    required String squadId,
    String? managerId,
    String? managerLeagueId,
  });
}
