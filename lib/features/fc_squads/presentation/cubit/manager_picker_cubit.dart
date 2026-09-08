import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_manager.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/player_card_catalog_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ManagerPickerStatus { loading, ready, failure }

class ManagerPickerState extends Equatable {
  const ManagerPickerState({
    this.status = ManagerPickerStatus.loading,
    this.nations = const <FcNation>[],
    this.managers = const <FcManager>[],
    this.leagues = const <FcLeague>[],
    this.selectedNation,
    this.selectedManager,
    this.selectedLeague,
    this.isLoadingManagers = false,
    this.failure,
  });

  final ManagerPickerStatus status;
  final List<FcNation> nations;
  final List<FcManager> managers;
  final List<FcLeague> leagues;
  final FcNation? selectedNation;
  final FcManager? selectedManager;
  final FcLeague? selectedLeague;
  final bool isLoadingManagers;
  final AppFailure? failure;

  /// A liga só faz sentido depois de escolher o técnico (item 52).
  bool get canPickLeague => selectedManager != null;

  ManagerPickerState copyWith({
    ManagerPickerStatus? status,
    List<FcNation>? nations,
    List<FcManager>? managers,
    List<FcLeague>? leagues,
    FcNation? selectedNation,
    FcManager? selectedManager,
    bool clearSelectedManager = false,
    FcLeague? selectedLeague,
    bool clearSelectedLeague = false,
    bool? isLoadingManagers,
    AppFailure? failure,
    bool clearFailure = false,
  }) => ManagerPickerState(
    status: status ?? this.status,
    nations: nations ?? this.nations,
    managers: managers ?? this.managers,
    leagues: leagues ?? this.leagues,
    selectedNation: selectedNation ?? this.selectedNation,
    selectedManager: clearSelectedManager
        ? null
        : (selectedManager ?? this.selectedManager),
    selectedLeague: clearSelectedLeague
        ? null
        : (selectedLeague ?? this.selectedLeague),
    isLoadingManagers: isLoadingManagers ?? this.isLoadingManagers,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    nations,
    managers,
    leagues,
    selectedNation,
    selectedManager,
    selectedLeague,
    isLoadingManagers,
    failure,
  ];
}

/// Fluxo país -> técnico -> liga (item 47).
class ManagerPickerCubit extends Cubit<ManagerPickerState> {
  ManagerPickerCubit(
    this._repository, {
    FcManager? initialManager,
    FcLeague? initialLeague,
  }) : super(
         ManagerPickerState(
           selectedManager: initialManager,
           selectedLeague: initialLeague,
         ),
       );

  final PlayerCardCatalogRepository _repository;

  Future<void> load() async {
    emit(
      state.copyWith(status: ManagerPickerStatus.loading, clearFailure: true),
    );
    try {
      final nations = await _repository.getNations();
      final leagues = await _repository.getLeagues();
      if (isClosed) {
        return;
      }
      final nation = state.selectedManager?.nation;
      emit(
        state.copyWith(
          status: ManagerPickerStatus.ready,
          nations: nations,
          leagues: leagues,
          selectedNation: nation,
          clearFailure: true,
        ),
      );
      if (nation != null) {
        await selectNation(nation);
      }
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(status: ManagerPickerStatus.failure, failure: failure),
        );
      }
    }
  }

  Future<void> selectNation(FcNation nation) async {
    emit(
      state.copyWith(
        selectedNation: nation,
        isLoadingManagers: true,
        managers: const <FcManager>[],
      ),
    );
    try {
      final managers = await _repository.searchManagers(nationId: nation.id);
      if (isClosed || state.selectedNation?.id != nation.id) {
        return;
      }
      emit(state.copyWith(managers: managers, isLoadingManagers: false));
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isLoadingManagers: false, failure: failure));
      }
    }
  }

  void selectManager(FcManager manager) => emit(
    // Trocar de técnico limpa a liga: a combinação anterior deixou de valer.
    state.copyWith(selectedManager: manager, clearSelectedLeague: true),
  );

  void selectLeague(FcLeague league) =>
      emit(state.copyWith(selectedLeague: league));
}
