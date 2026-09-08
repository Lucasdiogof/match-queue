import 'package:fifa_queue/features/matchmaking/data/selected_game_mode_store.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Modo de jogo selecionado, lembrado entre sessões. App-scoped como
/// ThemeCubit/LocaleCubit: é uma preferência única do usuário, não por time.
class GameModeCubit extends Cubit<GameMode> {
  GameModeCubit(this._store) : super(_store.read());

  final SelectedGameModeStore _store;

  Future<void> select(GameMode mode) async {
    if (mode == state) {
      return;
    }
    emit(mode);
    await _store.write(mode);
  }
}
