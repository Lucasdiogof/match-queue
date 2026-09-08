# Handoff — Etapa 17 (Auditoria de lançamento)

Status em 2026-09-08: **auditoria concluída, nenhuma feature nova
implementada**, como pedido. HEAD `28ecdf9` = `origin/main`, 71 migrations
locais = 71 remotas, `flutter analyze` — No issues found (reconfirmado).

## O que esta etapa é

Não é uma etapa de produto. É um raio-x do estado real do projeto contra
critério de lançamento — feito por leitura de todos os handoffs
anteriores (7 a 16) mais inspeção direta de código, rotas, migrations,
config Android/iOS/Web, l10n e segurança estática.

**Relatório completo**: [`launch_gap_analysis.md`](launch_gap_analysis.md).
Leia lá o detalhe — este documento é só o índice.

## Achado principal, em uma frase

Backend e domínio estão em ótimo estado (RLS/security definer uniformes,
zero bug crítico novo encontrado, zero secret exposto, rotas todas
alcançáveis); o que falta para publicar de verdade é o pacote em volta do
produto: **zero teste automatizado, sem CI/CD, sem assinatura de release,
sem Política de Privacidade/Termos, sem exclusão de conta, e risco de
marca não avaliado** (nome/strings citam "FIFA"/"EA SPORTS FC"/"Ultimate
Team" diretamente).

## Correções aplicadas

Nenhuma. Não foi encontrado bug crítico trivial, nem secret exposto no
repositório (os 4 arquivos com chave Firebase de cliente existem só
localmente, corretamente fora do git), nem nada quebrando a própria
auditoria. Uma divergência de documentação foi encontrada
(`docs/database.md` lista `notification_preferences`/`devices` como "não
existe ainda", desatualizado desde a Etapa 7) — reportada, não corrigida:
é reescrita de seção inteira, não correção trivial de uma linha.

## Percentual geral estimado

**≈ 68%** ponderado (ver `launch_gap_analysis.md`, seção 2, para o
detalhe e a explicação dos pesos por dimensão).

## Próximo passo sugerido

Não é a Etapa 18 de produto. É decidir, com o dono do produto, a Fase A
do roadmap do relatório (nome/marca, Política de Privacidade/Termos,
exclusão de conta, assinatura de release) — sem isso nenhuma loja aceita
o app, independente de quão pronta a Etapa 16 esteja.

## Git

Migrations: nenhuma nova. Nenhum código mudou. Commit desta etapa é só
os dois documentos novos + atualização do índice (`handoff.md`).
