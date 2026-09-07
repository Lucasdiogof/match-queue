import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/profile/domain/repositories/profile_repository.dart';
import 'package:fifa_queue/features/profile/presentation/cubit/profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileState());

  final ProfileRepository _repository;

  Future<void> load({required String fallbackDisplayName}) async {
    emit(state.copyWith(status: ProfileStatus.loading, clearFailure: true));
    try {
      final profile = await _repository.ensureMyProfile(
        fallbackDisplayName: fallbackDisplayName,
      );
      if (!isClosed) {
        emit(ProfileState(status: ProfileStatus.ready, profile: profile));
      }
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(status: ProfileStatus.failure, failure: failure));
      }
    }
  }

  Future<bool> updateDisplayName(String displayName) async {
    if (state.isSaving) {
      return false;
    }
    emit(state.copyWith(isSaving: true, clearFailure: true));
    try {
      final profile = await _repository.updateDisplayName(displayName);
      if (!isClosed) {
        emit(ProfileState(status: ProfileStatus.ready, profile: profile));
      }
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isSaving: false, failure: failure));
      }
      return false;
    }
  }

  void clearFailure() {
    if (state.failure != null) {
      emit(state.copyWith(clearFailure: true));
    }
  }

  void clear() => emit(const ProfileState());
}
