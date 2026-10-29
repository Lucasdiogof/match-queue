# Match Queue Web (Cloudflare Workers + Static Assets)

Padrão: `Lucasdiogof/lucksrei-web-template`. Estado: **preparado, não publicado** (nenhum Worker `matchqueue-web` criado, sem DNS).

- Arquivos: `wrangler.jsonc` (Worker `matchqueue-web`, só assets; rota `matchqueue.lucksrei.com` comentada), `web/_headers`, `scripts/*.sh`.
- Build: `bash scripts/build-web.sh env/production.json` (`env/*.json` é gitignored). A web não usa Firebase (`kIsWeb` pula a inicialização).
- Deploy manual: `bash scripts/deploy-web.sh env/production.json`. Rollback: `npx wrangler rollback <id> --name matchqueue-web`.
- Sem deploy automático (nenhum secret criado). O Codemagic atual só roda qualidade (Linux) no push e um `web-preview` manual.
- As rotas públicas `/privacy`, `/terms` e `/u/:identifier` funcionam sem sessão e foram verificadas no `wrangler dev` local (200 com fallback de SPA).

## Validado (2026-10-17)
`flutter build web --release` compila (Flutter 3.47.4); bundle sem chaves privilegiadas; headers de segurança presentes.
**Não validado**: login, fila e cartas no navegador (handoff já registra que o preview web não rodava ao vivo).

## Privacidade
- Auditoria das migrations: as 41 tabelas criadas têm RLS habilitada. Os buckets de storage do app de contas foram apagados (ver memória do projeto), portanto não há upload de avatar a revisar.
- A política in-app (pt/en/es, `lib/features/legal/data`) agora cita a Cloudflare como hospedagem da versão web (recebe IP/horário) e informa que o Firebase não é usado na web; data atualizada para 2026-10-17.
- Para a loja web o link público da política seria `https://matchqueue.lucksrei.com/privacy`.

## Pendências externas
1. Autorização de DNS (`matchqueue.lucksrei.com`).
2. Se houver confirmação de cadastro por link na web: cadastrar só `https://matchqueue.lucksrei.com/` nas Redirect URLs do projeto Supabase do EA FC (**não alterado**). A recuperação por código não precisa de redirect.
3. Confirmar SMTP custom no Supabase (embutido = 2 e-mails/hora).

## Ambiente de teste e deploy (2026-10-17)
- Teste publicado em https://matchqueue-web.lucasdiogo1234.workers.dev (Worker `matchqueue-web`, versão d83ea02c). Smoke estrito passou (raiz, assets, `/privacy`, `/terms`, `/join/:code`, `/u/:id`, headers).
- QA em Chrome real: login em ~1,5 s, `/privacy` em ~0,5 s, convite inexistente mostra "Convite não encontrado"; 0 erros de console, 0 respostas 4xx/5xx.
- **Convites na web:** o `env/production.json` tem `APP_LINK_HOST=lucksrei.com`; usado na web geraria links para o site institucional. O workflow usa o segredo `WEB_ENV_JSON` (cópia do JSON de produção com `APP_LINK_HOST=matchqueue.lucksrei.com`), então os links de convite apontam para o domínio do app.
- Workflows: `deploy-web.yml` (gate `AUTO_DEPLOY`, Wrangler 4, smoke) e `rollback-web.yml`. Segredos: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, `WEB_ENV_JSON` (só nomes). `AUTO_DEPLOY` **não** foi definido (ação do dono).
- Domínio `matchqueue.lucksrei.com`: rota ainda comentada em `wrangler.jsonc`; ativar junto com a Site URL/Redirect URL do Supabase do projeto (`https://matchqueue.lucksrei.com/`).
- Login, recuperação por código e Realtime **não testados** (exigem conta).

## Verificação independente (2026-10-17, noite)
- Smoke estrito do template (`scripts/smoke-test.sh`, agora igual ao `lucksrei-web-template`) contra `https://matchqueue-web.lucasdiogo1234.workers.dev`: **passou** (HTML, `flutter_bootstrap.js`, `main.dart.js` 4,4 MB como JavaScript, `manifest.json`, `version.json` 1.0.3+8, rotas `/login /privacy /terms /join/:code /u/:id` com fallback de SPA, headers `x-content-type-options`, HSTS, `x-frame-options`, `referrer-policy`).
- Navegador: `/login`, `/privacy` (inclusive 375 px), `/terms` e `/join/TESTE123` ("Convite não encontrado") renderizam; 0 erros de console, todas as requisições 200.
- O workflow passou a checar só a URL viva (`workers.dev`) e as rotas profundas; `matchqueue.lucksrei.com` volta ao `SMOKE_URLS` quando a rota de domínio for ativada (antes disso o smoke falharia por DNS inexistente).
- **Deploy pelo CI comprovado** (run 39069481017, `workflow_dispatch`): build web, checagem de segredos no bundle, deploy Wrangler 4 e smoke estrito, todos ok. O primeiro run (39069171666) falhou porque `lib/firebase_options.dart` é gitignored; o workflow agora grava um stub quando o arquivo não existe (a web nunca inicializa o Firebase). Depois do deploy, `/join/TESTE123` chama `rpc/resolve_team_invite` no Supabase com 200.
- `AUTO_DEPLOY` continua indefinido (push não publica); deploy manual: Actions > Deploy web > Run workflow.
