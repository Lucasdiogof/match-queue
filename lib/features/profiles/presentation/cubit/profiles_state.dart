import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/profiles/domain/entities/profile.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';

enum ProfilesStatus { initial, loading, ready, failure }

class ProfilesState extends Equatable {
  const ProfilesState({
    this.status = ProfilesStatus.initial,
    this.profiles = const <Profile>[],
    this.selectedProfileId,
    this.weekendLeagueEvent,
    this.failure,
    this.actionFailure,
    this.isSaving = false,
  });

  final ProfilesStatus status;
  final List<Profile> profiles;
  final String? selectedProfileId;
  final WeekendLeagueEvent? weekendLeagueEvent;
  final AppFailure? failure;
  final AppFailure? actionFailure;
  final bool isSaving;

  bool get isLoading => status == ProfilesStatus.loading;

  bool get hasProfiles => profiles.isNotEmpty;

  Profile? get selectedProfile {
    final id = selectedProfileId;
    if (id == null) {
      return null;
    }
    for (final profile in profiles) {
      if (profile.id == id) {
        return profile;
      }
    }
    return null;
  }

  ProfilesState copyWith({
    ProfilesStatus? status,
    List<Profile>? profiles,
    String? selectedProfileId,
    bool clearSelectedProfileId = false,
    WeekendLeagueEvent? weekendLeagueEvent,
    bool clearWeekendLeagueEvent = false,
    AppFailure? failure,
    bool clearFailure = false,
    AppFailure? actionFailure,
    bool clearActionFailure = false,
    bool? isSaving,
  }) => ProfilesState(
    status: status ?? this.status,
    profiles: profiles ?? this.profiles,
    selectedProfileId: clearSelectedProfileId
        ? null
        : (selectedProfileId ?? this.selectedProfileId),
    weekendLeagueEvent: clearWeekendLeagueEvent
        ? null
        : (weekendLeagueEvent ?? this.weekendLeagueEvent),
    failure: clearFailure ? null : (failure ?? this.failure),
    actionFailure: clearActionFailure
        ? null
        : (actionFailure ?? this.actionFailure),
    isSaving: isSaving ?? this.isSaving,
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    profiles,
    selectedProfileId,
    weekendLeagueEvent,
    failure,
    actionFailure,
    isSaving,
  ];
}
