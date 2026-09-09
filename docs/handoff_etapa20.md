# Handoff — Etapa 20 (Store Release Readiness / Device QA)

Status em 2026-09-09: **NOT READY — CONFIG BLOCKERS** (Android/iOS) e
**READY FOR PHYSICAL DEVICE QA** assim que o build rodar numa máquina
capaz. Zero bug de código nesta etapa. Detalhe completo em
`release_checklist_android.md`, `release_checklist_ios.md` e
`release_checklist_store_metadata.md` — este documento resume e aponta
pra eles.

## 1. Android — resumo (detalhe: `release_checklist_android.md`)

**Correção de status (pedido do dono do produto, após o fechamento
original desta etapa)**: a pergunta "está pronto para criar a release
key?" é diferente de "está pronto pra buildar nesta máquina?", que é
diferente de "está pronto pra Play Store?" — as três respostas não
podem ser resumidas numa única frase "NOT READY". Distinção oficial,
ver seção 9 de `release_checklist_android.md` para o detalhe completo:

- **READY TO CREATE RELEASE KEY: SIM** — zero blocker de código;
  `signingConfig` de release, a guarda contra assinatura silenciosa com
  chave de debug, e `key.properties.example` já existem. Gerar o
  keystore e digitar as senhas é uma etapa operacional do usuário, não
  um blocker de readiness.
- **Atualização 2026-09-09**: keystore real gerado, `android/
  key.properties` e `env/production.json` preenchidos, `storeFile`
  corrigido (estava com o path placeholder do template), e **AAB de
  release gerado com sucesso** — `build/app/outputs/bundle/release/
  app-release.aab` (~65 MB), assinado com a release key de verdade.
  Rodou no terminal do próprio usuário; nesta ferramenta de execução
  (sandboxed) o mesmo comando ainda bate no erro de loopback — a
  limitação é do processo que chama o Gradle, não da máquina Windows em
  si. `APP_LINK_HOST` também já tem valor real (`lucksrei.com`) —
  domínio decidido, desbloqueia Privacy Policy URL e App/Universal
  Links quando alguém for implementar (não feito nesta sessão).
- **READY TO BUILD RELEASE NESTA MÁQUINA: SIM, no terminal do usuário**
  (confirmado com artefato real). Nesta ferramenta de execução
  automatizada: ainda NÃO.
- **READY FOR STORE SUBMISSION: AINDA NÃO** — falta Device QA num
  aparelho físico com este AAB e o setup de metadata da Play Console.

- `flutter build apk --release` e `flutter build appbundle --release`
  tentados de verdade nesta sessão: **ambos falham com
  `java.io.IOException: Unable to establish loopback connection`** —
  classificado **ENVIRONMENT** (Gradle não consegue abrir loopback TCP
  nesta máquina Windows; ocorre antes até da checagem de
  `key.properties` do próprio projeto rodar).
- `android/key.properties`/keystore: **ausentes**, classificado
  **CONFIG** — template do que falta, sem valores reais, documentado.
- SDK/versionamento/ícone/splash/Firebase/`POST_NOTIFICATIONS`: todos
  **READY**, auditados por leitura de arquivo.
- App Links: pendência de domínio já conhecida desde a Etapa 1, não é
  achado novo.

## 2. Web — resumo

- `flutter build web --release`: **PASS**, compila limpo.
- Execução ao vivo no navegador de preview: **ENVIRONMENT LIMITATION**
  reconfirmada (mesma causa da Etapa 19 — o sandbox bloqueia a chamada
  de rede do `Supabase.initialize()` antes de `runApp()`). Não
  mascarado, não re-testado à exaustão porque a causa já está provada.
- Manifest, ícones, `base href`, ausência de Firebase Web push (decisão
  antiga): auditados por leitura de arquivo, sem achado novo.

## 3. iOS — resumo (detalhe: `release_checklist_ios.md`)

**NOT EXECUTED — REQUIRES macOS**, como esperado. Achado real: este
projeto **nunca teve um `pod install` rodado** (não existe `ios/Podfile`
no repo) — ou seja, nem o primeiro passo de abrir no Xcode foi feito
ainda em nenhuma sessão anterior. Checklist operacional de 10 passos
para quando houver um Mac, na ordem certa, já escrito no documento
dedicado.

## 4. Device QA Checklist (manual, pra rodar em Android físico e iPhone real)

Nenhum item abaixo foi executado nesta etapa (sem device físico neste
ambiente) — a lista existe pra ser seguida quando houver um aparelho.
Marcar cada linha ao executar de verdade; não marcar por inferência.

### Auth
- [ ] Criar conta nova
- [ ] Login
- [ ] Logout
- [ ] Relogin com a mesma conta
- [ ] Sessão continua válida depois de o app ficar em background por
      alguns minutos e voltar
- [ ] Excluir conta (fluxo completo, confirmar que a conta some de
      verdade)

### Time
- [ ] Criar time
- [ ] Gerar convite, compartilhar o link/código
- [ ] Entrar num time por convite
- [ ] Comportamento por papel (OWNER vê opções que PLAYER não vê)
- [ ] Saída/remoção de membro

### Squad
- [ ] Abrir o picker de jogador
- [ ] Buscar por nome
- [ ] Aplicar filtros (posição/liga/clube/rating)
- [ ] Selecionar uma carta
- [ ] Salvar o squad
- [ ] Fechar e reabrir o app — squad ainda está lá

### Matchmaking
- [ ] Entrar na fila
- [ ] Um segundo membro do time entra e fica na fila (FIFO)
- [ ] Promoção automática quando o primeiro reporta "Encontrei"
- [ ] Notificação "sua vez" chega de verdade
- [ ] Expiração da busca (esperar o tempo configurado)
- [ ] Sair da fila/busca manualmente
- [ ] Fila se comporta corretamente com o app indo pra background e
      voltando no meio da espera

### Notificações
- [ ] Prompt de permissão do sistema aparece na primeira vez
- [ ] Push chega de verdade com o app fechado
- [ ] Inbox mostra o mesmo evento
- [ ] Marcar como lida/não lida
- [ ] Abrir a notificação leva pro destino certo (deep link)
- [ ] Desligar uma categoria de push e confirmar que o evento ainda
      aparece na inbox (push OFF, inbox ON)

### Perfil público
- [ ] Ativar/compartilhar o perfil público
- [ ] Abrir o link como visitante (sem estar logado)
- [ ] Confirmar que nenhum dado privado (e-mail, etc.) aparece

### Visual
- [ ] Tema claro
- [ ] Tema escuro
- [ ] Idioma PT
- [ ] Idioma EN
- [ ] Idioma ES
- [ ] Teclado não cobre campo em foco
- [ ] Sem overflow de texto em nomes longos
- [ ] Scroll suave nas listas longas (histórico, picker)
- [ ] Bottom sheets/dialogs abrem e fecham corretamente
- [ ] Snackbars aparecem e desaparecem no tempo certo
- [ ] Loading/empty state/erro+retry aparecem quando esperado, nunca
      travados

**Status desta fase: checklist CRIADO, execução INCOMPLETE** (0 de N
itens marcados — nenhum device físico disponível neste ambiente).

## 5. Store metadata — resumo (detalhe: `release_checklist_store_metadata.md`)

- Google Play: **~35% pronto** — o que é config de app está feito
  (ícone, exclusão de conta, declaração de ads); falta texto/arte/
  decisão humana e o AAB assinado.
- App Store: **~25% pronto** — mesmos gaps de texto/arte, mais o
  próprio pipeline de build/archive nem pôde ser tentado (precisa de
  Mac).
- Bloqueio comum às duas lojas: **Privacy Policy precisa de uma URL
  pública hospedada** (não só a tela dentro do app) — depende da mesma
  decisão de domínio pendente desde a Etapa 1.

## 6. Segurança (reconferência de release)

- Nenhuma secret commitada — reconfirmado (`git grep` por padrões de
  chave, nada encontrado; `env/*.json` exceto `.example.json`,
  `firebase_options.dart`, `google-services.json`,
  `GoogleService-Info.plist`, `key.properties`, `*.keystore` todos
  ausentes do índice do git).
- Nenhuma service role key no cliente Flutter — o app só usa a
  `publishable key` (anon); a secret key só existe em `Platform.environment`
  do script `tool/sync_fc_cards.dart`, nunca embutida em código versionado.
- Config de debug não presente em build de release: `signingConfigs`
  cai pra debug key só se `key.properties` não existir, e o
  `gradle.taskGraph.whenReady` **bloqueia** a build de release nesse
  caso — não deixa vazar silenciosamente.
- RLS: inalterada, sem achado novo desde a Etapa 19.
- Endpoints privilegiados: todas as escritas continuam atrás de RPC
  `security definer` com `auth.uid()` — nenhum insert direto do cliente
  em tabela sensível.
- Exclusão de conta: Edge Function `delete-account` (v1, ACTIVE),
  inalterada.
- Privacy/Terms/About + disclaimer de não afiliação com a EA: existem
  (`legal_content_pt.dart`, `about_page.dart`), confirmados por leitura
  de código.
- Nenhum log sensível impresso nesta sessão (só checagem de
  presença/ausência de variável de ambiente, nunca valor).

## 7. Testes / infra finais

- `flutter test`: 6/6 verde.
- `flutter analyze`: **No issues found**.
- Migrations: 76 locais = 76 remotas.
- `git status`: limpo (só os documentos desta etapa).

## Entrega final

1. **HEAD antes/depois**: `d096606` → (commit desta etapa, sem push)
2. **Android release build**: **FAIL** (ENVIRONMENT — Gradle/loopback)
3. **AAB**: **FAIL** (ENVIRONMENT — mesma causa)
4. **Web release**: **PARTIAL** — build PASS, execução ao vivo
   ENVIRONMENT LIMITATION
5. **iOS static readiness**: **PARTIAL** — config existente correta,
   nunca houve `pod install`, capabilities de push ainda não criadas
6. **Device QA checklist**: **COMPLETE (criado)**, execução
   **INCOMPLETE** (sem device físico)
7. **Google Play readiness**: **~35%**
8. **App Store readiness**: **~25%**
9. **Missing user inputs**: nome final de listagem, descrições,
   categoria, screenshots, arte de banner, domínio (pra Privacy Policy
   URL e App/Universal Links), support URL, conta de revisor
10. **Missing credentials**: keystore Android + `key.properties`, conta
    Apple Developer/Team, provisioning/signing de distribuição iOS
11. **Blockers de ambiente**: Gradle não builda nesta máquina Windows;
    execução visual Web bloqueada pelo sandbox de rede do navegador de preview;
    iOS exige macOS
12. **Blockers de código**: **nenhum**
13. **Blockers de configuração**: keystore Android ausente; iOS nunca
    teve `pod install`/capabilities configuradas; domínio pra Privacy
    Policy/App Links não decidido
14. **Segurança**: PASS
15. **`flutter test`**: 6/6
16. **`flutter analyze`**: limpo
17. **Migrations**: 76/76
18. **`git status`**: limpo

## Veredito

**NOT READY — CONFIG BLOCKERS.**

Não há bug de código nem bloqueio de arquitetura. O que falta é 100%
config/credencial (keystore Android, setup de Xcode, domínio, textos de
loja) e ambiente de execução (Mac pra iOS, uma máquina onde o Gradle
funcione pra Android, um device físico pra QA visual). Assim que o
Android buildar numa máquina capaz (mesmo sem keystore, um build de
debug já bastaria pra QA visual) ou um iPhone/Android físico estiver
disponível, o projeto está pronto pra entrar na fase de **Device QA**
— não precisa de mais nenhuma mudança de código para chegar lá.
