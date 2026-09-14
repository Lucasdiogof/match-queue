import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/features/public_profile/domain/entities/public_sharing_settings.dart';
import 'package:fifa_queue/features/public_profile/domain/repositories/public_profile_repository.dart';
import 'package:fifa_queue/features/public_profile/presentation/cubit/sharing_settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Perfil público de UMA conta FC -- escopado por [fcAccountId] desde a
/// criação, nunca trocável depois (trocar de conta é abrir outro cubit,
/// não mutar este).
class SharingSettingsCubit extends Cubit<SharingSettingsState> {
  SharingSettingsCubit(this._repository, {required this.fcAccountId})
    : super(
        SharingSettingsState(
          saved: PublicSharingSettings.empty(fcAccountId),
          draft: PublicSharingSettings.empty(fcAccountId),
        ),
      );

  final PublicProfileRepository _repository;
  final String fcAccountId;

  Future<void> load() async {
    emit(
      state.copyWith(status: SharingSettingsStatus.loading, clearFailure: true),
    );
    try {
      final settings = await _repository.fetchMySettings(fcAccountId);
      emit(
        state.copyWith(
          status: SharingSettingsStatus.ready,
          saved: settings,
          draft: settings,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: SharingSettingsStatus.failure,
          failure: error is AppFailure ? error : const UnexpectedFailure(),
        ),
      );
    }
  }

  void setEnabled(bool value) =>
      emit(state.copyWith(draft: state.draft.copyWith(isEnabled: value)));

  void setSlugDraft(String value) {
    final normalized = AppValidators.normalizePublicProfileSlug(value);
    emit(
      state.copyWith(
        draft: state.draft.copyWith(slug: normalized),
        slugAvailability: SlugAvailability.idle,
      ),
    );
  }

  void setShowSquad(bool value) =>
      emit(state.copyWith(draft: state.draft.copyWith(showSquad: value)));

  void setShowWeekendLeague(bool value) => emit(
    state.copyWith(draft: state.draft.copyWith(showWeekendLeague: value)),
  );

  void setShowRivals(bool value) =>
      emit(state.copyWith(draft: state.draft.copyWith(showRivals: value)));

  void setShowStats(bool value) =>
      emit(state.copyWith(draft: state.draft.copyWith(showStats: value)));

  Future<void> checkSlugAvailability(String slug) async {
    final normalized = AppValidators.normalizePublicProfileSlug(slug);
    if (normalized == state.saved.slug) {
      emit(state.copyWith(slugAvailability: SlugAvailability.idle));
      return;
    }
    if (AppValidators.publicProfileSlug(normalized) != null) {
      emit(state.copyWith(slugAvailability: SlugAvailability.invalid));
      return;
    }
    emit(state.copyWith(slugAvailability: SlugAvailability.checking));
    try {
      final available = await _repository.isSlugAvailable(
        normalized,
        fcAccountId: fcAccountId,
      );
      if (state.draft.slug != normalized) {
        return;
      }
      emit(
        state.copyWith(
          slugAvailability: available
              ? SlugAvailability.available
              : SlugAvailability.unavailable,
        ),
      );
    } catch (_) {
      emit(state.copyWith(slugAvailability: SlugAvailability.idle));
    }
  }

  Future<bool> save() async {
    emit(state.copyWith(isSaving: true, clearActionFailure: true));
    try {
      final result = await _repository.updateMySettings(state.draft);
      emit(state.copyWith(isSaving: false, saved: result, draft: result));
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          isSaving: false,
          actionFailure: error is AppFailure
              ? error
              : const UnexpectedFailure(),
        ),
      );
      return false;
    }
  }

  void discardDraft() => emit(state.copyWith(draft: state.saved));
}
