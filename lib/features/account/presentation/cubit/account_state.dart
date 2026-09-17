import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/account/domain/entities/account.dart';

enum AccountStatus { initial, loading, ready, failure }

class AccountState extends Equatable {
  const AccountState({
    this.status = AccountStatus.initial,
    this.account,
    this.failure,
    this.isSaving = false,
  });

  final AccountStatus status;
  final Account? account;
  final AppFailure? failure;
  final bool isSaving;

  bool get isReady => status == AccountStatus.ready && account != null;

  bool get isLoading => status == AccountStatus.loading;

  /// Onboarding da conta so termina quando ha pelo menos uma plataforma: e o
  /// unico dado obrigatorio que o cadastro nao coleta sozinho. Enquanto for
  /// true, as telas que dependem de matchmaking mostram o card de onboarding
  /// em vez do conteudo.
  bool get needsOnboarding => account != null && account!.platforms.isEmpty;

  String get displayName => account?.displayName ?? '';

  AccountState copyWith({
    AccountStatus? status,
    Account? account,
    bool clearAccount = false,
    AppFailure? failure,
    bool clearFailure = false,
    bool? isSaving,
  }) => AccountState(
    status: status ?? this.status,
    account: clearAccount ? null : (account ?? this.account),
    failure: clearFailure ? null : (failure ?? this.failure),
    isSaving: isSaving ?? this.isSaving,
  );

  @override
  List<Object?> get props => <Object?>[status, account, failure, isSaving];
}
