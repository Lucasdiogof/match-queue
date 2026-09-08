import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/public_profile/domain/entities/public_profile.dart';

enum PublicProfileViewStatus { loading, ready, notFound, failure }

class PublicProfileViewState extends Equatable {
  const PublicProfileViewState({
    this.status = PublicProfileViewStatus.loading,
    this.profile,
    this.failure,
    this.isOwner = false,
  });

  final PublicProfileViewStatus status;
  final PublicProfile? profile;
  final AppFailure? failure;

  /// O visitante autenticado é o dono deste perfil -- so entao a UI mostra o
  /// CTA extra "Editar compartilhamento".
  final bool isOwner;

  @override
  List<Object?> get props => <Object?>[status, profile, failure, isOwner];
}
