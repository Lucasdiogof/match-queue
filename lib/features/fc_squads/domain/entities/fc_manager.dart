import 'package:equatable/equatable.dart';

class FcNation extends Equatable {
  const FcNation({required this.id, required this.name, this.flagImageUrl});

  final String id;
  final String name;
  final String? flagImageUrl;

  @override
  List<Object?> get props => <Object?>[id, name, flagImageUrl];
}

class FcLeague extends Equatable {
  const FcLeague({required this.id, required this.name, this.logoImageUrl});

  final String id;
  final String name;
  final String? logoImageUrl;

  @override
  List<Object?> get props => <Object?>[id, name, logoImageUrl];
}

class FcClub extends Equatable {
  const FcClub({
    required this.id,
    required this.name,
    this.leagueId,
    this.logoImageUrl,
  });

  final String id;
  final String name;
  final String? leagueId;
  final String? logoImageUrl;

  @override
  List<Object?> get props => <Object?>[id, name, leagueId, logoImageUrl];
}

/// Técnico. A liga NÃO mora aqui de propósito: ela é configuração do squad
/// (o mesmo técnico pode ser usado com ligas diferentes em squads
/// diferentes), então vive em [FcSquadDetail.managerLeague].
class FcManager extends Equatable {
  const FcManager({
    required this.id,
    required this.name,
    this.nation,
    this.imageUrl,
  });

  final String id;
  final String name;
  final FcNation? nation;
  final String? imageUrl;

  @override
  List<Object?> get props => <Object?>[id, name, nation, imageUrl];
}
