import 'package:equatable/equatable.dart';

class Account extends Equatable {
  const Account({
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

  Account copyWith({String? displayName, String? avatarUrl, String? locale}) =>
      Account(
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
