import 'dart:async';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_manager.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_squad.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/fc_squad_repository.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/squad_builder_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

PlayerCard _card(String id, String primary, [List<String> alt = const []]) =>
    PlayerCard(
      id: id,
      provider: 'TEST',
      playerName: 'Jogador $id',
      rating: 80,
      primaryPosition: primary,
      alternativePositions: alt,
    );

FormationSlot _slot(String code, String position, double x, double y) =>
    FormationSlot(
      slotCode: code,
      positionCode: position,
      x: x,
      y: y,
      sortOrder: 0,
    );

final _f442 = FormationDefinition(
  code: '4-4-2',
  displayName: '4-4-2',
  slots: <FormationSlot>[
    _slot('GK', 'GK', 0.5, 0.05),
    _slot('CB1', 'CB', 0.4, 0.25),
    _slot('CB2', 'CB', 0.6, 0.25),
  ],
);

final _f433 = FormationDefinition(
  code: '4-3-3',
  displayName: '4-3-3',
  slots: <FormationSlot>[
    _slot('GK', 'GK', 0.5, 0.05),
    _slot('CB', 'CB', 0.5, 0.25),
  ],
);

FcSquadDetail _detail({
  FormationDefinition? formation,
  List<SquadSlot> slots = const <SquadSlot>[],
  DateTime? updatedAt,
  int chemistry = 10,
}) => FcSquadDetail(
  id: 'squad-1',
  fcAccountId: 'account-1',
  name: 'Elenco',
  formation: formation ?? _f442,
  slots: slots,
  isDefault: true,
  benchSize: 7,
  chemistry: chemistry,
  updatedAt: updatedAt ?? DateTime.utc(2026, 10, 12, 10),
);

/// Repositorio de teste: conta chamadas para provar que editar o rascunho
/// nao toca no servidor.
class _FakeRepository implements FcSquadRepository {
  _FakeRepository({required this.detail});

  FcSquadDetail detail;
  int saveCalls = 0;
  int previewCalls = 0;
  AppFailure? saveFailure;
  int chemistry = 10;

  @override
  Future<FcSquadDetail> getBuilder(String squadId) async => detail;

  @override
  Future<List<FormationDefinition>> listFormations() async =>
      <FormationDefinition>[_f442, _f433];

  @override
  Future<int> previewChemistry({
    required String squadId,
    required String formationCode,
    required Map<String, String> slots,
    String? managerId,
    String? managerLeagueId,
  }) async {
    previewCalls++;
    return chemistry;
  }

  @override
  Future<FcSquadDetail> saveLineup({
    required String squadId,
    required String formationCode,
    required Map<String, String> slots,
    String? managerId,
    String? managerLeagueId,
    DateTime? expectedUpdatedAt,
  }) async {
    saveCalls++;
    final failure = saveFailure;
    if (failure != null) {
      throw failure;
    }
    detail = _detail(
      formation: formationCode == '4-3-3' ? _f433 : _f442,
      slots: <SquadSlot>[
        for (final entry in slots.entries)
          SquadSlot(
            type: SquadSlotType.starting,
            slotCode: entry.key,
            card: _card(entry.value, 'CB'),
          ),
      ],
      // O servidor devolve um updated_at NOVO: e isso que impede o segundo
      // save seguido de tomar conflito falso.
      updatedAt: DateTime.utc(2026, 10, 12, 11),
    );
    return detail;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} nao usado no teste');
}

void main() {
  late _FakeRepository repository;
  late SquadBuilderCubit cubit;

  setUp(() {
    repository = _FakeRepository(detail: _detail());
    cubit = SquadBuilderCubit(repository, squadId: 'squad-1');
  });

  tearDown(() => cubit.close());

  group('carga', () {
    test('baseline e draft nascem iguais e sem alteracoes pendentes', () async {
      await cubit.load();
      expect(cubit.state.status, SquadBuilderStatus.ready);
      expect(cubit.state.isDirty, isFalse);
      expect(cubit.state.canSave, isFalse);
      expect(cubit.state.chemistry, 10);
    });
  });

  group('rascunho local', () {
    test('escalar jogador nao chama o servidor', () async {
      await cubit.load();
      cubit.assignCard(slotCode: 'CB1', card: _card('a', 'CB'));
      expect(repository.saveCalls, 0);
      expect(cubit.state.isDirty, isTrue);
    });

    test('desfazer manualmente volta a nao ter alteracao', () async {
      await cubit.load();
      cubit.assignCard(slotCode: 'CB1', card: _card('a', 'CB'));
      expect(cubit.state.isDirty, isTrue);
      cubit.clearSlot('CB1');
      // isDirty compara conteudo, nao "houve toque".
      expect(cubit.state.isDirty, isFalse);
    });

    test('trocar por outro e voltar ao original tambem zera o dirty', () async {
      repository.detail = _detail(
        slots: <SquadSlot>[
          SquadSlot(
            type: SquadSlotType.starting,
            slotCode: 'CB1',
            card: _card('a', 'CB'),
          ),
        ],
      );
      await cubit.load();
      cubit.assignCard(slotCode: 'CB1', card: _card('b', 'CB'));
      expect(cubit.state.isDirty, isTrue);
      cubit.assignCard(slotCode: 'CB1', card: _card('a', 'CB'));
      expect(cubit.state.isDirty, isFalse);
    });

    test('o mesmo jogador nunca ocupa dois slots', () async {
      await cubit.load();
      final card = _card('a', 'CB');
      cubit.assignCard(slotCode: 'CB1', card: card);
      cubit.assignCard(slotCode: 'CB2', card: card);
      final starters = cubit.state.draft!.starters;
      expect(starters.length, 1);
      expect(starters['CB2']?.id, 'a');
    });

    test('tecnico entra no rascunho e nao persiste sozinho', () async {
      await cubit.load();
      cubit.setManager(
        manager: const FcManager(id: 'm1', name: 'Tecnico'),
      );
      expect(cubit.state.isDirty, isTrue);
      expect(repository.saveCalls, 0);
    });
  });

  group('troca de formacao', () {
    test('acontece no rascunho e remove quem nao cabe', () async {
      repository.detail = _detail(
        slots: <SquadSlot>[
          SquadSlot(
            type: SquadSlotType.starting,
            slotCode: 'CB1',
            card: _card('a', 'CB'),
          ),
          SquadSlot(
            type: SquadSlotType.starting,
            slotCode: 'CB2',
            card: _card('b', 'CB'),
          ),
        ],
      );
      await cubit.load();
      cubit.setFormation('4-3-3');

      expect(repository.saveCalls, 0);
      expect(cubit.state.draft!.formation.code, '4-3-3');
      // 4-3-3 do fixture tem um unico slot de zaga.
      expect(cubit.state.draft!.starters.length, 1);
      expect(cubit.state.droppedByFormationChange.length, 1);
    });

    test('nunca encaixa jogador em posicao incompativel', () async {
      repository.detail = _detail(
        slots: <SquadSlot>[
          SquadSlot(
            type: SquadSlotType.starting,
            slotCode: 'CB1',
            card: _card('atacante', 'ST'),
          ),
        ],
      );
      await cubit.load();
      cubit.setFormation('4-3-3');
      expect(cubit.state.draft!.starters, isEmpty);
      expect(cubit.state.droppedByFormationChange.single.id, 'atacante');
    });
  });

  group('save', () {
    test('chama a RPC atomica uma vez so e limpa o dirty', () async {
      await cubit.load();
      cubit.assignCard(slotCode: 'CB1', card: _card('a', 'CB'));
      final ok = await cubit.save();

      expect(ok, isTrue);
      expect(repository.saveCalls, 1);
      expect(cubit.state.isDirty, isFalse);
      expect(cubit.state.isSaving, isFalse);
    });

    test('adota o updated_at novo, entao o segundo save nao conflita', () async {
      await cubit.load();
      expect(cubit.state.baseline!.updatedAt, DateTime.utc(2026, 10, 12, 10));

      cubit.assignCard(slotCode: 'CB1', card: _card('a', 'CB'));
      await cubit.save();
      expect(cubit.state.baseline!.updatedAt, DateTime.utc(2026, 10, 12, 11));

      cubit.assignCard(slotCode: 'CB2', card: _card('b', 'CB'));
      final ok = await cubit.save();
      expect(ok, isTrue);
      expect(cubit.state.hasConflict, isFalse);
    });

    test('sem alteracao nao chama o servidor', () async {
      await cubit.load();
      final ok = await cubit.save();
      expect(ok, isFalse);
      expect(repository.saveCalls, 0);
    });

    test('erro preserva o rascunho intacto', () async {
      await cubit.load();
      cubit.assignCard(slotCode: 'CB1', card: _card('a', 'CB'));
      repository.saveFailure = const NetworkFailure();

      final ok = await cubit.save();
      expect(ok, isFalse);
      // O que a pessoa montou continua na tela.
      expect(cubit.state.draft!.starters['CB1']?.id, 'a');
      expect(cubit.state.isDirty, isTrue);
      expect(cubit.state.saveFailure, isNotNull);
    });
  });

  group('conflito de edicao', () {
    test('FQ049 vira estado de conflito e bloqueia salvar por cima', () async {
      await cubit.load();
      cubit.assignCard(slotCode: 'CB1', card: _card('a', 'CB'));
      repository.saveFailure = const SquadFailure(
        reason: SquadFailureReason.editConflict,
      );

      await cubit.save();
      expect(cubit.state.hasConflict, isTrue);
      // Sem forcar: com conflito aberto, salvar deixa de ser oferecido.
      expect(cubit.state.canSave, isFalse);
      expect(cubit.state.draft!.starters['CB1']?.id, 'a');
    });

    test('recarregar substitui baseline e rascunho e limpa o conflito', () async {
      await cubit.load();
      cubit.assignCard(slotCode: 'CB1', card: _card('a', 'CB'));
      repository.saveFailure = const SquadFailure(
        reason: SquadFailureReason.editConflict,
      );
      await cubit.save();

      repository
        ..saveFailure = null
        ..detail = _detail(updatedAt: DateTime.utc(2026, 10, 12, 12));
      await cubit.reloadAfterConflict();

      expect(cubit.state.hasConflict, isFalse);
      expect(cubit.state.isDirty, isFalse);
      expect(cubit.state.draft!.starters, isEmpty);
      expect(cubit.state.baseline!.updatedAt, DateTime.utc(2026, 10, 12, 12));
    });
  });

  group('preview', () {
    test('resposta de um rascunho antigo nao vence o atual', () async {
      await cubit.load();
      // Duas respostas: a primeira lenta com valor velho, a segunda rapida
      // com o valor certo.
      final slow = Completer<int>();
      final fast = Completer<int>();
      final racing = _RacingRepository(
        detail: repository.detail,
        responses: <Completer<int>>[slow, fast],
      );
      final raced = SquadBuilderCubit(racing, squadId: 'squad-1');
      await raced.load();

      // Sem await de proposito: as duas ficam pendentes ao mesmo tempo, que
      // e justamente a situacao que o contador de geracao existe para cobrir.
      unawaited(raced.debugPreviewNow());
      unawaited(raced.debugPreviewNow());

      fast.complete(31);
      await Future<void>.delayed(Duration.zero);
      expect(raced.state.chemistry, 31);

      slow.complete(7);
      await Future<void>.delayed(Duration.zero);
      // A resposta atrasada da geracao anterior e descartada.
      expect(raced.state.chemistry, 31);
      await raced.close();
    });
  });
}

class _RacingRepository extends _FakeRepository {
  _RacingRepository({required super.detail, required this.responses});

  final List<Completer<int>> responses;
  int _index = 0;

  @override
  Future<int> previewChemistry({
    required String squadId,
    required String formationCode,
    required Map<String, String> slots,
    String? managerId,
    String? managerLeagueId,
  }) => responses[_index++].future;
}
