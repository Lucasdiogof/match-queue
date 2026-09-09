# Changelog

Histórico de funcionalidades do app, da mais recente pra mais antiga. Auditorias
internas, scripts de importação de dados e sessões só de validação não entram
aqui — só o que muda a experiência de usar o app.

## 2026-09-09

- **Squad Builder**: o catálogo real completo de cartas está no ar — 17.873
  jogadores e cartas reais (futebol masculino e feminino), substituindo a
  amostra pequena de desenvolvimento.

## 2026-09-08

- **Notificações**: nova Central de Notificações (sino com badge de não
  lidas, inbox com lida/não lida, paginação) além do push. Preferências
  agora agrupadas por categoria (Matchmaking, Times, Weekend League, Rivals,
  Rankings) em vez de um toggle por alerta.
- **Perfil**: perfil público opt-in com link compartilhável, mostrando sua
  escalação principal e estatísticas esportivas pra quem tiver o link.
- **Time**: recorde esportivo, ranking e artilharia/assistências de todo o
  time, num só painel.
- **Partidas**: gols e assistências por jogador, resultado editável (sem
  limite de tempo), e uma tela dedicada de detalhes da partida.
- **Contas (Elenco)**: páginas de detalhe de Weekend League e Rivals por
  conta, com sobrescrita manual do recorde quando necessário.
- **Squad Builder**: overall e química calculados automaticamente, com
  arrastar-e-soltar, banco de reservas, e explicação de por que cada titular
  tem a química que tem.
- **Jogar**: card de partida pendente, seletor de modo de jogo, e uma linha
  do tempo combinando histórico de busca e de partidas.
- Renomeado "Elenco" para "Conta" em todo o app, pra clareza.
- Uma busca agora cobre todos os times aos quais a conta está vinculada, em
  vez de exigir uma busca separada por time.
- **Time**: dividido em lista de times e tela de detalhe por time, com
  perfis individuais de jogador.
- Notificações push agora usam tokens reais de dispositivo do Firebase.
- **Conta**: exclusão de conta, e páginas públicas de Política de
  Privacidade / Termos de Uso / Sobre.
- Assinatura de release de produção do Android configurada.

## 2026-09-07

- Primeira versão do app: projeto Flutter pra Android, iOS e Web com o
  design system e a marca do FIFA Queue.
- Autenticação real (criar conta, entrar, redefinir senha) via Supabase.
- **Time**: criar um time, convidar outras pessoas por link/código
  compartilhável, trocar entre times.
- **Buscar** (matchmaking): só uma pessoa busca por vez em cada time, o
  resto espera numa fila que avança sozinha e atualiza em tempo real — sem
  precisar mais atualizar manualmente.
