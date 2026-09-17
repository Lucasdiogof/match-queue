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
      final isOwner = profile.found && await _isMySlug(identifier);
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
  /// nunca dispara essa chamada extra. get_my_public_profile_settings devolve
  /// SEMPRE a linha do usuario logado, entao dono e quem tem exatamente este
  /// slug. Isso e so pra decidir se mostra o atalho de editar: nenhum acesso
  /// vem daqui, toda escrita revalida ownership na RPC.
  Future<bool> _isMySlug(String identifier) async {
    if (_authRepository.currentUser == null) {
      return false;
    }
    try {
      final mine = await _repository.fetchMySettings();
      final slug = mine.slug;
      return slug != null &&
          slug.toLowerCase() == identifier.trim().toLowerCase();
    } catch (_) {
      return false;
    }
  }
}
