import 'dart:typed_data';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/profiles/data/selected_profile_store.dart';
import 'package:fifa_queue/features/profiles/domain/entities/profile.dart';
import 'package:fifa_queue/features/profiles/domain/entities/profile_platform.dart';
import 'package:fifa_queue/features/profiles/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/profiles/domain/repositories/profile_repository.dart';
import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Elencos do usuário + qual está selecionado agora. App-scoped como
/// TeamsCubit -- mesma forma (lista + seleção persistida e revalidada
/// contra a lista real, nunca "profiles.first" cego), mesmo motivo.
class ProfilesCubit extends Cubit<ProfilesState> {
  ProfilesCubit(this._repository, this._selectedStore)
    : super(const ProfilesState());

  final ProfileRepository _repository;
  final SelectedProfileStore _selectedStore;

  String? _userId;

  Future<void> load({required String userId}) async {
    _userId = userId;
    emit(state.copyWith(status: ProfilesStatus.loading, clearFailure: true));
    try {
      final snapshot = await _repository.fetchMyProfiles();
      final profiles = _sortedByTeamFirst(snapshot.profiles);
      final selectedId = _resolveSelectedId(profiles, userId);
      emit(
        state.copyWith(
          status: ProfilesStatus.ready,
          profiles: profiles,
          weekendLeagueEvent: snapshot.weekendLeagueEvent,
          clearWeekendLeagueEvent: snapshot.weekendLeagueEvent == null,
          selectedProfileId: selectedId,
          clearSelectedProfileId: selectedId == null,
          clearFailure: true,
        ),
      );
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(status: ProfilesStatus.failure, failure: failure));
      }
    }
  }

  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    await load(userId: userId);
  }

  Future<void> selectProfile(String profileId) async {
    if (state.selectedProfileId == profileId) {
      return;
    }
    if (!state.profiles.any((profile) => profile.id == profileId)) {
      return;
    }
    emit(state.copyWith(selectedProfileId: profileId));
    await _persistSelected(profileId);
  }

  Future<bool> createProfile(String name, {ProfilePlatform? platform}) =>
      _mutate(() async {
        final id = await _repository.createProfile(name);
        if (platform != null) {
          await _repository.updatePlatform(id: id, platform: platform);
        }
      }, selectNewest: true);

  Future<bool> updateProfile({required String id, required String name}) =>
      _mutate(() => _repository.updateProfile(id: id, name: name));

  Future<bool> updatePlatform({
    required String id,
    ProfilePlatform? platform,
  }) => _mutate(() => _repository.updatePlatform(id: id, platform: platform));

  Future<bool> uploadAndSetAvatar({
    required String profileId,
    required Uint8List bytes,
    required String contentType,
  }) => _mutate(
    () => _repository.uploadAndSetAvatar(
      profileId: profileId,
      bytes: bytes,
      contentType: contentType,
    ),
  );

  Future<bool> removeAvatar(String profileId) =>
      _mutate(() => _repository.removeAvatar(profileId));

  Future<bool> archiveProfile(String id) => _mutate(
    () => _repository.archiveProfile(id),
    clearSelectionIfArchived: id,
  );

  Future<bool> updateRivalsDivision({
    required String id,
    RivalsDivision? division,
  }) => _mutate(
    () => _repository.updateRivalsDivision(id: id, division: division),
  );

  Future<bool> linkToTeam({
    required String profileId,
    required String teamId,
  }) => _mutate(
    () => _repository.linkToTeam(profileId: profileId, teamId: teamId),
  );

  Future<bool> unlinkFromTeam({
    required String profileId,
    required String teamId,
  }) => _mutate(
    () => _repository.unlinkFromTeam(profileId: profileId, teamId: teamId),
  );

  Future<bool> setWeekendLeagueManualRecord({
    required String profileId,
    required int wins,
    required int losses,
  }) async {
    final eventId = state.weekendLeagueEvent?.id;
    if (eventId == null) {
      return false;
    }
    return _mutate(
      () => _repository.setWeekendLeagueManualRecord(
        profileId: profileId,
        eventId: eventId,
        wins: wins,
        losses: losses,
      ),
    );
  }

  Future<bool> clearWeekendLeagueManualRecord(String profileId) async {
    final eventId = state.weekendLeagueEvent?.id;
    if (eventId == null) {
      return false;
    }
    return _mutate(
      () => _repository.clearWeekendLeagueManualRecord(
        profileId: profileId,
        eventId: eventId,
      ),
    );
  }

  /// [eventId] pra qual campanha incrementar -- cada Weekend League e uma
  /// historia independente (15 jogos cada), entao quem esta vendo o detalhe
  /// de uma campanha PASSADA precisa poder mexer nela, nao sempre na atual.
  /// Sem [eventId] explicito, cai na campanha corrente (uso do card
  /// resumido na tela da Conta, que so mostra a atual).
  Future<bool> incrementWeekendLeagueRecord({
    required String profileId,
    String? eventId,
    int winDelta = 0,
    int lossDelta = 0,
  }) async {
    final resolvedEventId = eventId ?? state.weekendLeagueEvent?.id;
    if (resolvedEventId == null) {
      return false;
    }
    return _mutate(
      () => _repository.incrementWeekendLeagueManualRecord(
        profileId: profileId,
        eventId: resolvedEventId,
        winDelta: winDelta,
        lossDelta: lossDelta,
      ),
    );
  }

  Future<bool> incrementRivalsRecord({
    required String profileId,
    int winDelta = 0,
    int lossDelta = 0,
  }) => _mutate(
    () => _repository.incrementRivalsManualRecord(
      profileId: profileId,
      winDelta: winDelta,
      lossDelta: lossDelta,
    ),
  );

  void clearActionFailure() {
    if (state.actionFailure != null) {
      emit(state.copyWith(clearActionFailure: true));
    }
  }

  void clear() {
    _userId = null;
    emit(const ProfilesState());
  }

  Future<bool> _mutate(
    Future<void> Function() action, {
    bool selectNewest = false,
    String? clearSelectionIfArchived,
  }) async {
    if (state.isSaving) {
      return false;
    }
    emit(state.copyWith(isSaving: true, clearActionFailure: true));
    try {
      await action();
      final userId = _userId;
      if (userId == null) {
        emit(state.copyWith(isSaving: false));
        return true;
      }
      final snapshot = await _repository.fetchMyProfiles();
      var selectedId = state.selectedProfileId;
      if (clearSelectionIfArchived != null &&
          selectedId == clearSelectionIfArchived) {
        selectedId = null;
      }
      if (selectNewest && snapshot.profiles.isNotEmpty) {
        selectedId = snapshot.profiles.last.id;
      }
      final profiles = _sortedByTeamFirst(snapshot.profiles);
      final resolvedId = _resolveSelectedId(
        profiles,
        userId,
        preferred: selectedId,
      );
      emit(
        state.copyWith(
          status: ProfilesStatus.ready,
          profiles: profiles,
          weekendLeagueEvent: snapshot.weekendLeagueEvent,
          clearWeekendLeagueEvent: snapshot.weekendLeagueEvent == null,
          selectedProfileId: resolvedId,
          clearSelectedProfileId: resolvedId == null,
          isSaving: false,
          clearActionFailure: true,
        ),
      );
      await _persistSelected(resolvedId);
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isSaving: false, actionFailure: failure));
      }
      return false;
    }
  }

  /// Conta com time vem primeiro -- e o que a pessoa provavelmente quer ver
  /// e o que vira selecao padrao (ver _resolveSelectedId) quando nao ha
  /// preferencia salva. Estavel: preserva a ordem relativa dentro de cada
  /// grupo (nao embaralha por time/sem-time).
  List<Profile> _sortedByTeamFirst(List<Profile> profiles) => <Profile>[
    ...profiles.where((profile) => profile.teamIds.isNotEmpty),
    ...profiles.where((profile) => profile.teamIds.isEmpty),
  ];

  String? _resolveSelectedId(
    List<Profile> profiles,
    String userId, {
    String? preferred,
  }) {
    if (profiles.isEmpty) {
      return null;
    }
    final candidate = preferred ?? _selectedStore.read(userId);
    if (candidate != null &&
        profiles.any((profile) => profile.id == candidate)) {
      return candidate;
    }
    return profiles.first.id;
  }

  Future<void> _persistSelected(String? profileId) async {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    await _selectedStore.write(userId, profileId);
  }
}
