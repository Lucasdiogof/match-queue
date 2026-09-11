import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_manager.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_squad.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/lineup_draft.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/fc_squads/domain/lineup_remap.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/fc_squad_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum SquadBuilderStatus { loading, ready, failure }

enum LineupPreviewStatus { idle, updating, failure }

class SquadBuilderState extends Equatable {
  const SquadBuilderState({
    this.status = SquadBuilderStatus.loading,
    this.baseline,
    this.draft,
    this.formations = const <FormationDefinition>[],
    this.chemistry,
    this.previewStatus = LineupPreviewStatus.idle,
    this.isSaving = false,
    this.failure,
    this.saveFailure,
    this.hasConflict = false,
    this.droppedByFormationChange = const <PlayerCard>[],
  });

  final SquadBuilderStatus status;

  /// O que o servidor confirmou. Nunca alterado por edicao local.
  final FcSquadDetail? baseline;

  /// O que o usuario esta montando.
  final LineupDraft? draft;

  final List<FormationDefinition> formations;

  /// Quimica correspondente ao rascunho. Vem do servidor -- ver
  /// [LineupDraft.overall] para o porque de overall ser a excecao.
  final int? chemistry;
  final LineupPreviewStatus previewStatus;

  final bool isSaving;
  final AppFailure? failure;
  final AppFailure? saveFailure;

  /// Elenco alterado em outro aparelho. Nao e "erro de save": a saida e
  /// recarregar, e salvar por cima fica bloqueado ate isso acontecer.
  final bool hasConflict;

  /// Quem saiu na ultima troca de formacao. E feedback da operacao, nao um
  /// lugar onde jogadores ficam guardados -- some na proxima mutacao.
  final List<PlayerCard> droppedByFormationChange;

  /// Diferenca REAL entre rascunho e baseline. Trocar um jogador e voltar ao
  /// anterior devolve false, porque compara conteudo e nao "houve toque".
  bool get isDirty {
    final current = draft;
    final saved = baseline;
    if (current == null || saved == null) {
      return false;
    }
    return current.fingerprint != LineupDraft.fromDetail(saved).fingerprint;
  }

  bool get canSave => isDirty && !isSaving && !hasConflict;

  int? get overall => draft?.overall;

  SquadBuilderState copyWith({
    SquadBuilderStatus? status,
    FcSquadDetail? baseline,
    LineupDraft? draft,
    List<FormationDefinition>? formations,
    int? chemistry,
    bool clearChemistry = false,
    LineupPreviewStatus? previewStatus,
    bool? isSaving,
    AppFailure? failure,
    bool clearFailure = false,
    AppFailure? saveFailure,
    bool clearSaveFailure = false,
    bool? hasConflict,
    List<PlayerCard>? droppedByFormationChange,
  }) => SquadBuilderState(
    status: status ?? this.status,
    baseline: baseline ?? this.baseline,
    draft: draft ?? this.draft,
    formations: formations ?? this.formations,
    chemistry: clearChemistry ? null : (chemistry ?? this.chemistry),
    previewStatus: previewStatus ?? this.previewStatus,
    isSaving: isSaving ?? this.isSaving,
    failure: clearFailure ? null : (failure ?? this.failure),
    saveFailure: clearSaveFailure ? null : (saveFailure ?? this.saveFailure),
    hasConflict: hasConflict ?? this.hasConflict,
    droppedByFormationChange:
        droppedByFormationChange ?? this.droppedByFormationChange,
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    baseline,
    draft,
    formations,
    chemistry,
    previewStatus,
    isSaving,
    failure,
    saveFailure,
    hasConflict,
    droppedByFormationChange,
  ];
}

/// Editor do Elenco.
///
/// Antes cada toque ia direto ao servidor por uma RPC propria. Agora toda
/// edicao acontece no rascunho e so `save()` persiste, numa transacao.
///
/// As RPCs por acao continuam existindo e funcionando; este cubit apenas
/// deixou de usa-las. A limpeza delas e uma rodada separada, depois do fluxo
/// novo rodar com dados reais.
class SquadBuilderCubit extends Cubit<SquadBuilderState> {
  SquadBuilderCubit(this._repository, {required this.squadId})
    : super(const SquadBuilderState());

  final FcSquadRepository _repository;
  final String squadId;

  Timer? _previewDebounce;

  /// Contador de geracao do preview. Sem ele, uma resposta lenta de um
  /// rascunho antigo chegaria depois de uma rapida do rascunho novo e
  /// sobrescreveria a quimica correta. Debounce sozinho nao resolve isso --
  /// so reduz a frequencia.
  int _previewGeneration = 0;

  static const Duration _previewDelay = Duration(milliseconds: 300);

  Future<void> load() async {
    emit(
      state.copyWith(status: SquadBuilderStatus.loading, clearFailure: true),
    );
    try {
      final formations = state.formations.isEmpty
          ? await _repository.listFormations()
          : state.formations;
      final squad = await _repository.getBuilder(squadId);
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: SquadBuilderStatus.ready,
          baseline: squad,
          draft: LineupDraft.fromDetail(squad),
          formations: formations,
          chemistry: squad.chemistry,
          previewStatus: LineupPreviewStatus.idle,
          isSaving: false,
          hasConflict: false,
          clearFailure: true,
          clearSaveFailure: true,
          droppedByFormationChange: const <PlayerCard>[],
        ),
      );
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(status: SquadBuilderStatus.failure, failure: failure),
        );
      }
    }
  }

  /// Depois de um conflito: o servidor e a autoridade, entao o rascunho e
  /// descartado e tudo recomeca do estado atual. Sem merge automatico e sem
  /// "salvar assim mesmo".
  Future<void> reloadAfterConflict() => load();

  // -------------------------------------------------------------- mutacoes

  void assignCard({required String slotCode, required PlayerCard card}) {
    final draft = state.draft;
    if (draft == null) {
      return;
    }
    final next = Map<String, PlayerCard>.of(draft.starters);
    // Mesmo jogador em dois slots nunca acontece: se ele ja estava escalado,
    // sai de onde estava. Na pratica isso vira uma troca quando o destino
    // tambem esta ocupado, que e o que a pessoa espera ao arrastar.
    final previous = draft.slotOf(card.id);
    if (previous != null && previous != slotCode) {
      final displaced = next[slotCode];
      next.remove(previous);
      if (displaced != null) {
        next[previous] = displaced;
      }
    }
    next[slotCode] = card;
    _mutate(draft.copyWith(starters: next));
  }

  void clearSlot(String slotCode) {
    final draft = state.draft;
    if (draft == null || !draft.starters.containsKey(slotCode)) {
      return;
    }
    _mutate(
      draft.copyWith(
        starters: Map<String, PlayerCard>.of(draft.starters)
          ..remove(slotCode),
      ),
    );
  }

  void clearAll() {
    final draft = state.draft;
    if (draft == null || draft.isEmpty) {
      return;
    }
    _mutate(draft.copyWith(starters: const <String, PlayerCard>{}));
  }

  void setManager({FcManager? manager, FcLeague? league}) {
    final draft = state.draft;
    if (draft == null) {
      return;
    }
    _mutate(
      draft.copyWith(
        manager: manager,
        clearManager: manager == null,
        managerLeague: league,
        clearManagerLeague: league == null,
      ),
    );
  }

  /// Troca de formacao, local. Reaproveita quem cabe e avisa quem saiu.
  void setFormation(String formationCode) {
    final draft = state.draft;
    if (draft == null || draft.formation.code == formationCode) {
      return;
    }
    final target = state.formations
        .where((f) => f.code == formationCode)
        .firstOrNull;
    if (target == null) {
      return;
    }

    final result = remapLineup(
      current: <RemapEntry>[
        for (final entry in draft.starters.entries)
          if (draft.formation.slots
                  .where((s) => s.slotCode == entry.key)
                  .firstOrNull
              case final slot?)
            RemapEntry(
              slotCode: entry.key,
              card: entry.value,
              positionCode: slot.positionCode,
              x: slot.x,
              y: slot.y,
            ),
      ],
      target: target.slots,
    );

    _mutate(
      draft.copyWith(formation: target, starters: result.assigned),
      dropped: result.dropped,
    );
  }

  /// Toda mutacao passa por aqui: emite o rascunho novo, limpa erro de save
  /// anterior e reagenda o preview.
  void _mutate(LineupDraft next, {List<PlayerCard>? dropped}) {
    emit(
      state.copyWith(
        draft: next,
        droppedByFormationChange: dropped ?? const <PlayerCard>[],
        clearSaveFailure: true,
      ),
    );
    _schedulePreview();
  }

  // --------------------------------------------------------------- preview

  void _schedulePreview() {
    _previewDebounce?.cancel();
    final draft = state.draft;
    if (draft == null) {
      return;
    }
    // Marca "recalculando" imediatamente: o valor na tela ainda e o anterior,
    // e ele nao corresponde mais ao rascunho.
    emit(state.copyWith(previewStatus: LineupPreviewStatus.updating));
    _previewDebounce = Timer(_previewDelay, _runPreview);
  }

  Future<void> _runPreview() async {
    final draft = state.draft;
    if (draft == null) {
      return;
    }
    final generation = ++_previewGeneration;
    try {
      final chemistry = await _repository.previewChemistry(
        squadId: squadId,
        formationCode: draft.formation.code,
        slots: draft.slotIds,
        managerId: draft.manager?.id,
        managerLeagueId: draft.managerLeague?.id,
      );
      // Chegou tarde: outro rascunho ja pediu preview depois deste.
      if (isClosed || generation != _previewGeneration) {
        return;
      }
      emit(
        state.copyWith(
          chemistry: chemistry,
          previewStatus: LineupPreviewStatus.idle,
        ),
      );
    } on AppFailure {
      if (isClosed || generation != _previewGeneration) {
        return;
      }
      // Preview e conforto, nao autoridade: falhar aqui nao pode mexer no
      // rascunho nem zerar a quimica exibida.
      emit(state.copyWith(previewStatus: LineupPreviewStatus.failure));
    }
  }

  void retryPreview() => _runPreview();

  /// Dispara o preview sem esperar o debounce. Existe para o teste conseguir
  /// provocar a corrida de respostas -- o unico jeito de verificar que uma
  /// resposta atrasada nao vence o rascunho atual.
  @visibleForTesting
  Future<void> debugPreviewNow() => _runPreview();

  // ------------------------------------------------------------------ save

  Future<bool> save() async {
    final draft = state.draft;
    final baseline = state.baseline;
    if (draft == null || baseline == null || !state.canSave) {
      return false;
    }
    emit(state.copyWith(isSaving: true, clearSaveFailure: true));
    try {
      final saved = await _repository.saveLineup(
        squadId: squadId,
        formationCode: draft.formation.code,
        slots: draft.slotIds,
        managerId: draft.manager?.id,
        managerLeagueId: draft.managerLeague?.id,
        expectedUpdatedAt: baseline.updatedAt,
      );
      if (isClosed) {
        return true;
      }
      // O baseline vira o que o servidor confirmou, inclusive o updated_at
      // novo -- sem isso o segundo save seguido levaria a baseline velha e
      // tomaria um conflito que nao existe.
      emit(
        state.copyWith(
          baseline: saved,
          draft: LineupDraft.fromDetail(saved),
          chemistry: saved.chemistry,
          previewStatus: LineupPreviewStatus.idle,
          isSaving: false,
          clearSaveFailure: true,
          droppedByFormationChange: const <PlayerCard>[],
        ),
      );
      return true;
    } on AppFailure catch (failure) {
      if (isClosed) {
        return false;
      }
      final isConflict =
          failure is SquadFailure &&
          failure.reason == SquadFailureReason.editConflict;
      // O rascunho NAO volta para o baseline: perder a montagem por causa de
      // uma falha de rede seria pior do que o erro em si.
      emit(
        state.copyWith(
          isSaving: false,
          saveFailure: failure,
          hasConflict: isConflict,
        ),
      );
      return false;
    }
  }

  @override
  Future<void> close() {
    _previewDebounce?.cancel();
    return super.close();
  }
}
