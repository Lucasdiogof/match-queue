# Google Play — formulário de Data Safety

Levantamento real do que o app coleta, feito por leitura de código
(schema Supabase + dependências do `pubspec.yaml`), pra preencher o
formulário oficial da Play Console sem depender de memória ou suposição.
O preenchimento em si só existe dentro do Console (**NEEDS PLAY
CONSOLE**) — este documento é o insumo, não o formulário.

## O que o app coleta de verdade

| Categoria (taxonomia da Play Store) | Coletado? | Campo/fonte real |
| --- | --- | --- |
| **Informação pessoal — E-mail** | Sim | `auth.users.email` (Supabase Auth) |
| **Informação pessoal — Nome** | Sim | `profiles.display_name` |
| **Fotos** | **Não** | Nenhum `image_picker`/câmera/galeria no `pubspec.yaml` — `avatar_url` não é upload de foto do device |
| **Localização** | Não | Nenhuma dependência de geolocalização |
| **Contatos** | Não | Nenhuma dependência de acesso a contatos |
| **Identificadores de dispositivo — Device/token ID** | Sim | `user_devices.fcm_token` (token de push do Firebase, por device) |
| **App activity — In-app actions** | Sim | Times, contas FC, squads, partidas, matchmaking, notificações — todo o uso funcional do app, vinculado ao `user_id` |
| **App info and performance — Crash logs** | Sim | Firebase Crashlytics (`firebase_crashlytics` no `pubspec.yaml`) |
| **Financeiro** | Não | Nenhum pagamento/compra no app |
| **Saúde e fitness** | Não | N/A |
| **Mensagens** | Não | Nenhum chat/DM entre usuários |
| **Pesquisa no app** | Sim (indiretamente) | Busca de jogador/carta no picker (`search_fc_player_cards`) — não é dado pessoal do usuário, é busca no catálogo, não precisa ser declarada como coleta de dados pessoais |

## Perguntas do formulário (respostas objetivas, pra colar no Console)

| Pergunta | Resposta |
| --- | --- |
| O app coleta ou compartilha algum dos tipos de dados do usuário? | **Sim** |
| Todos os dados coletados são criptografados em trânsito? | **Sim** — todo tráfego é HTTPS (Supabase + FCM) |
| O app fornece uma forma de o usuário solicitar a exclusão dos dados? | **Sim** — exclusão de conta real dentro do app (Fase A) |
| E-mail é compartilhado com terceiros? | **Não** — usado só para autenticação (Supabase Auth), não repassado |
| Nome é compartilhado com terceiros? | **Não** — visível só pros outros membros do time e, opt-in, no perfil público (Etapa 16) |
| Device/token ID é compartilhado com terceiros? | **Sim, com o Google (Firebase Cloud Messaging)** — necessário pra entregar push, é o provedor de infraestrutura, não um terceiro de marketing |
| Crash logs são compartilhados com terceiros? | **Sim, com o Google (Firebase Crashlytics)** |
| Os dados são usados para publicidade? | **Não** |
| Os dados são usados para personalização? | **Não** — a "personalização" que existe (times, squads) é a própria funcionalidade do app, não segmentação de anúncio |
| A coleta de dados é obrigatória ou opcional? | E-mail/nome: **obrigatórios** (necessários pra criar conta). Device token: **opcional na prática** — o app funciona sem push, mas o toggle de notificação é do usuário. |

## Finalidade declarada de cada dado

- **E-mail**: autenticação/gerenciamento de conta.
- **Nome**: funcionalidade do app (identificar o jogador dentro do time/squad).
- **Device/token ID**: funcionalidade do app (entregar notificações push).
- **In-app actions**: funcionalidade do app (matchmaking, squads, stats).
- **Crash logs**: diagnóstico/correção de bugs.

## O que NÃO declarar (evitar sobre-declaração)

Não marcar: Localização, Financeiro, Saúde, Contatos, Fotos/Vídeos,
Áudio, Calendário, Histórico de navegação — nenhuma dessas categorias
tem coleta real neste app, confirmado por ausência de dependência
correspondente no `pubspec.yaml` e ausência de coluna correspondente no
schema Supabase.

## Status

**NEEDS PLAY CONSOLE** para o preenchimento formal — todo o
levantamento de fato (esta tabela) já está pronto e não depende de mais
nenhuma auditoria de código.
