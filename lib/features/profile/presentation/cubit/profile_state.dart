import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/profile/domain/entities/profile.dart';

enum ProfileStatus { initial, loading, ready, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.failure,
    this.isSaving = false,
  });

  final ProfileStatus status;
  final Profile? profile;
  final AppFailure? failure;
  final bool isSaving;

  bool get isReady => status == ProfileStatus.ready && profile != null;

  String get displayName => profile?.displayName ?? '';

  ProfileState copyWith({
    ProfileStatus? status,
    Profile? profile,
    bool clearProfile = false,
    AppFailure? failure,
    bool clearFailure = false,
    bool? isSaving,
  }) => ProfileState(
    status: status ?? this.status,
    profile: clearProfile ? null : (profile ?? this.profile),
    failure: clearFailure ? null : (failure ?? this.failure),
    isSaving: isSaving ?? this.isSaving,
  );

  @override
  List<Object?> get props => <Object?>[status, profile, failure, isSaving];
}
