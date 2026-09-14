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
      final isOwner = await _resolveIsOwner(profile.accountId);
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
  /// nunca dispara essa chamada extra. get_my_public_profile_settings ja
  /// levanta FQ025 se a conta nao for do usuario logado, entao a chamada
  /// so ter sucesso ja PROVA ownership -- nao precisa comparar slug.
  Future<bool> _resolveIsOwner(String? accountId) async {
    if (accountId == null || _authRepository.currentUser == null) {
      return false;
    }
    try {
      await _repository.fetchMySettings(accountId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
