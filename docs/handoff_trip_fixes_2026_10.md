# Match Queue — correções da viagem (MAT-001/002/003)

Origem: pacote `MatchQueue_Correcoes_Viagem` (14–15/10/2026), três screenshots
de uso real. Tudo foi feito direto na `main`, em commits pequenos.

**Verificação:** nesta fase **não** foram executados `flutter analyze`,
testes, builds nem publicação (regra do pacote; o Flutter também não estava no
PATH desta máquina). Os testes novos foram escritos mas **não rodados**. Os
arquivos `lib/l10n/generated/*` foram editados à mão para espelhar os `.arb`;
rodar `flutter gen-l10n` deve gerar diff vazio ou só de formatação.

## MAT-001 — catálogo/mercado sem versões especiais

**Diagnóstico.** Há duas causas, e só uma é do app.

1. **Fonte (não é bug do app).** O catálogo de produção vem do snapshot
   `WREXIST_EA_FC27_SNAPSHOT` (17.923 cartas / 17.873 jogadores, ver
   `docs/card_artwork_gap.md` e `docs/handoff_etapa17b2.md`): é o ratings base
   da EA, uma carta por jogador. Não traz TOTW, UCL, eventos nem edições
   especiais, e nenhuma fonte gratuita/legítima de cartas UT foi aprovada
   (`docs/card_provider_research.md`: FUTWIZ, FUTBIN, FUT.GG, WeFUT etc.
   bloqueiam automação). **Cartas que a fonte não tem não aparecem, e o app não
   inventa cartas, imagens nem preços.** O importador
   (`tool/sync_fc_cards.dart`) já trata edição pela identidade da carta
   (`provider_card_id`), então, se uma fonte futura trouxer edições, elas entram
   sem mudança de modelo.
2. **App (corrigido).**
   - A busca do Mercado pedia uma única página de 30 e não tinha como chegar ao
     resto: nomes com muitas cartas eram truncados em silêncio.
   - `PlayerCardQuery.nextPage()` descartava o filtro `positions` (grupo de
     posição), então a página 2 misturava todas as posições.
   - `search_fc_player_cards` ordenava por `rating, player_name`: cartas
     diferentes do mesmo jogador com o mesmo overall empatam, e com
     `limit/offset` podem repetir ou sumir entre páginas.
   - O item do Mercado não mostrava versão nem clube, então duas edições do
     mesmo jogador eram indistinguíveis.

**Solução.** `MarketSearchCubit.loadMore` + botão "Carregar mais" (dedup só por
**id da carta**, nunca por nome/jogador); `nextPage` mantém `positions`;
migration `20261022100000_search_fc_player_cards_stable_order.sql` (desempate
por `c.id`, mesma assinatura/filtros/grants); badge de `card_type` e clube no
`MarketCardTile`.

**Limitações.** Sem edições na fonte, o resultado visível não muda hoje. A
migration precisa ser aplicada no Supabase (`supabase db push`) — **não
aplicada** nesta sessão. Não há filtro de versão na UI do catálogo: sem dados
de versão distintos ele seria vazio.

## MAT-002 — mesma senha na recuperação

**Diagnóstico.** A rejeição vem do **backend**: o Supabase Auth responde
`422 same_password` ("New password should be different from the old
password") em `updateUser`. Não é validação da UI (`AppValidators` só checa
tamanho/confirmação) nem configurável pelo cliente. O mapper não conhecia o
código e caía em `AuthFailureReason.unknown`, daí a mensagem genérica "Não foi
possível concluir a autenticação." da screenshot.

**Solução.** Novo `AuthFailureReason.samePassword` mapeado de `same_password`,
com mensagem clara em pt/en/es ("A nova senha precisa ser diferente da senha
atual."). Não há contorno: a regra é obrigatória do provedor, e permitir a
mesma senha exigiria enfraquecer a política (fora de escopo). Loading e
navegação pós-sucesso (`/central`) já estavam corretos e não foram alterados.

## MAT-003 — Jogar offline

**Diagnóstico.** A aba Jogar é `ControlPage`. Os times só carregam depois que
a conta resolve (`TeamsSessionListener`); offline a conta falhava e nada era
guardado, e a página devolvia `SizedBox.shrink()` para conta nula — tela
vazia, sem spinner nem erro.

**Solução.**
- `AccountCacheStore` / `TeamsCacheStore` (SharedPreferences, já adotado no
  projeto; sem dependência nova): última conta e lista de times carregadas com
  sucesso, **um usuário por aparelho** (leitura com outro `user_id` devolve
  vazio; escrita sobrescreve; `clear()` ao sair, via `AccountCubit.clear` e
  `TeamsCubit.clear`). Só campos estáveis: nome, plataformas, divisão, times.
  Placar, campanha vigente, fila e membros **não** são salvos.
- Cubits mostram o cache na hora, revalidam, e em falha mantêm o cache com a
  falha registrada (`cachedAt`).
- `ControlPage`: nunca vazia (carregando / erro offline com "Tentar de novo" /
  dados salvos). Banner "Sem conexão… Última atualização: …" quando a
  atualização falhou. Matchmaking vira cartão desabilitado explicativo
  (`_OnlineOnlyCard`); **não há simulação de fila/partida offline**. Cards de
  Champions/Rivals ficam ocultos enquanto a conta mostrada é a salva.
- Revalidação: pull-to-refresh, botão de tentar de novo e retorno ao app
  (`AppLifecycleState.resumed`) — não há pacote de conectividade, e não
  adicionamos um.

**Limitações.** Elenco (`AccountSquadCard`/FC squads) e a aba Times continuam
dependendo do servidor; não foram cacheados. A detecção de reconexão é por
ação/retomada, não por evento de rede.

## Checklist manual (iOS e Android)

- [ ] Recuperação: código → nova senha **igual** à antiga → mensagem "precisa
  ser diferente"; senha diferente → sucesso, vai para Central.
- [ ] Online: abrir Jogar, conferir conta, time, modo e fila normais.
- [ ] Modo avião após uso online: matar o app, reabrir → Jogar mostra conta e
  time salvos, banner de sem conexão com data, matchmaking desabilitado.
- [ ] Primeira abertura offline em instalação limpa → estado "Sem conexão" com
  "Tentar de novo", nunca tela vazia.
- [ ] Reconectar: "Tentar de novo", puxar para atualizar e voltar ao app
  revalidam; banner some, fila volta, sem sessão duplicada.
- [ ] Trocar de conta / sair: dados da conta anterior não aparecem na nova.
- [ ] Mercado: buscar nome com >30 cartas → "Carregar mais" traz o resto sem
  repetidos; item mostra clube e versão quando existir.
- [ ] Catálogo por grupo de posição: página 2 mantém o filtro.
- [ ] Após `supabase db push`: paginação do catálogo sem repetidos/faltando.
