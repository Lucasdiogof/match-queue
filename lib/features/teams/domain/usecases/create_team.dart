import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/domain/repositories/team_repository.dart';

class CreateTeam {
  const CreateTeam(this._repository);

  final TeamRepository _repository;

  Future<Team> call({
    required String name,
    String? tag,
    Duration? defaultSearchDuration,
  }) {
    final normalizedName = AppValidators.normalizeTeamName(name);
    if (AppValidators.teamName(normalizedName) != null) {
      throw const TeamFailure(reason: TeamFailureReason.invalidName);
    }

    final normalizedTag = AppValidators.normalizeTeamTag(tag);
    if (AppValidators.teamTag(normalizedTag) != null) {
      throw const TeamFailure(reason: TeamFailureReason.invalidTag);
    }

    return _repository.createTeam(
      name: normalizedName,
      tag: normalizedTag,
      defaultSearchDuration: defaultSearchDuration,
    );
  }
}
