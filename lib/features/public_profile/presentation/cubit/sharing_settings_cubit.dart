import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/features/public_profile/domain/repositories/public_profile_repository.dart';
import 'package:fifa_queue/features/public_profile/presentation/cubit/sharing_settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SharingSettingsCubit extends Cubit<SharingSettingsState> {
  SharingSettingsCubit(this._repository) : super(const SharingSettingsState());

  final PublicProfileRepository _repository;

  Future<void> load() async {
    emit(
      state.copyWith(status: SharingSettingsStatus.loading, clearFailure: true),
    );
    try {
      final settings = await _repository.fetchMySettings();
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

  void setFcAccountId(String? id) => emit(
    state.copyWith(
      draft: id == null
          ? state.draft.copyWith(clearFcAccountId: true)
          : state.draft.copyWith(fcAccountId: id),
    ),
  );

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
      final available = await _repository.isSlugAvailable(normalized);
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

  /// Usado pelos CTAs "Compartilhar esta Conta"/"Compartilhar escalação":
  /// oferece habilitar (nunca ativa sozinho sem o usuario apertar Salvar).
  void applyPreselect({String? fcAccountId, bool? showSquad}) {
    var draft = state.draft;
    if (fcAccountId != null) {
      draft = draft.copyWith(fcAccountId: fcAccountId, isEnabled: true);
    }
    if (showSquad ?? false) {
      draft = draft.copyWith(showSquad: true);
    }
    emit(state.copyWith(draft: draft));
  }
}
