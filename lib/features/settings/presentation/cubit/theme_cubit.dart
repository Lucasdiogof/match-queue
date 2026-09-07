import 'package:fifa_queue/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._repository) : super(_repository.readThemeMode());

  final SettingsRepository _repository;

  Future<void> select(ThemeMode mode) async {
    if (mode == state) {
      return;
    }
    emit(mode);
    await _repository.writeThemeMode(mode);
  }
}
