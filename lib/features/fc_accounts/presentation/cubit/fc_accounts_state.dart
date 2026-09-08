import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';

enum FcAccountsStatus { initial, loading, ready, failure }

class FcAccountsState extends Equatable {
  const FcAccountsState({
    this.status = FcAccountsStatus.initial,
    this.accounts = const <FcAccount>[],
    this.selectedAccountId,
    this.weekendLeagueEvent,
    this.failure,
    this.actionFailure,
    this.isSaving = false,
  });

  final FcAccountsStatus status;
  final List<FcAccount> accounts;
  final String? selectedAccountId;
  final WeekendLeagueEvent? weekendLeagueEvent;
  final AppFailure? failure;
  final AppFailure? actionFailure;
  final bool isSaving;

  bool get isLoading => status == FcAccountsStatus.loading;

  bool get hasAccounts => accounts.isNotEmpty;

  FcAccount? get selectedAccount {
    final id = selectedAccountId;
    if (id == null) {
      return null;
    }
    for (final account in accounts) {
      if (account.id == id) {
        return account;
      }
    }
    return null;
  }

  FcAccountsState copyWith({
    FcAccountsStatus? status,
    List<FcAccount>? accounts,
    String? selectedAccountId,
    bool clearSelectedAccountId = false,
    WeekendLeagueEvent? weekendLeagueEvent,
    bool clearWeekendLeagueEvent = false,
    AppFailure? failure,
    bool clearFailure = false,
    AppFailure? actionFailure,
    bool clearActionFailure = false,
    bool? isSaving,
  }) => FcAccountsState(
    status: status ?? this.status,
    accounts: accounts ?? this.accounts,
    selectedAccountId: clearSelectedAccountId
        ? null
        : (selectedAccountId ?? this.selectedAccountId),
    weekendLeagueEvent: clearWeekendLeagueEvent
        ? null
        : (weekendLeagueEvent ?? this.weekendLeagueEvent),
    failure: clearFailure ? null : (failure ?? this.failure),
    actionFailure: clearActionFailure
        ? null
        : (actionFailure ?? this.actionFailure),
    isSaving: isSaving ?? this.isSaving,
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    accounts,
    selectedAccountId,
    weekendLeagueEvent,
    failure,
    actionFailure,
    isSaving,
  ];
}
