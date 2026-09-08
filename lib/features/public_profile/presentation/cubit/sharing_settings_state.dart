import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/public_profile/domain/entities/public_sharing_settings.dart';

enum SharingSettingsStatus { initial, loading, ready, failure }

enum SlugAvailability { idle, checking, available, unavailable, invalid }

class SharingSettingsState extends Equatable {
  const SharingSettingsState({
    this.status = SharingSettingsStatus.initial,
    this.saved = PublicSharingSettings.empty,
    this.draft = PublicSharingSettings.empty,
    this.isSaving = false,
    this.slugAvailability = SlugAvailability.idle,
    this.failure,
    this.actionFailure,
  });

  final SharingSettingsStatus status;
  final PublicSharingSettings saved;
  final PublicSharingSettings draft;
  final bool isSaving;
  final SlugAvailability slugAvailability;
  final AppFailure? failure;
  final AppFailure? actionFailure;

  bool get isLoading => status == SharingSettingsStatus.loading;

  bool get isDirty => saved != draft;

  SharingSettingsState copyWith({
    SharingSettingsStatus? status,
    PublicSharingSettings? saved,
    PublicSharingSettings? draft,
    bool? isSaving,
    SlugAvailability? slugAvailability,
    AppFailure? failure,
    bool clearFailure = false,
    AppFailure? actionFailure,
    bool clearActionFailure = false,
  }) => SharingSettingsState(
    status: status ?? this.status,
    saved: saved ?? this.saved,
    draft: draft ?? this.draft,
    isSaving: isSaving ?? this.isSaving,
    slugAvailability: slugAvailability ?? this.slugAvailability,
    failure: clearFailure ? null : (failure ?? this.failure),
    actionFailure: clearActionFailure
        ? null
        : (actionFailure ?? this.actionFailure),
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    saved,
    draft,
    isSaving,
    slugAvailability,
    failure,
    actionFailure,
  ];
}
