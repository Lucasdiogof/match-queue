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

  /// Grava o Elenco inteiro numa transacao. E o unico caminho de escrita do
  /// builder desde que a edicao virou rascunho local -- as RPCs por acao
  /// abaixo seguem existindo para nao quebrar nada, mas o builder nao as usa.
  ///
  /// [expectedUpdatedAt] e a baseline de concorrencia: veio do servidor ao
  /// carregar e volta aqui. Se o elenco mudou nesse meio tempo, o servidor
  /// recusa em vez de sobrescrever.
  Future<FcSquadDetail> saveLineup({
    required String squadId,
    required String formationCode,
    required Map<String, String> slots,
    String? managerId,
    String? managerLeagueId,
    DateTime? expectedUpdatedAt,
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

  /// Limpa todos os slots (titulares + banco + reservas) do squad. O squad
  /// em si nunca é apagado por aqui.
  Future<FcSquadDetail> clearSlots(String squadId);
}
