import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/notifications/domain/entities/notification_category.dart';

/// Um item da Central de Notificacoes (item 91). Texto nunca vem pronto do
/// backend (item 70): titleKey + params sao resolvidos pelo l10n do
/// cliente, o mesmo padrao usado no resto do app.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.category,
    required this.type,
    required this.titleKey,
    required this.params,
    required this.createdAt,
    this.deepLinkType,
    this.deepLinkParams = const <String, dynamic>{},
    this.readAt,
  });

  final String id;
  final NotificationCategory? category;
  final String type;
  final String titleKey;
  final Map<String, dynamic> params;
  final String? deepLinkType;
  final Map<String, dynamic> deepLinkParams;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  AppNotification copyWithRead() =>
      isUnread ? _copyWith(readAt: DateTime.now().toUtc()) : this;

  AppNotification _copyWith({DateTime? readAt}) => AppNotification(
    id: id,
    category: category,
    type: type,
    titleKey: titleKey,
    params: params,
    createdAt: createdAt,
    deepLinkType: deepLinkType,
    deepLinkParams: deepLinkParams,
    readAt: readAt ?? this.readAt,
  );

  @override
  List<Object?> get props => <Object?>[
    id,
    category,
    type,
    titleKey,
    params,
    deepLinkType,
    deepLinkParams,
    createdAt,
    readAt,
  ];
}

class NotificationInboxCursor extends Equatable {
  const NotificationInboxCursor({required this.createdAt, required this.id});

  final String createdAt;
  final String id;

  @override
  List<Object?> get props => <Object?>[createdAt, id];
}

class NotificationInboxPage extends Equatable {
  const NotificationInboxPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<AppNotification> items;
  final bool hasMore;
  final NotificationInboxCursor? nextCursor;

  @override
  List<Object?> get props => <Object?>[items, hasMore, nextCursor];
}
