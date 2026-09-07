import 'package:fifa_queue/features/invitations/data/repositories/local_pending_invite_repository.dart';
import 'package:fifa_queue/features/invitations/domain/repositories/pending_invite_repository.dart';
import 'package:fifa_queue/features/invitations/presentation/cubit/pending_invite_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

void registerInvitationsModule(GetIt sl) {
  sl
    ..registerLazySingleton<PendingInviteRepository>(
      () => LocalPendingInviteRepository(sl<SharedPreferences>()),
    )
    ..registerLazySingleton<PendingInviteCubit>(
      () => PendingInviteCubit(sl<PendingInviteRepository>()),
    );
}
