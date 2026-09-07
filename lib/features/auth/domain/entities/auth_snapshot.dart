import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/auth/domain/entities/auth_user.dart';

enum AuthSessionEvent {
  unknown,
  initial,
  signedIn,
  signedOut,
  tokenRefreshed,
  userUpdated,
  passwordRecovery,
}

class AuthSnapshot extends Equatable {
  const AuthSnapshot({required this.event, this.user});

  const AuthSnapshot.signedOut()
    : event = AuthSessionEvent.signedOut,
      user = null;

  final AuthSessionEvent event;
  final AuthUser? user;

  bool get isAuthenticated => user != null;

  bool get isPasswordRecovery => event == AuthSessionEvent.passwordRecovery;

  @override
  List<Object?> get props => <Object?>[event, user];
}
