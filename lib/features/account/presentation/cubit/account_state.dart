import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/account/domain/entities/account.dart';

enum AccountStatus { initial, loading, ready, failure }

class AccountState extends Equatable {
  const AccountState({
    this.status = AccountStatus.initial,
    this.profile,
    this.failure,
    this.isSaving = false,
  });

  final AccountStatus status;
  final Account? profile;
  final AppFailure? failure;
  final bool isSaving;

  bool get isReady => status == AccountStatus.ready && profile != null;

  String get displayName => profile?.displayName ?? '';

  AccountState copyWith({
    AccountStatus? status,
    Account? profile,
    bool clearProfile = false,
    AppFailure? failure,
    bool clearFailure = false,
    bool? isSaving,
  }) => AccountState(
    status: status ?? this.status,
    profile: clearProfile ? null : (profile ?? this.profile),
    failure: clearFailure ? null : (failure ?? this.failure),
    isSaving: isSaving ?? this.isSaving,
  );

  @override
  List<Object?> get props => <Object?>[status, profile, failure, isSaving];
}
