# Checklist de metadata — Google Play e App Store

Nada aqui foi inventado. Onde não existe texto/URL real, fica marcado
como `MISSING` ou `NEEDS USER INPUT` — nunca preenchido com um
placeholder que pareça definitivo.

## Google Play Console

| Item | Status | Observação |
| --- | --- | --- |
| Nome do app | **NEEDS USER INPUT** | "FIFA Queue" é o nome usado no código/manifest, mas o nome de listagem na loja é uma decisão de produto (pode diferir por marca registrada da EA/FIFA) |
| Short description (80 caracteres) | **MISSING** | Não existe texto escrito ainda |
| Full description | **MISSING** | Não existe texto escrito ainda |
| Categoria | **NEEDS USER INPUT** | Provavelmente "Esportes" ou "Ferramentas", decisão do dono do produto |
| Screenshots (telefone/tablet) | **MISSING — NEEDS PHYSICAL DEVICE** | Precisa do app rodando de verdade numa tela pra capturar |
| Feature graphic (1024×500) | **MISSING** | Arte de banner, não existe ainda |
| Ícone de alta resolução (512×512) | **READY** — pode ser exportado do ícone adaptativo já existente (`launcher_icon`) | Confirmar resolução exata antes de subir |
| Privacy Policy URL | **MISSING — NEEDS USER INPUT** | O app tem uma tela de Política de Privacidade (`privacy_policy_page.dart`), mas a Play Store exige uma **URL pública hospedada**, não só uma tela dentro do app — precisa de um domínio/hosting (mesma dependência de domínio do App Links) |
| Data safety (formulário) | **NEEDS USER INPUT** | Precisa do dono do produto responder o questionário oficial da Play Console — o código já mostra o que é coletado (e-mail, nome, dados esportivos opcionais), mas o formulário é preenchido manualmente na Play Console, não algo que o repositório provisiona |
| Content rating (questionário IARC) | **NEEDS USER INPUT** | Preenchido na Play Console |
| App access (login de teste pro revisor) | **NEEDS USER INPUT** | Recomendado criar uma conta de revisor dedicada e informar as credenciais no formulário de review |
| Ads declaration | **READY (não tem anúncios)** — declarar "não contém anúncios" | Nenhum SDK de ads no `pubspec.yaml` |
| Target audience / idade | **NEEDS USER INPUT** | Decisão de produto |
| Account deletion (URL ou fluxo no app) | **READY** — o app já tem exclusão de conta real, dentro do próprio app (Fase A). A Play Store aceita declarar o fluxo in-app, não exige URL separada se o fluxo existe | |
| AAB assinado | **NOT EXECUTED** — ver `release_checklist_android.md` (bloqueio de keystore + ambiente) | |
| Release track (internal/closed/open) | **NEEDS USER INPUT** | Decisão de produto — recomenda-se testagem interna antes de produção |

**Estimativa objetiva de completude Google Play: ~35%** (o que depende
só de configuração de app — ícone, exclusão de conta, ads — está pronto;
o que depende de texto/arte/decisão humana e de um AAB assinado, não).

## App Store Connect

| Item | Status | Observação |
| --- | --- | --- |
| Nome | **NEEDS USER INPUT** | Mesma ressalva de marca da Play Store |
| Subtitle | **MISSING** | Não existe texto ainda |
| Description | **MISSING** | Não existe texto ainda |
| Keywords | **MISSING** | Não existe lista ainda |
| Screenshots (por tamanho de tela exigido) | **MISSING — NEEDS PHYSICAL DEVICE + macOS** | Precisa rodar no simulador/device real |
| Privacy Policy URL | **MISSING — NEEDS USER INPUT** | Mesma dependência de domínio/hosting da Play Store |
| App Privacy (questionário de coleta de dados) | **NEEDS USER INPUT** | Preenchido no App Store Connect |
| Age rating (questionário) | **NEEDS USER INPUT** | Preenchido no App Store Connect |
| Support URL | **MISSING — NEEDS USER INPUT** | Precisa de um canal de suporte real (e-mail ou página) |
| Marketing URL | **MISSING (opcional)** | Não obrigatório |
| Account deletion | **READY** — mesmo fluxo in-app já implementado; a Apple exige que exista, e existe | |
| Review notes | **MISSING** | Recomenda-se descrever o fluxo de convite/matchmaking pro revisor conseguir testar sem depender de outro usuário real |
| Sign-in demo (se o revisor não conseguir criar conta) | **NEEDS USER INPUT** | Recomenda-se fornecer credenciais de uma conta de teste já com time/squad prontos |
| TestFlight | **NOT EXECUTED — REQUIRES macOS** | Depende do archive existir primeiro |
| Archive/upload | **NOT EXECUTED — REQUIRES macOS** | Ver `release_checklist_ios.md` |

**Estimativa objetiva de completude App Store: ~25%** (menor que Android
porque, além dos mesmos gaps de texto/arte/domínio, o próprio pipeline
de build/archive nem pôde ser tentado neste ambiente).

## Dependência comum aos dois

Privacy Policy URL pública (hospedada, não só a tela dentro do app) é
exigida pelas duas lojas e ainda não existe — depende da mesma decisão
de domínio já pendente desde a Etapa 1 pros App/Universal Links. Vale
resolver as duas coisas juntas quando o domínio for decidido.
