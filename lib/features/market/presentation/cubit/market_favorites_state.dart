import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';

enum MarketFavoritesStatus { loading, ready, empty, failure }

class MarketFavoritesState extends Equatable {
  const MarketFavoritesState({
    this.status = MarketFavoritesStatus.loading,
    this.cards = const <PlayerCard>[],
    this.failure,
  });

  final MarketFavoritesStatus status;
  final List<PlayerCard> cards;
  final AppFailure? failure;

  MarketFavoritesState copyWith({
    MarketFavoritesStatus? status,
    List<PlayerCard>? cards,
    AppFailure? failure,
    bool clearFailure = false,
  }) => MarketFavoritesState(
    status: status ?? this.status,
    cards: cards ?? this.cards,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => <Object?>[status, cards, failure];
}
