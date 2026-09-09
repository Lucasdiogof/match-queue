# Device QA — Android (checklist manual)

Pra rodar com o AAB/APK de release real instalado num aparelho Android
físico. Nada aqui foi executado ainda — nenhum device físico esteve
disponível neste ambiente. Marcar cada linha só depois de testar de
verdade, nunca por inferência.

Instalar o release real (não `flutter run`, que usa debug):
```bash
flutter build apk --release --dart-define-from-file=env/production.json
adb install build/app/outputs/flutter-apk/app-release.apk
```
(AAB não instala direto via `adb` — usar o APK release equivalente pra
teste manual; o AAB é só o formato de upload pra Play Store.)

## Auth
- [ ] Criar conta nova
- [ ] Login
- [ ] Logout
- [ ] Relogin com a mesma conta
- [ ] Sessão continua válida depois do app em background por alguns minutos
- [ ] Recuperação de senha (e-mail → link → troca de senha → volta pro app)
- [ ] Excluir conta (fluxo completo, confirmar que a conta some de verdade)

## Times / Convites
- [ ] Criar time
- [ ] Gerar convite (link/código)
- [ ] Entrar num time por convite
- [ ] Comportamento por papel (OWNER vê o que PLAYER não vê)
- [ ] Sair do time / remover membro

## Squad Builder
- [ ] Abrir o picker de jogador
- [ ] Buscar por nome
- [ ] Aplicar filtros (posição/liga/clube/rating)
- [ ] Selecionar/trocar/remover carta
- [ ] Salvar o squad
- [ ] Fechar e reabrir o app — squad persistiu

## Matchmaking / Realtime
- [ ] Entrar na fila
- [ ] Segundo membro do time entra e fica na fila (FIFO)
- [ ] Promoção automática ao reportar "Encontrei"
- [ ] Fila atualiza em tempo real sem precisar puxar pra atualizar
- [ ] Comportamento com o app indo pra background e voltando no meio
      da espera
- [ ] Reconexão depois de perder e recuperar conexão de rede

## Push / Notificações
- [ ] Prompt de permissão do sistema aparece na primeira vez
- [ ] Push chega de verdade com o app fechado
- [ ] Inbox mostra o mesmo evento do push
- [ ] Marcar notificação como lida/não lida
- [ ] Tocar na notificação leva pro destino certo (deep link)
- [ ] Desligar uma categoria de push e confirmar que o evento ainda
      aparece na inbox (push OFF, inbox ON)

## Deep links
- [ ] Abrir o link de convite de time (o que existe hoje é custom
      scheme/origin, não App Links ainda — ver `docs/deep_links.md`)
- [ ] Abrir o link de perfil público

## Perfil público
- [ ] Ativar/compartilhar o perfil público
- [ ] Abrir o link como visitante (sem estar logado)
- [ ] Confirmar que nenhum dado privado aparece (e-mail, etc.)

## Visual
- [ ] Tema claro
- [ ] Tema escuro
- [ ] Idioma PT
- [ ] Idioma EN
- [ ] Idioma ES
- [ ] Teclado não cobre campo em foco
- [ ] Sem overflow de texto em nomes longos
- [ ] Scroll suave em listas longas (histórico, picker)
- [ ] Bottom sheets/dialogs abrem e fecham corretamente
- [ ] Snackbars aparecem e desaparecem no tempo certo
- [ ] Loading/empty state/erro+retry aparecem quando esperado, nunca
      travados

## Status

**Checklist CRIADO. Execução INCOMPLETE** — 0 de N itens marcados,
nenhum device físico disponível neste ambiente. Pronto para ser seguido
assim que houver um aparelho Android real com o APK/AAB de release
instalado.
