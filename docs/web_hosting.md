# Match Queue Web (Cloudflare Workers + Static Assets)

Padrão: `Lucasdiogof/lucksrei-web-template`. Estado: **preparado, não publicado** (nenhum Worker `matchqueue-web` criado, sem DNS).

- Arquivos: `wrangler.jsonc` (Worker `matchqueue-web`, só assets; rota `matchqueue.lucksrei.com` comentada), `web/_headers`, `scripts/*.sh`.
- Build (flavor EA FC, o padrão da web): `bash scripts/build-web.sh env/production.json` (`env/*.json` é gitignored). A web não usa Firebase (`kIsWeb` pula a inicialização).
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
