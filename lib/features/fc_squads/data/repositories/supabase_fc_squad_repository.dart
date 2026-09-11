import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/fc_squads/data/datasources/fc_squad_remote_data_source.dart';
import 'package:fifa_queue/features/fc_squads/data/models/fc_squad_model.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_squad.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/fc_squad_repository.dart';

class SupabaseFcSquadRepository implements FcSquadRepository {
  const SupabaseFcSquadRepository(this._dataSource, this._errorMapper);

  final FcSquadRemoteDataSource _dataSource;
  final SupabaseErrorMapper _errorMapper;

  @override
  Future<List<FormationDefinition>> listFormations() => _guard(() async {
    final rows = await _dataSource.listFormations();
    return rows.map(FcSquadModel.formationFromJson).toList(growable: false);
  });

  @override
  Future<List<FcSquadSummary>> listSquads(String fcAccountId) => _guard(
    () async => FcSquadModel.summariesFromJson(
      await _dataSource.listSquads(fcAccountId),
    ),
  );

  @override
  Future<FcSquadDetail> getBuilder(String squadId) => _guard(
    () async =>
        FcSquadModel.detailFromJson(await _dataSource.getBuilder(squadId)),
  );

  @override
  Future<FcSquadDetail> createSquad({
    required String fcAccountId,
    required String name,
    required String formationCode,
  }) => _guard(
    () async => FcSquadModel.detailFromJson(
      await _dataSource.createSquad(
        fcAccountId: fcAccountId,
        name: name,
        formationCode: formationCode,
      ),
    ),
  );

  @override
  Future<FcSquadDetail> renameSquad({
    required String squadId,
    required String name,
  }) => _guard(
    () async => FcSquadModel.detailFromJson(
      await _dataSource.renameSquad(squadId: squadId, name: name),
    ),
  );

  @override
  Future<FcSquadDetail> saveLineup({
    required String squadId,
    required String formationCode,
    required Map<String, String> slots,
    String? managerId,
    String? managerLeagueId,
    DateTime? expectedUpdatedAt,
  }) => _guard(
    () async => FcSquadModel.detailFromJson(
      await _dataSource.saveLineup(
        squadId: squadId,
        formationCode: formationCode,
        slots: <Map<String, String>>[
          for (final entry in slots.entries)
            <String, String>{
              'slot_code': entry.key,
              'player_card_id': entry.value,
            },
        ],
        managerId: managerId,
        managerLeagueId: managerLeagueId,
        expectedUpdatedAt: expectedUpdatedAt,
      ),
    ),
  );

  @override
  Future<FcSquadDetail> setFormation({
    required String squadId,
    required String formationCode,
  }) => _guard(
    () async => FcSquadModel.detailFromJson(
      await _dataSource.setFormation(
        squadId: squadId,
        formationCode: formationCode,
      ),
    ),
  );

  @override
  Future<FcSquadDetail> setDefault(String squadId) => _guard(
    () async =>
        FcSquadModel.detailFromJson(await _dataSource.setDefault(squadId)),
  );

  @override
  Future<void> archiveSquad(String squadId) =>
      _guard(() => _dataSource.archiveSquad(squadId));

  @override
  Future<FcSquadDetail> setSlot({
    required String squadId,
    required SquadSlotType type,
    required String slotCode,
    required String playerCardId,
  }) => _guard(
    () async => FcSquadModel.detailFromJson(
      await _dataSource.setSlot(
        squadId: squadId,
        slotType: type.key,
        slotCode: slotCode,
        playerCardId: playerCardId,
      ),
    ),
  );

  @override
  Future<FcSquadDetail> clearSlot({
    required String squadId,
    required SquadSlotType type,
    required String slotCode,
  }) => _guard(
    () async => FcSquadModel.detailFromJson(
      await _dataSource.clearSlot(
        squadId: squadId,
        slotType: type.key,
        slotCode: slotCode,
      ),
    ),
  );

  @override
  Future<FcSquadDetail> swapSlots({
    required String squadId,
    required SquadSlotType fromType,
    required String fromCode,
    required SquadSlotType toType,
    required String toCode,
  }) => _guard(
    () async => FcSquadModel.detailFromJson(
      await _dataSource.swapSlots(
        squadId: squadId,
        fromType: fromType.key,
        fromCode: fromCode,
        toType: toType.key,
        toCode: toCode,
      ),
    ),
  );

  @override
  Future<FcSquadDetail> setManager({
    required String squadId,
    String? managerId,
    String? managerLeagueId,
  }) => _guard(
    () async => FcSquadModel.detailFromJson(
      await _dataSource.setManager(
        squadId: squadId,
        managerId: managerId,
        managerLeagueId: managerLeagueId,
      ),
    ),
  );

  @override
  Future<FcSquadDetail> clearSlots(String squadId) => _guard(
    () async =>
        FcSquadModel.detailFromJson(await _dataSource.clearSlots(squadId)),
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
