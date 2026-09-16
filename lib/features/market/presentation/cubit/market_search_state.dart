import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';

enum MarketSearchStatus {
  /// Nada digitado ainda (ou termo curto demais) -- estado inicial, nunca
  /// lista nada por padrao (pedido explicito: Mercado nunca carrega cartas
  /// sozinho).
  initial,
  loading,
  ready,
  noResults,
  failure,
}

class MarketSearchState extends Equatable {
  const MarketSearchState({
    this.status = MarketSearchStatus.initial,
    this.query = '',
    this.cards = const <PlayerCard>[],
    this.favoriteCardIds = const <String>{},
    this.failure,
  });

  final MarketSearchStatus status;
  final String query;
  final List<PlayerCard> cards;

  /// Ids favoritados, carregado uma vez e atualizado localmente ao
  /// favoritar/desfavoritar -- evita round-trip extra por resultado.
  final Set<String> favoriteCardIds;
  final AppFailure? failure;

  MarketSearchState copyWith({
    MarketSearchStatus? status,
    String? query,
    List<PlayerCard>? cards,
    Set<String>? favoriteCardIds,
    AppFailure? failure,
    bool clearFailure = false,
  }) => MarketSearchState(
    status: status ?? this.status,
    query: query ?? this.query,
    cards: cards ?? this.cards,
    favoriteCardIds: favoriteCardIds ?? this.favoriteCardIds,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    query,
    cards,
    favoriteCardIds,
    failure,
  ];
}
