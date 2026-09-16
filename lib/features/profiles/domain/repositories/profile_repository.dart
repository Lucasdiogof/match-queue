import 'dart:typed_data';

import 'package:fifa_queue/features/profiles/domain/entities/profile.dart';
import 'package:fifa_queue/features/profiles/domain/entities/profile_platform.dart';
import 'package:fifa_queue/features/profiles/domain/entities/profile_stats.dart';
import 'package:fifa_queue/features/profiles/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';

class ProfilesSnapshot {
  const ProfilesSnapshot({required this.profiles, this.weekendLeagueEvent});

  final List<Profile> profiles;
  final WeekendLeagueEvent? weekendLeagueEvent;
}

abstract interface class ProfileRepository {
  Future<ProfilesSnapshot> fetchMyProfiles();

  /// Devolve o id da conta recem-criada.
  Future<String> createProfile(String name);

  Future<void> updateProfile({required String id, required String name});

  Future<void> updatePlatform({required String id, ProfilePlatform? platform});

  Future<String> uploadAndSetAvatar({
    required String profileId,
    required Uint8List bytes,
    required String contentType,
  });

  Future<void> removeAvatar(String profileId);

  Future<void> archiveProfile(String id);

  Future<void> updateRivalsDivision({
    required String id,
    RivalsDivision? division,
  });

  Future<void> linkToTeam({required String profileId, required String teamId});

  Future<void> unlinkFromTeam({
    required String profileId,
    required String teamId,
  });

  Future<void> setWeekendLeagueManualRecord({
    required String profileId,
    required String eventId,
    required int wins,
    required int losses,
  });

  Future<void> clearWeekendLeagueManualRecord({
    required String profileId,
    required String eventId,
  });

  /// Delta pode ser negativo (corrigir um toque em "+" a mais). Servidor
  /// nunca deixa o total ficar negativo nem passar de 15 jogos.
  Future<void> incrementWeekendLeagueManualRecord({
    required String profileId,
    required String eventId,
    int winDelta = 0,
    int lossDelta = 0,
  });

  Future<void> incrementRivalsManualRecord({
    required String profileId,
    int winDelta = 0,
    int lossDelta = 0,
  });

  /// Partidas registradas/W/L/gols pró-contra-saldo da conta, todos os modos.
  Future<ProfileStats> fetchProfileStats(String profileId);

  /// Record de WL (computado x manual), artilharia e assistências de uma
  /// conta num evento.
  /// Semanas de Weekend League ja iniciadas, mais recente primeiro.
  Future<List<WeekendLeagueEvent>> fetchWeekendLeagueEvents();

  Future<WeekendLeagueProfileStats> fetchWeekendLeagueProfileStats({
    required String profileId,
    required String eventId,
  });

  /// Partidas/record/gols/assistências de Rivals de uma conta. All-time
  /// (sem season/semana modelada ainda).
  Future<RivalsProfileStats> fetchRivalsProfileStats(String profileId);
}
