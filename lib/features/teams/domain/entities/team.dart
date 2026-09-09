import 'package:equatable/equatable.dart';

class Team extends Equatable {
  const Team({
    required this.id,
    required this.name,
    required this.defaultSearchDuration,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.tag,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
    this.isPublic = true,
  });

  final String id;
  final String name;
  final String? tag;
  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final Duration defaultSearchDuration;
  final bool isActive;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  Team copyWith({
    String? name,
    String? tag,
    bool clearTag = false,
    String? logoUrl,
    String? primaryColor,
    String? secondaryColor,
    Duration? defaultSearchDuration,
    bool? isActive,
    bool? isPublic,
    DateTime? updatedAt,
  }) => Team(
    id: id,
    name: name ?? this.name,
    tag: clearTag ? null : (tag ?? this.tag),
    logoUrl: logoUrl ?? this.logoUrl,
    primaryColor: primaryColor ?? this.primaryColor,
    secondaryColor: secondaryColor ?? this.secondaryColor,
    defaultSearchDuration: defaultSearchDuration ?? this.defaultSearchDuration,
    isActive: isActive ?? this.isActive,
    isPublic: isPublic ?? this.isPublic,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  String get initials {
    final explicitTag = tag;
    if (explicitTag != null && explicitTag.isNotEmpty) {
      return _take(explicitTag, 3);
    }
    final words = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((word) => word.isEmpty);
    if (words.isEmpty) {
      return '?';
    }
    if (words.length == 1) {
      return _take(words.first, 2).toUpperCase();
    }
    return '${_take(words.first, 1)}${_take(words.last, 1)}'.toUpperCase();
  }

  static String _take(String value, int count) =>
      String.fromCharCodes(value.runes.take(count));

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    tag,
    logoUrl,
    primaryColor,
    secondaryColor,
    defaultSearchDuration,
    isActive,
    isPublic,
    createdAt,
    updatedAt,
  ];
}

/// Card resumido de um time publico, usado na lista de Explorar.
class PublicTeamSummary extends Equatable {
  const PublicTeamSummary({
    required this.id,
    required this.name,
    required this.memberCount,
    this.tag,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
  });

  final String id;
  final String name;
  final String? tag;
  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final int memberCount;

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    tag,
    logoUrl,
    primaryColor,
    secondaryColor,
    memberCount,
  ];
}

/// Membro de um time publico -- so aparece nomeado se o proprio usuario tem
/// o perfil publico (Etapa 16) habilitado; ver get_public_team.
class PublicTeamMember extends Equatable {
  const PublicTeamMember({
    required this.displayName,
    required this.role,
    this.avatarUrl,
    this.publicProfileSlug,
  });

  final String displayName;
  final String role;
  final String? avatarUrl;
  final String? publicProfileSlug;

  @override
  List<Object?> get props => <Object?>[
    displayName,
    role,
    avatarUrl,
    publicProfileSlug,
  ];
}

class PublicTeamRecord extends Equatable {
  const PublicTeamRecord({
    required this.wins,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
  });

  final int wins;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;

  @override
  List<Object?> get props => <Object?>[wins, losses, goalsFor, goalsAgainst];
}

/// Payload completo da pagina publica de um time. `found = false` cobre
/// tanto "nao existe" quanto "existe mas e privado" -- mesma postura honesta
/// de PublicProfile (nunca revela que um id privado existe).
class PublicTeam extends Equatable {
  const PublicTeam({
    required this.found,
    this.id,
    this.name,
    this.tag,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
    this.memberCount = 0,
    this.members = const <PublicTeamMember>[],
    this.record,
  });

  final bool found;
  final String? id;
  final String? name;
  final String? tag;
  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final int memberCount;
  final List<PublicTeamMember> members;
  final PublicTeamRecord? record;

  @override
  List<Object?> get props => <Object?>[
    found,
    id,
    name,
    tag,
    logoUrl,
    primaryColor,
    secondaryColor,
    memberCount,
    members,
    record,
  ];
}
