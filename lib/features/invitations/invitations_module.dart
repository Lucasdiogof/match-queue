import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/invitations/data/datasources/invite_remote_data_source.dart';
import 'package:fifa_queue/features/invitations/data/repositories/local_invite_repository.dart';
import 'package:fifa_queue/features/invitations/data/repositories/local_pending_invite_repository.dart';
import 'package:fifa_queue/features/invitations/data/repositories/supabase_invite_repository.dart';
import 'package:fifa_queue/features/invitations/domain/repositories/invite_repository.dart';
import 'package:fifa_queue/features/invitations/domain/repositories/pending_invite_repository.dart';
import 'package:fifa_queue/features/invitations/domain/usecases/resolve_team_invite.dart';
import 'package:fifa_queue/features/invitations/presentation/cubit/pending_invite_cubit.dart';
import 'package:fifa_queue/features/teams/domain/repositories/team_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerInvitationsModule(GetIt sl, {required SupabaseClient? supabaseClient}) {
  sl
    ..registerLazySingleton<PendingInviteRepository>(
      () => LocalPendingInviteRepository(sl<SharedPreferences>()),
    )
    ..registerLazySingleton<PendingInviteCubit>(
      () => PendingInviteCubit(sl<PendingInviteRepository>()),
    );

  if (supabaseClient == null) {
    sl.registerLazySingleton<InviteRepository>(
      () => LocalInviteRepository(sl<TeamRepository>(), sl<SharedPreferences>()),
    );
  } else {
    sl
      ..registerLazySingleton<InviteRemoteDataSource>(
        () => SupabaseInviteRemoteDataSource(supabaseClient),
      )
      ..registerLazySingleton<InviteRepository>(
        () => SupabaseInviteRepository(
          sl<InviteRemoteDataSource>(),
          sl<SupabaseErrorMapper>(),
        ),
      );
  }

  sl.registerLazySingleton<ResolveTeamInvite>(
    () => ResolveTeamInvite(sl<InviteRepository>()),
  );
}
