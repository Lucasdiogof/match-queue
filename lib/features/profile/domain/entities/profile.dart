import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.displayName,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
    this.locale,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? locale;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile copyWith({String? displayName, String? avatarUrl, String? locale}) =>
      Profile(
        id: id,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        locale: locale ?? this.locale,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @override
  List<Object?> get props => <Object?>[
    id,
    displayName,
    avatarUrl,
    locale,
    createdAt,
    updatedAt,
  ];
}
