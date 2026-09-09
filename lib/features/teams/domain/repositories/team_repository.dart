import 'package:fifa_queue/features/teams/domain/entities/player_profile.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_member_status.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_sports_dashboard.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';

abstract interface class TeamRepository {
  Future<List<UserTeam>> fetchMyTeams();

  Future<Team> createTeam({
    required String name,
    String? tag,
    Duration? defaultSearchDuration,
  });

  Future<Team> updateTeam({
    required String teamId,
    String? name,
    String? tag,
    bool clearTag = false,
    Duration? defaultSearchDuration,
  });

  /// Único caminho de escrita da duração de busca -- nunca via [updateTeam],
  /// pra não ter duas formas concorrentes de gravar a mesma config.
  Future<Team> updateSearchDuration({
    required String teamId,
    required Duration duration,
  });

  Future<List<TeamMember>> fetchMembers(String teamId);

  Future<List<TeamMemberStatus>> fetchPlayerStatuses(String teamId);

  /// Perfil publico de um membro do MESMO time (Etapa 11). [fcAccountId]
  /// desambigua quando o alvo tem mais de uma Conta vinculada aquele time --
  /// veja [PlayerProfile.needsAccountSelection].
  Future<PlayerProfile> fetchMemberProfile({
    required String teamId,
    required String userId,
    String? fcAccountId,
  });

  /// Dashboard esportivo do Time numa chamada só (Etapa 14): resumo,
  /// ranking, artilharia, assistências, WL, Rivals e atividade.
  Future<TeamSportsDashboard> fetchSportsDashboard(String teamId);

  /// Lista completa de artilharia ou assistências, para o "ver tudo".
  Future<List<TeamPlayerLeaderboardEntry>> fetchPlayerLeaderboard({
    required String teamId,
    required bool byAssists,
    int limit,
    int offset,
  });

  /// Liga/desliga a visibilidade pública do time (aba Explorar + página
  /// pública). Só owner/admin -- a RPC recusa com FQ012 caso contrário.
  Future<Team> setTeamVisibility({
    required String teamId,
    required bool isPublic,
  });

  /// Times públicos para a aba Explorar -- nunca inclui time privado.
  Future<List<PublicTeamSummary>> listPublicTeams({int limit = 50});

  /// Página pública de um time. `found = false` cobre "não existe" e "é
  /// privado" com a mesma resposta.
  Future<PublicTeam> getPublicTeam(String teamId);
}
