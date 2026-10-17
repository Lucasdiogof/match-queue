Você é um pesquisador técnico. Preciso da sua ajuda para achar uma fonte LEGÍTIMA de dados de cartas do EA SPORTS FC 27 Ultimate Team, incluindo versões especiais.

## Contexto do app

Match Queue é um app mobile (Flutter, iOS e Android, backend Supabase/Postgres) para jogadores de EA FC combinarem partidas online entre times. Ele tem:

- Um Squad Builder (monta escalação com cartas) e uma aba Mercado onde a pessoa busca uma carta e vê o preço.
- Um catálogo de cartas no banco, com cerca de 17,9 mil cartas (masculino e feminino), buscável por nome, posição, liga, clube e nação.
- Um importador próprio que lê CSV e grava uma linha por carta, identificada por um id externo de carta (provider card id). Ele já aceita as colunas: card type, rarity, rating, posições, atributos, playstyles, clube, liga, nação, imagem do jogador e imagem da carta.

## O problema

O catálogo atual vem de um dataset público de ratings base (um repositório do GitHub sem licença declarada, snapshot de 28/08/2026). Ele tem UMA carta por jogador. Faltam: TOTW, Team of the Year, UCL, cartas de eventos, Icons, Heroes e outras edições especiais do mesmo jogador. Não temos imagens de carta nem de jogador (só texto e números).

## O que já foi descartado (não sugira de novo)

FUTBIN, FUTWIZ, FUT.GG, WeFUT, SoFIFA, fcratings.com e as páginas de ratings da EA: ou o robots.txt bloqueia automação, ou os termos de uso proíbem coleta automatizada, ou a EA reserva direitos contra mineração de dados. Não existe dataset FC 27 de cartas Ultimate Team em Kaggle ou GitHub com licença clara, até onde pesquisamos.

## Regras duras

- Nada de scraping de sites que proíbem, nada de burlar CAPTCHA, Cloudflare ou login, nada de cookies ou tokens privados.
- Só aceito fontes onde o uso comercial e a redistribuição em um app estejam claramente permitidos (API oficial, parceria, licença aberta ou autorização por escrito).
- Não invente nomes de APIs, endpoints, datasets ou licenças. Se não tiver certeza, diga que não tem.

## O que quero de você

1. Liste fontes possíveis de dados de cartas UT do FC 27 com edições especiais: APIs oficiais ou de parceiros, programas da EA para desenvolvedores, datasets licenciados ou abertos, serviços pagos com licença para apps. Para cada uma, diga: nome, link, o que cobre (edições especiais, imagens, preços), formato, custo, e o que a licença ou os termos permitem de fato (cite o trecho ou a página).
2. Diga quais exigem contato comercial ou aprovação, e escreva um rascunho curto de e-mail para pedir autorização (em inglês).
3. Se nada atender às regras duras, diga isso claramente e sugira alternativas realistas (por exemplo, um catálogo próprio mantido à mão só com as edições mais populares, usando somente texto e números, sem imagens oficiais).
4. Marque o que você confirmou em fonte oficial e o que é apenas suposição.

Responda em português do Brasil, com links verificáveis, e não afirme nada sobre licenças sem apontar de onde tirou.
