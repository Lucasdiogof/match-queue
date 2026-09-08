# Pesquisa de provedores de dados de cartas EA FC 27

Feita na Etapa 11 (2026-09-08), via WebSearch/WebFetch. Objetivo: escolher a
fonte dos dados reais de cartas que substituem as 50 cartas `provider =
'LOCAL'` da Etapa 10 (`docs/handoff_etapa10.md`).

## Regra dura, repetida aqui de propósito

Nunca contornar CAPTCHA, Cloudflare, nem usar cookies/tokens roubados ou
privados. Qualquer fonte que exigisse isso foi descartada, sem exceção,
mesmo que fosse tecnicamente a "melhor" cobertura de campos.

## Achado que muda o cenário: EA lançou uma Community API oficial

Em julho de 2026 a EA anunciou uma **Community API** oficial para o EA
SPORTS FC, concedendo acesso aprovado a dados de conta/Ultimate Team para
parceiros selecionados — FUT.GG, FUTBIN e FUTWIZ estão entre os primeiros
aprovados. Isso significa duas coisas:

1. Os três sites do pedido original (fut.gg, futbin, futwiz) hoje têm um
   canal **oficial e legítimo** de acesso a dados — mas esse canal é deles
   como parceiros aprovados pela EA, não um endpoint público que o FIFA
   Queue possa simplesmente consumir sem virar parceiro EA também.
2. Sem ser parceiro aprovado, o único jeito de tirar dados desses três
   sites hoje é scraping do HTML/JSON interno deles — o que esbarra direto
   na regra dura: os três já reforçaram proteção (Cloudflare/ToS) depois
   de virarem parceiros oficiais, exatamente para não vazar a integração
   nova.

## Comparativo

| Fonte | Tipo de acesso | Cobertura de campos | Estabilidade / risco | ToS |
| --- | --- | --- | --- | --- |
| **fut.gg** | Antes: paginação JSON não-documentada em `/players/`. Hoje: parceiro da EA Community API (acesso oficial, mas exige ser aprovado como parceiro EA — não é um endpoint público). Tentativa de acesso direto sem parceria caiu em 404/Cloudflare nesta pesquisa. | Historicamente completa (rating, posições, GK, playstyles, skill moves, pé fraco, altura, papéis) quando acessível. | Alto risco: por trás de Cloudflare, layout/API interna muda sem aviso, e agora tem incentivo extra da EA para fechar acesso não-parceiro. | Descartado — exigiria contornar proteção anti-bot. |
| **futbin.com** | ToS (`futbin.com/tos`) proíbe explicitamente "unauthorized access to the Website... or any server, computer, or database connected". Tem endpoints de terceiros (Apify, Parse.bot) fazendo scraping por fora, o que não muda o ToS do site em si. Também virou parceiro da EA Community API. | Rating, posições, preço de mercado, SBCs, playstyles — boa cobertura, mas parte fica atrás de assinatura premium no próprio site. | Alto risco/descartado: ToS proíbe explicitamente, e contornar isso seria a exata prática que a regra dura veta. | **Descartado por ToS explícito.** |
| **futwiz.com** | Não foi encontrado endpoint público documentado; mesmo padrão dos outros dois (site com proteção anti-bot, dados via scraping não-oficial). | Provavelmente comparável a fut.gg/futbin (não verificado a fundo, descartado antes por causa do padrão de acesso). | Alto risco — mesmo raciocínio dos outros dois. | Descartado pelo mesmo motivo estrutural. |
| **Datasets comunitários (GitHub/Kaggle)** — ex. `EAFC26-DataHub` (Kaggle "FC 26 Player Data", ~18k jogadores, 110+ atributos), `sofifa-web-scraper` (scrape do SoFIFA, ~18k jogadores), `FC25-Players-ETL` | Download direto de arquivo CSV/JSON versionado — **sem scraping ao vivo, sem bot, sem CAPTCHA**. Atualização é manual (baixar o CSV mais novo), não um endpoint. | Ampla (rating, posições, stats, nação, liga, clube, altura, pé) — GK stats e playstyles variam por dataset, precisam de validação campo a campo antes do import. | Baixo risco operacional (arquivo estático, licença geralmente aberta/CC), mas **não é tempo real** — cada atualização de patch da EA exige baixar um CSV novo manualmente. | Depende da licença específica do dataset (verificar antes de redistribuir imagens). |
| **SoFIFA.com** | HTML público, tabelas simples, sem login, historicamente tolerante a scraping pontual e de baixo volume (não confirma ToS explícito nesta pesquisa). | Rating, posições, stats completos, nação, liga, clube, altura, pé — GK stats e playstyles mais limitados que fut.gg/futbin. | Risco médio: é scraping de HTML de um site de terceiros (frágil a mudança de layout), mas sem Cloudflare/CAPTCHA hoje. | Sem ToS anti-scraping explícito encontrado, mas convém manter volume baixo e cache local. |

## Decisão

**Provider primário: dataset comunitário estático (CSV/JSON versionado, tipo
Kaggle "FC 26 Player Data" ou equivalente do GitHub).** Justificativa:

- É o único caminho que não depende de scraping ao vivo nem de contornar
  proteção alguma — cumpre a regra dura com folga, não no limite dela.
- A importação já era desenhada para ser um processo manual/periódico
  (`npm run sync:fc-cards` rodado à mão), então "não ser tempo real" não é
  uma desvantagem real para este produto — ele já não pretendia sincronizar
  a cada patch da EA automaticamente.
- O schema (`provider`, `provider_card_id`, `last_synced_at`, `source_url`)
  foi desenhado para aceitar qualquer fonte compatível depois, incluindo
  fut.gg/futbin/futwiz no dia em que o FIFA Queue eventualmente vire parceiro
  aprovado da EA Community API — essa é a linha oficial e correta pra esse
  caminho, não scraping por fora.

**Fallback: SoFIFA**, só para preencher campos que o dataset comunitário não
tiver (ex.: imagem de clube específica) — scraping pontual, baixo volume,
nunca automatizado num cron, sempre revisado manualmente antes de upsert.

**Nunca**: fut.gg, futbin, futwiz por scraping direto. Ficam registrados
aqui como "vire parceiro oficial da EA Community API primeiro", não como
"tente contornar a proteção deles".

## O que isso significa para o importer desta etapa

O importer (`tool/sync_fc_cards.dart`, descrito no handoff) foi escrito para
ler um arquivo CSV local já baixado pelo usuário (dataset comunitário) e
fazer upsert idempotente — nunca para baixar nada da internet sozinho.
Baixar o CSV de fato (Kaggle exige conta/click manual, então nem daria pra
automatizar sem credenciais) e rodar o importer contra o Supabase remoto
ficou como **pendência consciente**, documentada no handoff — esta sessão
não tinha o arquivo de dados real disponível nem permissão prévia para
baixar um arquivo de terceiro sem confirmação explícita do usuário no chat
(regra do ambiente: download de arquivo é ação que exige permissão
explícita, e esta sessão roda sem supervisão síncrona).
