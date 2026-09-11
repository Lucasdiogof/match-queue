import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_manager.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_squad.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';

/// O Elenco como o usuario esta montando agora, antes de salvar.
///
/// So titulares: banco e reservas sairam do produto. As linhas legadas
/// continuam no banco de dados, mas nao entram aqui, nao sao lidas na hora
/// de montar o rascunho e nao voltam no save.
class LineupDraft extends Equatable {
  const LineupDraft({
    required this.formation,
    required this.starters,
    this.manager,
    this.managerLeague,
  });

  /// Extrai o rascunho do que o servidor devolveu. Este e o unico ponto que
  /// traduz estado persistido em rascunho -- e por isso o unico lugar onde
  /// slots que nao sejam titulares sao descartados.
  factory LineupDraft.fromDetail(FcSquadDetail detail) => LineupDraft(
    formation: detail.formation,
    starters: <String, PlayerCard>{
      for (final slot in detail.slots)
        if (slot.type == SquadSlotType.starting) slot.slotCode: slot.card,
    },
    manager: detail.manager,
    managerLeague: detail.managerLeague,
  );

  final FormationDefinition formation;

  /// slotCode -> carta. Mapa, e nao lista, porque um slot recebe no maximo
  /// um jogador -- a estrutura ja impede escalar dois no mesmo lugar.
  final Map<String, PlayerCard> starters;

  final FcManager? manager;
  final FcLeague? managerLeague;

  /// Overall do rascunho: media das notas dos titulares PREENCHIDOS.
  ///
  /// E o unico numero calculado no cliente, porque `round(avg(rating))` nao
  /// tem como divergir do SQL -- e ha fixtures fixando os dois lados,
  /// inclusive a media terminando em .5, que e onde linguagens costumam
  /// discordar. A quimica, essa nao: vem do servidor.
  int? get overall {
    if (starters.isEmpty) {
      return null;
    }
    final total = starters.values.fold<int>(0, (sum, c) => sum + c.rating);
    return (total / starters.length).round();
  }

  bool get isEmpty => starters.isEmpty;

  /// Um mesmo jogador nunca ocupa dois slots.
  bool contains(String cardId) =>
      starters.values.any((card) => card.id == cardId);

  String? slotOf(String cardId) {
    for (final entry in starters.entries) {
      if (entry.value.id == cardId) {
        return entry.key;
      }
    }
    return null;
  }

  /// Payload do save: so identidade, nada de carta inteira.
  Map<String, String> get slotIds => <String, String>{
    for (final entry in starters.entries) entry.key: entry.value.id,
  };

  LineupDraft copyWith({
    FormationDefinition? formation,
    Map<String, PlayerCard>? starters,
    FcManager? manager,
    bool clearManager = false,
    FcLeague? managerLeague,
    bool clearManagerLeague = false,
  }) => LineupDraft(
    formation: formation ?? this.formation,
    starters: starters ?? this.starters,
    manager: clearManager ? null : (manager ?? this.manager),
    managerLeague: clearManagerLeague
        ? null
        : (managerLeague ?? this.managerLeague),
  );

  /// Assinatura do rascunho. Serve para duas coisas: decidir se ha diferenca
  /// real em relacao ao baseline (e nao "o usuario tocou em algo"), e casar
  /// a resposta do preview com o rascunho que a pediu.
  String get fingerprint {
    final slots = slotIds.entries.map((e) => '${e.key}=${e.value}').toList()
      ..sort();
    return <String>[
      formation.code,
      manager?.id ?? '-',
      managerLeague?.id ?? '-',
      ...slots,
    ].join('|');
  }

  @override
  List<Object?> get props => <Object?>[fingerprint];
}
