import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/auth/domain/entities/auth_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.failure,
    this.isSubmitting = false,
    this.isPasswordRecovery = false,
  });

  final AuthStatus status;
  final AuthUser? user;
  final AppFailure? failure;
  final bool isSubmitting;
  final bool isPasswordRecovery;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isResolved => status != AuthStatus.unknown;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    bool clearUser = false,
    AppFailure? failure,
    bool clearFailure = false,
    bool? isSubmitting,
    bool? isPasswordRecovery,
  }) => AuthState(
    status: status ?? this.status,
    user: clearUser ? null : (user ?? this.user),
    failure: clearFailure ? null : (failure ?? this.failure),
    isSubmitting: isSubmitting ?? this.isSubmitting,
    isPasswordRecovery: isPasswordRecovery ?? this.isPasswordRecovery,
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    user,
    failure,
    isSubmitting,
    isPasswordRecovery,
  ];
}
