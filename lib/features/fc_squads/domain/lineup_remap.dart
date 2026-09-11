import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';

/// Jogador que estava escalado, com o slot que ocupava.
class RemapEntry {
  const RemapEntry({
    required this.slotCode,
    required this.card,
    required this.positionCode,
    required this.x,
    required this.y,
  });

  final String slotCode;
  final PlayerCard card;

  /// Posicao do slot que ele ocupava na formacao ANTIGA.
  final String positionCode;
  final double x;
  final double y;
}

/// Resultado da troca de formacao.
class RemapResult {
  const RemapResult({required this.assigned, required this.dropped});

  /// slotCode da formacao nova -> carta.
  final Map<String, PlayerCard> assigned;

  /// Quem nao tem nenhum slot compativel na formacao nova. Nao vai para
  /// lugar nenhum: sai da escalacao, e a tela avisa.
  final List<PlayerCard> dropped;
}

/// Um jogador so pode ocupar um slot cuja posicao ele realmente joga:
/// posicao principal ou uma alternativa declarada na carta. Nada de
/// equivalencia ampla do tipo "lateral aceita qualquer defensor".
bool canPlay(PlayerCard card, String positionCode) =>
    card.primaryPosition == positionCode ||
    card.alternativePositions.contains(positionCode);

/// Remapeia a escalacao ao trocar de formacao.
///
/// Ordem, e ela importa:
///   1. mesmo slot_code, se continuar existindo e ele puder jogar ali;
///   2. mesma posicao do slot antigo;
///   3. qualquer slot compativel, priorizando o lado (L/R/C no codigo do
///      slot) e depois a distancia no campo;
///   4. nao ha slot compativel -> sai da escalacao.
///
/// A versao anterior, no servidor, tinha uma quinta passada que encaixava
/// pelo slot livre mais proximo SEM exigir elegibilidade -- era assim que um
/// atacante acabava escalado de lateral so por estar perto. Ela nao existe
/// mais: sair da escalacao com aviso e melhor do que jogar fora de posicao
/// sem ninguem perceber.
///
/// Funcao livre para poder ser testada sem montar cubit nem widget.
RemapResult remapLineup({
  required List<RemapEntry> current,
  required List<FormationSlot> target,
}) {
  final assigned = <String, PlayerCard>{};
  final taken = <String>{};
  final dropped = <PlayerCard>[];
  final pending = <RemapEntry>[];

  // 1. mesmo slot.
  for (final entry in current) {
    final slot = target.where((s) => s.slotCode == entry.slotCode).firstOrNull;
    if (slot != null &&
        !taken.contains(slot.slotCode) &&
        canPlay(entry.card, slot.positionCode)) {
      assigned[slot.slotCode] = entry.card;
      taken.add(slot.slotCode);
    } else {
      pending.add(entry);
    }
  }

  // 2. mesma posicao do slot que ele ocupava.
  final stillPending = <RemapEntry>[];
  for (final entry in pending) {
    final slot = target
        .where(
          (s) =>
              !taken.contains(s.slotCode) &&
              s.positionCode == entry.positionCode &&
              canPlay(entry.card, s.positionCode),
        )
        .firstOrNull;
    if (slot != null) {
      assigned[slot.slotCode] = entry.card;
      taken.add(slot.slotCode);
    } else {
      stillPending.add(entry);
    }
  }

  // 3. qualquer slot compativel: mesmo lado primeiro, depois mais perto.
  for (final entry in stillPending) {
    final options =
        target
            .where(
              (s) =>
                  !taken.contains(s.slotCode) &&
                  canPlay(entry.card, s.positionCode),
            )
            .toList()
          ..sort((a, b) {
            final sideA = _sameSide(a.slotCode, entry.slotCode) ? 0 : 1;
            final sideB = _sameSide(b.slotCode, entry.slotCode) ? 0 : 1;
            if (sideA != sideB) {
              return sideA.compareTo(sideB);
            }
            return _distance(a, entry).compareTo(_distance(b, entry));
          });
    if (options.isEmpty) {
      dropped.add(entry.card);
    } else {
      assigned[options.first.slotCode] = entry.card;
      taken.add(options.first.slotCode);
    }
  }

  return RemapResult(assigned: assigned, dropped: dropped);
}

double _distance(FormationSlot slot, RemapEntry entry) {
  final dx = slot.x - entry.x;
  final dy = slot.y - entry.y;
  return dx * dx + dy * dy;
}

/// Lado lido do proprio codigo do slot ('LCB', 'RM', 'ST'). Um lateral
/// esquerdo que precisa mudar de slot deve preferir outro slot da esquerda
/// antes de atravessar o campo.
String _side(String slotCode) {
  if (slotCode.startsWith('L')) {
    return 'L';
  }
  if (slotCode.startsWith('R')) {
    return 'R';
  }
  return 'C';
}

bool _sameSide(String a, String b) => _side(a) == _side(b);
