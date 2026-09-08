import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';
import 'package:fifa_queue/features/public_profile/domain/repositories/public_profile_repository.dart';
import 'package:fifa_queue/features/public_profile/presentation/cubit/public_profile_view_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PublicProfileViewCubit extends Cubit<PublicProfileViewState> {
  PublicProfileViewCubit(this._repository, this._authRepository)
    : super(const PublicProfileViewState());

  final PublicProfileRepository _repository;
  final AuthRepository _authRepository;

  Future<void> load(String identifier) async {
    emit(const PublicProfileViewState());
    try {
      final profile = await _repository.fetchPublicProfile(identifier);
      final isOwner = await _resolveIsOwner(identifier);
      emit(
        PublicProfileViewState(
          status: profile.found
              ? PublicProfileViewStatus.ready
              : PublicProfileViewStatus.notFound,
          profile: profile,
          isOwner: isOwner,
        ),
      );
    } catch (error) {
      emit(
        PublicProfileViewState(
          status: PublicProfileViewStatus.failure,
          failure: error is AppFailure ? error : const UnexpectedFailure(),
        ),
      );
    }
  }

  /// So chama a propria configuracao quando ha sessao -- visitante anonimo
  /// nunca dispara essa chamada extra.
  Future<bool> _resolveIsOwner(String identifier) async {
    if (_authRepository.currentUser == null) {
      return false;
    }
    try {
      final mySettings = await _repository.fetchMySettings();
      final mySlug = mySettings.slug?.toLowerCase();
      return mySlug != null && mySlug == identifier.toLowerCase();
    } catch (_) {
      return false;
    }
  }
}
