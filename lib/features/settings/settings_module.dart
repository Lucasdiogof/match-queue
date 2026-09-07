import 'package:fifa_queue/features/settings/data/repositories/local_settings_repository.dart';
import 'package:fifa_queue/features/settings/domain/repositories/settings_repository.dart';
import 'package:fifa_queue/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:fifa_queue/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

void registerSettingsModule(GetIt sl) {
  sl
    ..registerLazySingleton<SettingsRepository>(
      () => LocalSettingsRepository(sl<SharedPreferences>()),
    )
    ..registerLazySingleton<ThemeCubit>(
      () => ThemeCubit(sl<SettingsRepository>()),
    )
    ..registerLazySingleton<LocaleCubit>(
      () => LocaleCubit(sl<SettingsRepository>()),
    );
}
