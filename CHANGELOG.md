# Changelog

History of the app's features, most recent first. Internal audits, data-import
scripts and validation-only sessions aren't listed here — only what changes
the experience of using the app.

## 2026-09-09

- **Squad Builder**: the full real card catalog is now live — 17,873 real
  players and cards (men's and women's football), replacing the small
  development sample.

## 2026-09-08

- **Notifications**: new notification center (bell icon with unread badge,
  inbox with read/unread, pagination) alongside push. Preferences are now
  grouped by category (Matchmaking, Teams, Weekend League, Rivals, Rankings)
  instead of one toggle per alert.
- **Profile**: opt-in public profile with a shareable link, showing your
  main lineup and sporting stats to anyone with the link.
- **Time**: sporting record, ranking and top scorer/assist leaderboards for
  the whole team, in one dashboard.
- **Partidas**: per-player goals and assists, editable results (no time
  limit), and a dedicated match details screen.
- **Contas (Elenco)**: Weekend League and Rivals detail pages per account,
  with a manual record override when needed.
- **Squad Builder**: overall and chemistry are computed automatically, with
  drag-and-drop, a reserves bench, and a breakdown of why each starter has
  the chemistry they have.
- **Jogar**: pending-match card, game mode selector, and a combined
  search+match history timeline.
- Renamed "Elenco" to "Conta" everywhere in the app for clarity.
- One search now covers every team an account is linked to, instead of
  requiring a separate search per team.
- **Time**: split into a team list and a per-team detail screen, with
  individual player profiles.
- Push notifications now use real Firebase device tokens.
- **Conta**: account deletion, and public Privacy Policy / Terms of Use /
  About pages.
- Production Android release signing configured.

## 2026-09-07

- First version of the app: Flutter project for Android, iOS and Web with
  the FIFA Queue design system and brand.
- Real authentication (sign up, log in, password reset) via Supabase.
- **Time**: create a team, invite others via a shareable link/code, switch
  between teams.
- **Buscar** (matchmaking): only one person searches per team at a time, the
  rest wait in a queue that advances automatically and updates in real time
  — no more manual refreshing.
