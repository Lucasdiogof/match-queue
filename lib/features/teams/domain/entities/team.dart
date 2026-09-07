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
  });

  final String id;
  final String name;
  final String? tag;
  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final Duration defaultSearchDuration;
  final bool isActive;
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
    createdAt,
    updatedAt,
  ];
}
