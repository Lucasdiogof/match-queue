import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/invitations/data/datasources/invite_remote_data_source.dart';
import 'package:fifa_queue/features/invitations/data/repositories/local_pending_invite_repository.dart';
import 'package:fifa_queue/features/invitations/data/repositories/supabase_invite_repository.dart';
import 'package:fifa_queue/features/invitations/domain/repositories/invite_repository.dart';
import 'package:fifa_queue/features/invitations/domain/repositories/pending_invite_repository.dart';
import 'package:fifa_queue/features/invitations/domain/usecases/resolve_team_invite.dart';
import 'package:fifa_queue/features/invitations/presentation/cubit/pending_invite_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerInvitationsModule(
  GetIt sl, {
  required SupabaseClient supabaseClient,
}) {
  sl
    // Estado puramente do dispositivo (codigo de convite pendente entre o
    // deep link e o login) -- nunca teve contraparte no Supabase, entao
    // continua local mesmo sem "modo local" de backend.
    ..registerLazySingleton<PendingInviteRepository>(
      () => LocalPendingInviteRepository(sl<SharedPreferences>()),
    )
    ..registerLazySingleton<PendingInviteCubit>(
      () => PendingInviteCubit(sl<PendingInviteRepository>()),
    )
    ..registerLazySingleton<InviteRemoteDataSource>(
      () => SupabaseInviteRemoteDataSource(supabaseClient),
    )
    ..registerLazySingleton<InviteRepository>(
      () => SupabaseInviteRepository(
        sl<InviteRemoteDataSource>(),
        sl<SupabaseErrorMapper>(),
      ),
    )
    ..registerLazySingleton<ResolveTeamInvite>(
      () => ResolveTeamInvite(sl<InviteRepository>()),
    );
}
