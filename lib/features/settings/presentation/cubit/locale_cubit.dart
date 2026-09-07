import 'package:fifa_queue/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_bloc/flutter_bloc.dart';

class LocaleCubit extends Cubit<Locale?> {
  LocaleCubit(this._repository) : super(_repository.readLocale());

  final SettingsRepository _repository;

  Future<void> select(Locale? locale) async {
    if (locale == state) {
      return;
    }
    emit(locale);
    await _repository.writeLocale(locale);
  }
}
