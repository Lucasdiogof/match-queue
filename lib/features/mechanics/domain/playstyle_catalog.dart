/// Catálogo estático de PlayStyles do FC 27: nomes, categoria e explicação
/// vêm de pesquisa (FIFPlay), resumidos com texto próprio -- nunca copiados
/// literalmente. A contagem de cartas é sempre real, vinda de
/// `get_fc_playstyle_summary` (nunca daqui).
///
/// Os 35 nomes abaixo batem exatamente com os 35 valores distintos
/// encontrados em produção em `fc_player_cards.playstyles`/`playstyles_plus`
/// (auditado antes de implementar, Central/Mecânicas).
enum PlaystyleCategory {
  finishing,
  passing,
  defending,
  ballControl,
  physical,
  goalkeeper,
}

class PlaystyleInfo {
  const PlaystyleInfo({
    required this.name,
    required this.category,
    required this.effect,
    required this.plusEffect,
  });

  final String name;
  final PlaystyleCategory category;
  final String effect;
  final String plusEffect;
}

const List<PlaystyleInfo> kPlaystyleCatalog = <PlaystyleInfo>[
  PlaystyleInfo(
    name: 'Finesse Shot',
    category: PlaystyleCategory.finishing,
    effect:
        'Melhora curva, precisão e velocidade de execução do chute de '
        'efeito.',
    plusEffect:
        'Reforça ainda mais curva, precisão e execução do chute de '
        'efeito.',
  ),
  PlaystyleInfo(
    name: 'Chip Shot',
    category: PlaystyleCategory.finishing,
    effect: 'Cavadinhas mais rápidas e precisas sobre o goleiro adiantado.',
    plusEffect: 'Cavadinha ainda mais rápida e precisa.',
  ),
  PlaystyleInfo(
    name: 'Power Shot',
    category: PlaystyleCategory.finishing,
    effect: 'Aumenta força e velocidade da bola no chute de potência.',
    plusEffect:
        'Chute de potência mais forte, com trajetória mais baixa e '
        'controlada.',
  ),
  PlaystyleInfo(
    name: 'Dead Ball',
    category: PlaystyleCategory.finishing,
    effect:
        'Cobranças de falta e escanteio com mais velocidade, curva e '
        'precisão, e prévia de trajetória estendida.',
    plusEffect:
        'Cobranças com velocidade, curva e precisão excepcionais, '
        'prévia de trajetória no máximo.',
  ),
  PlaystyleInfo(
    name: 'Precision Header',
    category: PlaystyleCategory.finishing,
    effect: 'Melhora precisão e potência de cabeceio controlado.',
    plusEffect: 'Ganho de precisão e potência ainda maior no cabeceio.',
  ),
  PlaystyleInfo(
    name: 'Acrobatic',
    category: PlaystyleCategory.finishing,
    effect:
        'Melhora precisão de voleios e libera animações acrobáticas '
        'extras.',
    plusEffect:
        'Precisão maior e acesso a finalizações acrobáticas mais '
        'eficazes.',
  ),
  PlaystyleInfo(
    name: 'Low Driven Shot',
    category: PlaystyleCategory.finishing,
    effect: 'Melhora a precisão do chute rasteiro e forte.',
    plusEffect: 'Bônus de precisão maior no chute rasteiro e forte.',
  ),
  PlaystyleInfo(
    name: 'Gamechanger',
    category: PlaystyleCategory.finishing,
    effect:
        'Chutes de efeito e de trivela (parte externa do pé) com mais '
        'precisão.',
    plusEffect: 'Chutes de efeito e trivela com precisão muito maior.',
  ),
  PlaystyleInfo(
    name: 'Incisive Pass',
    category: PlaystyleCategory.passing,
    effect:
        'Melhora precisão do passe em profundidade, curva do passe com '
        'efeito e velocidade do passe de precisão.',
    plusEffect:
        'Reforça ainda mais os três, sem melhorar o primeiro toque '
        'de quem recebe.',
  ),
  PlaystyleInfo(
    name: 'Pinged Pass',
    category: PlaystyleCategory.passing,
    effect:
        'Passes rasteiros viajam mais rápido sem dificultar o primeiro '
        'toque de quem recebe.',
    plusEffect: 'Passes rasteiros consideravelmente mais rápidos.',
  ),
  PlaystyleInfo(
    name: 'Long Ball Pass',
    category: PlaystyleCategory.passing,
    effect:
        'Lançamentos longos mais precisos, rápidos e difíceis de '
        'interceptar.',
    plusEffect:
        'Reforça ainda mais precisão, velocidade e eficácia dos '
        'lançamentos longos.',
  ),
  PlaystyleInfo(
    name: 'Tiki Taka',
    category: PlaystyleCategory.passing,
    effect:
        'Melhora passes curtos e de primeira difíceis, com backheels '
        'contextuais.',
    plusEffect: 'Bônus de precisão maior nos passes curtos e de primeira.',
  ),
  PlaystyleInfo(
    name: 'Whipped Pass',
    category: PlaystyleCategory.passing,
    effect: 'Cruzamentos com mais precisão, velocidade e curva.',
    plusEffect:
        'Cruzamentos ainda mais fortes, com cruzamento forte de '
        'potência excepcional.',
  ),
  PlaystyleInfo(
    name: 'Inventive',
    category: PlaystyleCategory.passing,
    effect: 'Passes de efeito e de trivela com mais precisão.',
    plusEffect: 'Passes de efeito e trivela com precisão muito maior.',
  ),
  PlaystyleInfo(
    name: 'Jockey',
    category: PlaystyleCategory.defending,
    effect:
        'Melhora o movimento ao marcar de frente (contain) e a '
        'transição entre marcar e correr.',
    plusEffect:
        'Bônus de marcação maior, embora a diferença pra um '
        'defensor forte sem o estilo seja menor no FC 27.',
  ),
  PlaystyleInfo(
    name: 'Block',
    category: PlaystyleCategory.defending,
    effect: 'Aumenta alcance e eficácia ao bloquear chutes e passes.',
    plusEffect: 'Alcance e eficácia de bloqueio ainda maiores.',
  ),
  PlaystyleInfo(
    name: 'Intercept',
    category: PlaystyleCategory.defending,
    effect:
        'Melhora alcance de interceptação e a chance de manter a bola '
        'depois dela.',
    plusEffect:
        'Reforça ainda mais alcance e retenção de bola pós-'
        'interceptação.',
  ),
  PlaystyleInfo(
    name: 'Anticipate',
    category: PlaystyleCategory.defending,
    effect:
        'Melhora o sucesso do carrinho em pé e a chance de sair com a '
        'bola.',
    plusEffect:
        'Bônus significativamente maior no carrinho em pé e na '
        'retenção pós-desarme.',
  ),
  PlaystyleInfo(
    name: 'Slide Tackle',
    category: PlaystyleCategory.defending,
    effect:
        'Melhora a retenção da bola perto do jogador após um carrinho '
        'deslizante bem-sucedido.',
    plusEffect:
        'Cobertura de carrinho deslizante e retenção de bola ainda '
        'maiores.',
  ),
  PlaystyleInfo(
    name: 'Aerial Fortress',
    category: PlaystyleCategory.defending,
    effect:
        'Permite saltos mais altos e mais presença física em disputas '
        'aéreas defensivas.',
    plusEffect:
        'Saltos ainda mais altos e presença física ainda maior nas '
        'disputas aéreas.',
  ),
  PlaystyleInfo(
    name: 'Technical',
    category: PlaystyleCategory.ballControl,
    effect:
        'Melhora a velocidade da corrida controlada e o controle em '
        'curvas mais largas.',
    plusEffect: 'Bônus maior de corrida controlada e controle de drible.',
  ),
  PlaystyleInfo(
    name: 'Rapid',
    category: PlaystyleCategory.ballControl,
    effect:
        'Melhora o drible em velocidade máxima e reduz erros em toques '
        'em alta velocidade.',
    plusEffect: 'Bônus maior de drible em sprint.',
  ),
  PlaystyleInfo(
    name: 'First Touch',
    category: PlaystyleCategory.ballControl,
    effect:
        'Reduz o erro de primeiro toque e acelera a transição pro '
        'drible.',
    plusEffect:
        'Reduz ainda mais o erro de primeiro toque, transição pro '
        'drible ainda mais rápida.',
  ),
  PlaystyleInfo(
    name: 'Trickster',
    category: PlaystyleCategory.ballControl,
    effect: 'Libera embaixadinhas/floreios únicos.',
    plusEffect:
        'Libera floreios extras e mais agilidade ao driblar de '
        'lado.',
  ),
  PlaystyleInfo(
    name: 'Press Proven',
    category: PlaystyleCategory.ballControl,
    effect:
        'Mantém a bola mais perto ao trotar e melhora a proteção contra '
        'oponentes mais fortes.',
    plusEffect:
        'Controle excepcional ao trotar e proteção de bola muito '
        'melhor.',
  ),
  PlaystyleInfo(
    name: 'Quick Step',
    category: PlaystyleCategory.physical,
    effect: 'Melhora a aceleração no sprint explosivo.',
    plusEffect:
        'Bônus de aceleração maior que o normal, mas dependente do '
        'atributo de Aceleração do jogador.',
  ),
  PlaystyleInfo(
    name: 'Relentless',
    category: PlaystyleCategory.physical,
    effect:
        'Reduz o cansaço durante a partida e melhora a recuperação de '
        'fôlego no intervalo.',
    plusEffect:
        'Reduz muito mais o efeito do cansaço de longo prazo nos '
        'atributos.',
  ),
  PlaystyleInfo(
    name: 'Long Throw',
    category: PlaystyleCategory.physical,
    effect: 'Aumenta força e distância do arremesso lateral.',
    plusEffect:
        'Arremesso lateral com ainda mais força e distância '
        'máxima.',
  ),
  PlaystyleInfo(
    name: 'Bruiser',
    category: PlaystyleCategory.physical,
    effect: 'Mais força em disputas físicas de carrinho.',
    plusEffect: 'Vantagem de força ainda maior nas disputas físicas.',
  ),
  PlaystyleInfo(
    name: 'Enforcer',
    category: PlaystyleCategory.physical,
    effect:
        'Melhora disputas de ombro ao driblar e torna a proteção de '
        'bola mais eficaz.',
    plusEffect:
        'Melhora muito mais as disputas de ombro e a proteção de '
        'bola.',
  ),
  PlaystyleInfo(
    name: 'Far Throw',
    category: PlaystyleCategory.goalkeeper,
    effect: 'Arremessos do goleiro com mais velocidade e distância.',
    plusEffect: 'Arremessos com velocidade e distância ainda maiores.',
  ),
  PlaystyleInfo(
    name: 'Footwork',
    category: PlaystyleCategory.goalkeeper,
    effect: 'Defesas com os pés mais rápidas e com mais alcance.',
    plusEffect: 'Defesas com os pés ainda mais rápidas e com mais alcance.',
  ),
  PlaystyleInfo(
    name: 'Cross Claimer',
    category: PlaystyleCategory.goalkeeper,
    effect:
        'Sai para cruzamentos com mais ritmo, melhor leitura de '
        'trajetória, e mais alcance/força no soco.',
    plusEffect: 'Ainda mais ritmo, leitura e força no soco em cruzamentos.',
  ),
  PlaystyleInfo(
    name: 'Rush Out',
    category: PlaystyleCategory.goalkeeper,
    effect:
        'Aumenta velocidade de saída e reação em situações de um '
        'contra um.',
    plusEffect: 'Velocidade de saída muito maior e reações mais rápidas.',
  ),
  PlaystyleInfo(
    name: 'Far Reach',
    category: PlaystyleCategory.goalkeeper,
    effect:
        'Melhora o alcance em defesas de mergulho e libera animações '
        'de alcance estendido.',
    plusEffect:
        'Alcance de mergulho ainda maior e defesas de alcance '
        'estendido mais fortes.',
  ),
  PlaystyleInfo(
    name: 'Deflector',
    category: PlaystyleCategory.goalkeeper,
    effect:
        'Melhora a capacidade de espalmar a bola pra áreas mais '
        'seguras, controlando o rebote.',
    plusEffect:
        'Mais controle de espalmada, podendo direcionar a defesa '
        'pra um lugar seguro ou pra um companheiro.',
  ),
];

String playstyleCategoryLabel(PlaystyleCategory category) => switch (category) {
  PlaystyleCategory.finishing => 'Finalização',
  PlaystyleCategory.passing => 'Passe',
  PlaystyleCategory.defending => 'Defesa',
  PlaystyleCategory.ballControl => 'Controle de bola',
  PlaystyleCategory.physical => 'Físico',
  PlaystyleCategory.goalkeeper => 'Goleiro',
};

PlaystyleInfo? findPlaystyleInfo(String name) =>
    kPlaystyleCatalog.where((info) => info.name == name).firstOrNull;
