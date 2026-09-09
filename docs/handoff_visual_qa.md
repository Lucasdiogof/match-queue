# QA visual/funcional — handoff

Primeira rodada em que o app foi **executado de verdade** e inspecionado na
tela. Todas as rodadas anteriores fecharam com `NOT EXECUTED — ENVIRONMENT
LIMITATION`.

## 1. Como foi executado (e o que continua bloqueado)

| Plataforma | Status |
| --- | --- |
| **Flutter Web (Chrome)** | **EXECUTADO** — foi onde tudo abaixo foi visto |
| Android (emulador) | **NOT EXECUTED — ENVIRONMENT LIMITATION** |
| iOS | fora de escopo desta etapa |

O emulador estava de pé (`emulator-5554`, API 37) e o `adb` responde, mas
**o Gradle não roda nesta ferramenta**. A causa foi isolada até o fim, e não
é a máquina:

```
java.io.IOException: Unable to establish loopback connection
Caused by: java.net.SocketException: Invalid argument: connect
  at sun.nio.ch.UnixDomainSockets.connect0(Native Method)
  at sun.nio.ch.PipeImpl$Initializer$LoopbackConnector.run
```

O JDK abre o pipe interno do Gradle por Unix domain socket e o `connect`
falha com `EINVAL`. Tentados e todos com o mesmo erro: bash e PowerShell,
com e sem sandbox, `--no-daemon`, `TEMP` no caminho longo (o padrão vinha
como `C:\Users\COMPUT~1\...`, 8.3), `-Djava.net.preferIPv4Stack=true` e
`-Djdk.net.unixdomain.tmpdir`. No terminal do próprio dono o build funciona,
como já registrado na Etapa 20 — a limitação é do processo que chama o
Gradle.

**Web**: `flutter build web --no-web-resources-cdn` + servidor estático. O
`--no-web-resources-cdn` é obrigatório aqui — sem ele o CanvasKit é buscado
na CDN, que é bloqueada neste ambiente, e o app fica numa tela preta com
`main()` já executado e nenhuma `flutter-view` montada. Sintoma idêntico ao
já anotado na memória do projeto.

**Modo local**: o build foi feito **sem** `--dart-define-from-file`, o que
faz `supabaseClient == null` e o `get_it` registrar os repositórios locais
(`LocalAuthRepository` e companhia). Nenhuma conta real foi criada, nenhuma
senha real foi digitada e nada tocou a produção: o `LocalAuthRepository` é
um mapa em memória que aceita qualquer par e-mail/senha.

**Consequência honesta**: tudo que depende do catálogo real ou do backend
não pôde ser visto. Ver seção 5.

## 2. Bugs encontrados e corrigidos

### 2.1 Rivals: a divisão não existia na tela de Rivals

O card da Home dizia "Divisão ainda não informada", levava para
`RivalsDetailPage` — e lá **não havia divisão nenhuma**, nem leitura nem
edição, só estatísticas agregadas. O picker existia apenas em
`FcAccountDetailPage`. Beco sem saída: o app apontava o problema e a tela de
destino não resolvia.

Corrigido com uma seção de divisão no topo de `RivalsDetailPage`, reusando
`showRivalsDivisionPickerSheet` — nenhuma segunda forma de escrever o campo.
O rótulo da ação alterna entre "Informar" e "Editar" conforme o estado.
**Verificado ao vivo**: definir Elite atualiza a seção, a Home e persiste.

### 2.2 Bottom sheet de divisão inalcançável em tela baixa

Mesma classe do overflow já corrigido nas sheets de Nação/Liga/Clube, que
tinha passado batido aqui: `Column` sem `isChildScrollable`. Em 360x740 as 12
opções cabiam; **em 360x600 "Elite" ficava atrás da navegação e a lista não
rolava** — a última divisão era impossível de escolher.

Corrigido em `rivals_division_picker_sheet.dart` e, pelo mesmo motivo, em
`fc_account_switcher_sheet.dart` (cresce com o número de contas).
**Verificado ao vivo** a 360x600: a sheet respeita o teto de 85%, rola, e
"Elite" aparece inteira com o check.

### 2.3 Controle prometia o que não dá pra fazer

Título `controlTitle` era **"Seu jogo começa aqui"** — exatamente o padrão de
frase genérica que o dono do produto proibiu. Passou a "Sua vez na fila",
que descreve o que a tela faz.

Pior que a copy: o estado vazio dizia *"Escolha uma conta e um modo pra
começar a buscar partida"* mesmo para quem **já tem** Conta FC e cujo
bloqueio real é não ter Time. Agora o galho de "sem time" distingue os dois
casos da ordem Conta FC → Time: sem conta mostra o onboarding de conta; com
conta e sem time mostra "Você precisa de um time" com ação "Ver times".

### 2.4 Home prometia Rivals/WL antes de existir Conta FC

Com zero contas, o card "Entre em um time" dizia *"Rivals e Weekend League
você já pode usar"* — falso, porque ambos pertencem à Conta FC. Além de
mentir, competia com o CTA de criar a primeira conta, que é a ação certa
naquele momento. O card passou a aparecer só quando já existe Conta FC.
**Verificado ao vivo** nos dois estados.

### 2.5 Buraco morto no card "Clubes"

`SizedBox(height: 88)` ficava **por fora** do `FutureBuilder`, então uma
lista vazia devolvia `SizedBox.shrink()` dentro de uma caixa de 88px e
sobrava um vão embaixo do título. A altura fixa foi para dentro do builder.

### 2.6 Estado vazio repetido em Artilharia e Assistências

As duas seções mostravam a **mesma** frase ("Nenhum gol ou assistência
registrado ainda"), contra o pedido de estado vazio próprio por módulo.
Agora "Nenhum gol registrado ainda." e "Nenhuma assistência registrada
ainda.", nos três idiomas.

### 2.7 Eyebrow repetindo o título

"TIMES / Times" e "HISTÓRICO / Histórico" — o eyebrow não acrescentava nada.
Passaram a usar a marca como eyebrow, o padrão que a Home já usava
("FIFA QUEUE / Visão geral"). Controle não foi tocado: lá eyebrow e título
já eram diferentes.

### 2.8 "Contas" ambíguo no Perfil

A entrada para Contas FC chamava-se só "Contas", numa tela cujo topo é a
conta **do app**. Passou a "Contas FC" / "FC accounts" / "Cuentas FC",
alinhado com "CONTA FC ATIVA" da Home.

### 2.9 Barra de navegacao estourando 2px (reportado pelo dono, em device)

Encontrado **fora** desta ferramenta, rodando no aparelho — e por isso vale
registrar: nao aparecia no Web.

```
A RenderFlex overflowed by 2.0 pixels on the bottom.
  Column ... app_shell_page.dart:232
  constraints: BoxConstraints(w=82.3, h=64.0)
```

O item central (`_PrimaryNavItem`) era uma `Column` com o circulo de 52px
mais o rotulo. `Transform.translate` desloca na pintura mas **nao** reduz a
altura de layout, entao o circulo continuava ocupando 52 dos 64px da barra e
sobravam 12 para o texto. No render Web a linha do `labelSmall` coube; num
aparelho com metrica de fonte um pouco maior, nao — dai os 2px exatos.

Corrigido trocando a `Column` por um `Stack` com `clipBehavior: Clip.none` e
filhos posicionados: o visual e o mesmo (o circulo continua saindo pra fora
da barra) e a altura deixa de depender do tamanho da fonte. O `_NavItem`
comum, que tinha folga mas nenhum limite no rotulo, ganhou `Flexible` +
`maxLines: 1` pela mesma razao. **Verificado**: barra renderiza identica,
sem faixa de overflow.

Licao registrada: `Transform.translate` nao encolhe a caixa de layout. Para
um elemento que precisa desenhar fora do proprio espaco, o certo e `Stack` +
`Clip.none`, nunca translate dentro de um `Flex` com altura fixa.

## 3. Itens verificados sem defeito

| Item | Resultado |
| --- | --- |
| Home sem Conta FC | **PASS** — abre normal, CTA de Conta FC, nunca gate de Time |
| Home com uma Conta FC | **PASS** — "CONTA FC ATIVA", nick, iniciais, "Ainda sem time" |
| Cadastro de Conta FC | **PASS** — "Nova conta", um campo, não parece cadastro do app |
| Navegação 5 abas | **PASS** — Controle central destacado, círculo verde quando ativo, não parece FAB solto |
| Times: Meus Times / Explorar | **PASS** — abas funcionam, estados vazios **diferentes** entre si |
| Histórico vazio | **PASS** — ícone e copy próprios |
| Rivals empty state | **PASS** — "Divisão ainda não informada" |
| Perfil | **PASS** — hierarquia clara, Preferências/Sobre e Legal separados |
| Light / Dark | **PASS** — troca aplica na hora e persiste; claro tem profundidade (cards brancos sobre cinza), escuro não é preto chapado; logo adapta |
| PT / EN / ES | **PASS** — três idiomas percorridos, nenhuma string faltando, nenhum corte |
| Responsividade | **PASS** — 360x600, 360x740 e 1280x720; no desktop vira `NavigationRail`, sem overflow |
| Textura de fundo | **PASS** — sutil nos dois temas, sem neon |

## 4. Testes automatizados

`flutter analyze`: **No issues found**. `flutter test`: **17 testes, todos
verdes**.

**Nenhum teste novo foi adicionado**, e isso é deliberado: os nove defeitos
desta rodada são de layout, de copy e de ramificação de widget. O repositório
não tem harness de widget test (só `test/tool/` e lógica pura), e montar um
para cobrir "esta sheet rola numa tela de 600px" é trabalho próprio, não
apêndice de uma rodada de QA. Cada correção foi verificada executando o app.

## 5. NOT EXECUTED — ENVIRONMENT LIMITATION

Honestamente fora de alcance nesta rodada:

- **Squad Builder** (campo, formações, overlap, banco/reservas) — depende do
  catálogo real; em modo local não há carta nenhuma.
- **Imagens das cartas** — mesma razão. Continua sem evidência visual de que
  `player_image_url` renderiza; a Etapa 18 já validou o dado por REST.
- **Filtros de Nação/Liga/Clube** — as sheets hierárquicas precisam do
  catálogo. O bug de overflow **da mesma classe** foi reproduzido e corrigido
  na sheet de divisão (2.2), mas as três sheets de catálogo não foram vistas.
- **Matchmaking completo** — fila, lock concorrente, partida encontrada,
  cooldown de 30s, "não informar": todos exigem backend real e um Time.
- **Histórico com dados** — a linha nova (conta, modalidade, resultado,
  "Resultado não informado") só foi validada por SQL e teste unitário na
  rodada anterior; visualmente só o estado vazio foi visto.
- **Weekend League** — o seletor de semana precisa de
  `list_weekend_league_events`, que é backend.
- **Perfil público / Time privado** — exigem backend e um segundo usuário.
- **Realtime, reconexão, background/foreground**, notificações.
- **Android físico/emulador** — ver seção 1.

Para fechar esses itens é preciso rodar com `--dart-define-from-file=env/
development.json` e um usuário real, ou destravar o Gradle. Nenhum dos dois
está disponível aqui.

## 6. Observações que NÃO viraram mudança

- O subtítulo da Home ("Seu time e sua semana em um lugar") fala em "time"
  mesmo para quem não tem nenhum. É impreciso, mas descreve a tela em regime
  normal; trocar por algo condicional adicionaria estado sem ganho claro.
- O card de Weekend League não aparece em modo local porque não há evento.
  Em produção existem 5 semanas geradas, então isso **não** é evidência de
  bug — só não deu pra confirmar aqui.
- Estados de hover "presos" vistos em alguns cliques são artefato dos eventos
  de ponteiro sintéticos usados para dirigir o app, não comportamento real.
