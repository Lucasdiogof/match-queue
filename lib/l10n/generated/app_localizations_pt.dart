// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'FIFA Queue';

  @override
  String get appTagline => 'Um de cada vez na fila.';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionRetry => 'Tentar novamente';

  @override
  String get actionClose => 'Fechar';

  @override
  String get actionSave => 'Salvar';

  @override
  String get actionCopy => 'Copiar';

  @override
  String get actionShare => 'Compartilhar';

  @override
  String get actionBack => 'Voltar';

  @override
  String get actionNotNow => 'Agora não';

  @override
  String get actionSignOut => 'Sair';

  @override
  String get actionEdit => 'Editar';

  @override
  String get navHome => 'Início';

  @override
  String get navControl => 'Controle';

  @override
  String get navTeam => 'Times';

  @override
  String get navHistory => 'Histórico';

  @override
  String get navProfile => 'Perfil';

  @override
  String get comingSoonTitle => 'Em construção';

  @override
  String get comingSoonMessage =>
      'Esta área será construída nas próximas etapas do projeto.';

  @override
  String get comingSoonNextStage => 'Etapa 3';

  @override
  String get startEyebrow => 'FIFA QUEUE';

  @override
  String get startTitle => 'Visão geral';

  @override
  String get startSubtitle => 'Seu time e sua semana em um lugar.';

  @override
  String get startShortcutsTitle => 'Atalhos';

  @override
  String get controlEyebrow => 'CONTROLE';

  @override
  String get controlTitle => 'Seu jogo começa aqui';

  @override
  String get controlSubtitle => 'Fila, adversário e squad em um só lugar.';

  @override
  String get controlDiscoverCardsTitle => 'Explorar cartas';

  @override
  String get controlDiscoverCardsSubtitle =>
      'Jogadores em destaque no catálogo completo.';

  @override
  String get controlDiscoverClubsTitle => 'Clubes';

  @override
  String get controlDiscoverClubsSubtitle =>
      'Explore os clubes do catálogo FC27.';

  @override
  String get controlEmptyTitle => 'Pronto pra entrar em campo?';

  @override
  String get controlEmptyMessage =>
      'Escolha uma conta e um modo pra começar a buscar partida.';

  @override
  String get teamTitle => 'Meu time';

  @override
  String get teamSubtitle => 'Jogadores, cargos e convites.';

  @override
  String get teamsEyebrow => 'TIMES';

  @override
  String get teamsListSubtitle => 'Seus times e status operacional.';

  @override
  String get teamsMineTab => 'Meus Times';

  @override
  String get teamsExploreTab => 'Explorar';

  @override
  String get teamsExploreEmptyTitle => 'Nenhum time público ainda';

  @override
  String get teamsExploreEmptyMessage =>
      'Times públicos aparecem aqui quando existirem.';

  @override
  String get teamVisibilitySectionTitle => 'Visibilidade';

  @override
  String get teamVisibilityPublic => 'Público';

  @override
  String get teamVisibilityPrivate => 'Privado';

  @override
  String get teamVisibilityPublicHint =>
      'Aparece em Explorar e tem página pública.';

  @override
  String get teamVisibilityPrivateHint =>
      'Não aparece em Explorar nem em buscas públicas.';

  @override
  String get teamPublicPageMembersTitle => 'Elenco';

  @override
  String get teamPublicPageRecordTitle => 'Retrospecto';

  @override
  String teamPublicPageRecordLine(int wins, int losses) {
    return '$wins vitórias • $losses derrotas';
  }

  @override
  String get teamPublicPageNotFoundTitle => 'Time não encontrado';

  @override
  String get teamPublicPageNotFoundMessage =>
      'Este time não existe ou não está disponível publicamente.';

  @override
  String get historyEyebrow => 'HISTÓRICO';

  @override
  String get historyTitle => 'Histórico';

  @override
  String get historySubtitle => 'Buscas, partidas encontradas e expirações.';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileSubtitle => 'Conta, aparência e idioma.';

  @override
  String get authSignIn => 'Entrar';

  @override
  String get authSignUp => 'Criar conta';

  @override
  String get authForgotPassword => 'Esqueci minha senha';

  @override
  String get authEmail => 'E-mail';

  @override
  String get authPassword => 'Senha';

  @override
  String get authRevealPassword => 'Mostrar senha';

  @override
  String get authHidePassword => 'Ocultar senha';

  @override
  String authSignedInAs(String email) {
    return 'Conectado como $email';
  }

  @override
  String get profilePreferencesTitle => 'Preferências';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get languageSystem => 'Idioma do dispositivo';

  @override
  String get languagePortuguese => 'Português (Brasil)';

  @override
  String get languageEnglish => 'Inglês';

  @override
  String get languageSpanish => 'Espanhol';

  @override
  String get inviteJoinTeam => 'Entrar no time';

  @override
  String get inviteOpenTeam => 'Abrir time';

  @override
  String get inviteJoinMessage => 'Você foi convidado para entrar neste time.';

  @override
  String get inviteAlreadyMemberMessage => 'Você já faz parte deste time.';

  @override
  String get inviteSignInToAccept => 'Entrar para aceitar';

  @override
  String get inviteCreateAccount => 'Criar conta';

  @override
  String get inviteInvalidTitle => 'Convite não encontrado';

  @override
  String get inviteRevokedTitle => 'Este link não está mais ativo';

  @override
  String get inviteExpiredTitle => 'Este link expirou';

  @override
  String get inviteExhaustedTitle => 'Este link atingiu o limite de usos';

  @override
  String get inviteEnterCodeMessage =>
      'Cole ou digite o código que você recebeu.';

  @override
  String get inviteCodeFieldLabel => 'Código do convite';

  @override
  String get inviteCodeFieldInvalid => 'Código inválido.';

  @override
  String get inviteSectionTitle => 'Convidar jogadores';

  @override
  String get inviteSectionSubtitle =>
      'Compartilhe este link com quem você quer adicionar ao time.';

  @override
  String get inviteLinkCopied => 'Link copiado.';

  @override
  String get inviteShareSubject => 'Convite para o time no FIFA Queue';

  @override
  String inviteShareMessage(String url) {
    return 'Entre no meu time pelo FIFA Queue: $url';
  }

  @override
  String inviteShareMessageCodeOnly(String code) {
    return 'Entre no meu time pelo FIFA Queue com o código: $code';
  }

  @override
  String get inviteManageTitle => 'Gerenciar link';

  @override
  String get inviteCreateLinkAction => 'Criar link de convite';

  @override
  String get inviteUnavailableMessage =>
      'O link de convite deste time ainda não está disponível.';

  @override
  String get inviteRotateAction => 'Gerar novo link';

  @override
  String get inviteRotateConfirmTitle => 'Gerar um novo link?';

  @override
  String get inviteRotateConfirmMessage =>
      'O link atual deixará de funcionar imediatamente.';

  @override
  String get inviteRevokeAction => 'Desativar link';

  @override
  String get inviteRevokeConfirmTitle => 'Desativar link?';

  @override
  String get inviteRevokeConfirmMessage =>
      'Ninguém poderá entrar no time usando o link atual.';

  @override
  String queuePositionLabel(int position) {
    final intl.NumberFormat positionNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String positionString = positionNumberFormat.format(position);

    return '#$positionString na fila';
  }

  @override
  String get errorNetwork =>
      'Sem conexão. Verifique sua internet e tente novamente.';

  @override
  String get errorTimeout => 'A operação demorou demais. Tente novamente.';

  @override
  String get errorServer =>
      'Algo deu errado no servidor. Tente novamente em instantes.';

  @override
  String get errorPermission => 'Você não tem permissão para fazer isso.';

  @override
  String get errorNotFound => 'Não encontramos o que você procurava.';

  @override
  String get errorConflict =>
      'Esta ação conflita com o estado atual. Atualize e tente de novo.';

  @override
  String get errorUnexpected => 'Erro inesperado. Tente novamente.';

  @override
  String errorConfiguration(String keys) {
    return 'Configuração ausente: $keys';
  }

  @override
  String get errorInvalidCredentials => 'E-mail ou senha incorretos.';

  @override
  String get errorEmailAlreadyRegistered => 'Este e-mail já está cadastrado.';

  @override
  String get errorWeakPassword => 'Escolha uma senha mais forte.';

  @override
  String get errorUserNotFound => 'Conta não encontrada.';

  @override
  String get errorSessionExpired => 'Sua sessão expirou. Entre novamente.';

  @override
  String get errorEmailConfirmationRequired =>
      'Enviamos um link de confirmação para o seu e-mail. Confirme o endereço para entrar.';

  @override
  String get errorAuthUnknown => 'Não foi possível concluir a autenticação.';

  @override
  String get startupErrorTitle => 'Não foi possível iniciar o FIFA Queue';

  @override
  String startupErrorMessage(String keys) {
    return 'Faltam variáveis de ambiente obrigatórias: $keys';
  }

  @override
  String environmentBadge(String environment) {
    return 'Ambiente: $environment';
  }

  @override
  String get notFoundTitle => 'Página não encontrada';

  @override
  String get notFoundMessage =>
      'O endereço acessado não existe neste aplicativo.';

  @override
  String get notFoundAction => 'Ir para o início';

  @override
  String get loginTitle => 'Entre na sua conta';

  @override
  String get loginNoAccount => 'Ainda não tem uma conta?';

  @override
  String get signUpTitle => 'Crie sua conta';

  @override
  String get signUpSubtitle => 'Escolha como o seu time vai te chamar.';

  @override
  String get signUpHaveAccount => 'Já tem uma conta?';

  @override
  String get authDisplayName => 'Nome ou apelido';

  @override
  String get authDisplayNameHint => 'Lucas, ratowrld, Panda...';

  @override
  String get authEmailHint => 'voce@exemplo.com';

  @override
  String get authConfirmPassword => 'Confirmar senha';

  @override
  String authPasswordHelper(int count) {
    return 'Mínimo de $count caracteres';
  }

  @override
  String get forgotPasswordTitle => 'Recuperar acesso';

  @override
  String get forgotPasswordMessage =>
      'Informe o e-mail da sua conta e enviaremos o link para criar uma nova senha.';

  @override
  String get forgotPasswordAction => 'Enviar instruções';

  @override
  String get forgotPasswordSentTitle => 'Confira seu e-mail';

  @override
  String get forgotPasswordSentMessage =>
      'Se houver uma conta associada a este e-mail, você vai receber as instruções para redefinir a senha.';

  @override
  String get forgotPasswordBackToLogin => 'Voltar para o login';

  @override
  String get forgotPasswordResend => 'Reenviar';

  @override
  String get forgotPasswordNotReceived => 'Não recebeu o e-mail?';

  @override
  String get forgotPasswordResending => 'Reenviando...';

  @override
  String get forgotPasswordResendSuccess => 'E-mail reenviado.';

  @override
  String get resetPasswordTitle => 'Definir nova senha';

  @override
  String get resetPasswordMessage =>
      'Escolha uma nova senha para voltar a usar o FIFA Queue.';

  @override
  String get resetPasswordNewPassword => 'Nova senha';

  @override
  String get resetPasswordAction => 'Salvar nova senha';

  @override
  String get resetPasswordSuccess => 'Senha atualizada. Bem-vindo de volta.';

  @override
  String get resetPasswordInvalidTitle => 'Link expirado ou inválido';

  @override
  String get resetPasswordInvalidMessage =>
      'Peça um novo link de recuperação para definir sua senha.';

  @override
  String get validationEmailRequired => 'Informe seu e-mail.';

  @override
  String get validationEmailInvalid => 'Informe um e-mail válido.';

  @override
  String get validationPasswordRequired => 'Informe sua senha.';

  @override
  String validationPasswordTooShort(int count) {
    return 'A senha precisa ter pelo menos $count caracteres.';
  }

  @override
  String get validationPasswordConfirmationRequired => 'Confirme sua senha.';

  @override
  String get validationPasswordConfirmationMismatch =>
      'As senhas não coincidem.';

  @override
  String get validationDisplayNameRequired => 'Informe um nome ou apelido.';

  @override
  String validationDisplayNameTooShort(int count) {
    return 'Use pelo menos $count caracteres.';
  }

  @override
  String validationDisplayNameTooLong(int count) {
    return 'Use no máximo $count caracteres.';
  }

  @override
  String get errorTooManyRequests =>
      'Muitas tentativas. Espere um instante e tente de novo.';

  @override
  String get errorSignUpFailed => 'Não foi possível criar sua conta.';

  @override
  String homeGreeting(String name) {
    return 'Olá, $name';
  }

  @override
  String get homeSearchPlaceholderTitle =>
      'A busca coordenada chega na Etapa 3';

  @override
  String get homeSearchPlaceholderMessage =>
      'Primeiro vamos criar times e membros. Depois disso, só um jogador do time procura partida por vez.';

  @override
  String get profileAccountSection => 'Conta';

  @override
  String get profileDisplayNameLabel => 'Nome ou apelido';

  @override
  String get profileEmailLabel => 'E-mail';

  @override
  String get profileEditName => 'Editar nome';

  @override
  String get profileEditNameTitle => 'Como podemos te chamar?';

  @override
  String profileDisplayNameCounter(int count, int max) {
    return '$count/$max';
  }

  @override
  String get profileSaved => 'Nome atualizado.';

  @override
  String get profileLoadErrorTitle => 'Não foi possível carregar seu perfil';

  @override
  String profileMemberSince(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMM(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'No FIFA Queue desde $dateString';
  }

  @override
  String get teamNoTeamTitle => 'Você ainda não faz parte de um time';

  @override
  String get teamNoTeamMessage =>
      'Crie o seu time ou entre com um código de convite para começar.';

  @override
  String get historyNoTeamMessage =>
      'Sem time não há histórico pra mostrar. Crie o seu ou entre com um código de convite para começar a registrar buscas e partidas.';

  @override
  String get teamCreateCta => 'Criar time';

  @override
  String get teamHaveInviteCode => 'Tenho um código de convite';

  @override
  String get teamCreateTitle => 'Crie seu time';

  @override
  String get teamCreateSubtitle =>
      'Dá para ajustar cores, logo e duração da busca depois.';

  @override
  String get teamCreateFcAccountsSectionTitle =>
      'Quais Contas FC fazem parte deste time?';

  @override
  String get teamNameLabel => 'Nome do time';

  @override
  String get teamNameHint => 'Falcons FC';

  @override
  String get teamTagLabel => 'Tag (opcional)';

  @override
  String get teamTagHint => 'FLC';

  @override
  String get teamTagHelper => '2 a 6 letras ou números';

  @override
  String get teamCreateAction => 'Criar time';

  @override
  String get teamCreateAnother => 'Criar outro time';

  @override
  String get teamMembersTitle => 'Membros';

  @override
  String get teamsListEmptyMessage => 'Você ainda não faz parte de um time.';

  @override
  String get teamDetailPlayersTitle => 'Jogadores';

  @override
  String get playerProfileTitle => 'Perfil do jogador';

  @override
  String get playerProfileAccountLabel => 'Conta';

  @override
  String get playerProfileNoAccountMessage =>
      'Este jogador não tem uma conta vinculada a este time.';

  @override
  String get playerProfileSquadLabel => 'Escalação principal';

  @override
  String get playerProfileSquadNoneMessage => 'Ainda sem escalação montada.';

  @override
  String playerProfileCompletenessLabel(int count, int total) {
    return '$count/$total titulares';
  }

  @override
  String get playerProfileSelectAccountTitle =>
      'Este jogador tem mais de uma conta neste time';

  @override
  String get playerProfileWeekendLeagueEmptyMessage =>
      'Nenhum evento de Weekend League registrado.';

  @override
  String playerProfileWeekendLeagueRecordLabel(int wins, int losses) {
    return '${wins}V–${losses}D';
  }

  @override
  String teamMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogadores',
      one: '1 jogador',
      zero: 'Nenhum jogador',
    );
    return '$_temp0';
  }

  @override
  String get teamRoleOwner => 'Dono';

  @override
  String get teamRoleAdmin => 'Admin';

  @override
  String get teamRolePlayer => 'Jogador';

  @override
  String get teamYou => 'Você';

  @override
  String get teamManageAction => 'Configurações do time';

  @override
  String get teamEditTitle => 'Editar time';

  @override
  String get teamSwitchTitle => 'Seus times';

  @override
  String get teamSwitchAction => 'Trocar de time';

  @override
  String teamActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ativos',
      one: '1 ativo',
      zero: '0 ativos',
    );
    return '$_temp0';
  }

  @override
  String get teamSettingsInfoTitle => 'Informações';

  @override
  String get teamSearchDurationLabel => 'Duração padrão da busca';

  @override
  String get teamSearchDurationHelper =>
      'Tempo que cada jogador fica na frente da fila.';

  @override
  String get teamSearchDurationReadOnlyHelper =>
      'Só o dono ou um admin pode alterar.';

  @override
  String get teamStatusInMatch => 'Em jogo';

  @override
  String get teamStatusSearching => 'Buscando';

  @override
  String get teamStatusQueued => 'Na fila';

  @override
  String teamStatusQueuedWithPosition(int position) {
    return 'Na fila · #$position';
  }

  @override
  String get teamStatusOffline => 'Offline';

  @override
  String get teamStatusActiveNow => 'Ativo agora';

  @override
  String teamStatusActiveMinutesAgo(int minutes) {
    return 'Há $minutes min';
  }

  @override
  String teamDurationSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String teamDurationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min',
      one: '1 min',
    );
    return '$_temp0';
  }

  @override
  String get teamLoadErrorTitle => 'Não foi possível carregar seus times';

  @override
  String get teamMembersErrorTitle => 'Não foi possível carregar os membros';

  @override
  String get validationTeamNameRequired => 'Informe o nome do time.';

  @override
  String validationTeamNameTooShort(int count) {
    return 'Use pelo menos $count caracteres.';
  }

  @override
  String validationTeamNameTooLong(int count) {
    return 'Use no máximo $count caracteres.';
  }

  @override
  String validationTeamTagTooShort(int count) {
    return 'A tag precisa ter pelo menos $count caracteres.';
  }

  @override
  String validationTeamTagTooLong(int count) {
    return 'A tag pode ter no máximo $count caracteres.';
  }

  @override
  String get validationTeamTagInvalid => 'Use apenas letras e números.';

  @override
  String get errorTeamNameInvalid => 'Escolha um nome de time válido.';

  @override
  String get errorTeamTagInvalid => 'Escolha uma tag válida.';

  @override
  String get errorTeamSearchDurationInvalid =>
      'Escolha uma duração de busca válida.';

  @override
  String get errorTeamNotFound => 'Time não encontrado.';

  @override
  String get errorTeamPermissionDenied =>
      'Você não tem permissão para gerenciar este time.';

  @override
  String get errorTeamProfileMissing =>
      'Finalize seu perfil antes de criar um time.';

  @override
  String get errorInviteNotFound => 'Convite não encontrado.';

  @override
  String get errorInviteNotActive => 'Este convite não é mais válido.';

  @override
  String get errorInviteExpired => 'Este convite expirou.';

  @override
  String get errorInviteExhausted => 'Este convite atingiu o limite de usos.';

  @override
  String get errorInviteGenerationFailed =>
      'Não foi possível gerar o link de convite. Tente novamente.';

  @override
  String get errorInvitePermissionDenied =>
      'Você não tem permissão para gerenciar o convite deste time.';

  @override
  String get errorMatchmakingNoActiveSearch => 'Não há busca ativa no momento.';

  @override
  String get errorMatchmakingNotCurrentSearcher =>
      'Você não é mais quem está buscando partida.';

  @override
  String get errorMatchmakingAlreadyInOtherState =>
      'Você já está em outro estado da fila.';

  @override
  String get errorMatchmakingTeamInactive =>
      'Este time está inativo no momento.';

  @override
  String get errorGameCooldown => 'Espere um pouco antes de buscar de novo.';

  @override
  String get errorGameMatchNotFound => 'Partida não encontrada.';

  @override
  String get errorGameMatchAlreadyFinished => 'Esta partida já foi finalizada.';

  @override
  String get errorGameInvalidMode => 'Modo de jogo inválido.';

  @override
  String get errorGameInvalidResult =>
      'Informe um resultado ou um placar sem empate.';

  @override
  String get matchmakingIdleTitle => 'Ninguém está buscando partida';

  @override
  String get matchmakingIdleMessage =>
      'Toque em buscar partida para começar. O time inteiro vê assim que alguém entra na fila.';

  @override
  String get matchmakingSearchAction => 'Buscar partida';

  @override
  String get matchmakingJoinQueueAction => 'Entrar na fila';

  @override
  String get matchmakingCancelAction => 'Cancelar';

  @override
  String get matchmakingLeaveQueueAction => 'Sair da fila';

  @override
  String get matchmakingMatchFoundAction => 'Encontrei';

  @override
  String get matchmakingSearchingSelfTitle => 'Buscando partida';

  @override
  String get matchmakingSearchingSelfMessage =>
      'Assim que a partida começar, toque em partida encontrada.';

  @override
  String matchmakingSearchingOtherTitle(String name) {
    return '$name está buscando partida';
  }

  @override
  String matchmakingQueuePositionLabel(int position) {
    return 'Posição $position na fila';
  }

  @override
  String get matchmakingQueueSectionTitle => 'Fila de espera';

  @override
  String get matchmakingQueueEmptyMessage => 'Ninguém na fila.';

  @override
  String get matchmakingYouBadge => 'Você';

  @override
  String get matchmakingCancelConfirmTitle => 'Cancelar busca?';

  @override
  String get matchmakingCancelConfirmMessage =>
      'Você vai perder sua posição na busca atual.';

  @override
  String get matchmakingYourTurnTitle => 'Sua vez de buscar!';

  @override
  String get matchmakingReconnecting => 'Reconectando…';

  @override
  String get notificationsSectionTitle => 'Notificações';

  @override
  String get notificationsToggleYourTurn => 'Sua vez de buscar';

  @override
  String get notificationsToggleYourTurnHint =>
      'Quando chegar a sua vez na fila do time.';

  @override
  String get notificationsToggleExpiring => '30 segundos restantes';

  @override
  String get notificationsToggleExpiringHint =>
      'Um aviso antes de a sua busca expirar.';

  @override
  String get notificationsToggleExpired => 'Tempo de busca encerrado';

  @override
  String get notificationsToggleExpiredHint =>
      'Quando a sua busca termina sem partida.';

  @override
  String get notificationsEnableCta => 'Ativar notificações';

  @override
  String get notificationsPermissionDeniedHint =>
      'As notificações estão bloqueadas. Ative-as nas configurações do sistema.';

  @override
  String get notificationsUnsupportedHint =>
      'Este dispositivo ainda não recebe notificações push.';

  @override
  String get notificationsEnableTitle => 'Não perca a sua vez';

  @override
  String get notificationsEnableMessage =>
      'Ative as notificações para saber na hora quando for a sua vez de buscar partida — mesmo com o app fechado.';

  @override
  String get notificationsChannelQueueAlertsName => 'Alertas da fila';

  @override
  String get notificationsChannelQueueAlertsDescription =>
      'Avisos sobre a sua vez de buscar e o andamento da sua busca.';

  @override
  String get notificationsChannelAppUpdatesName => 'Atualizações do time';

  @override
  String get notificationsChannelAppUpdatesDescription =>
      'Novos membros, ranking, Weekend League e Rivals.';

  @override
  String get notificationsCategoryMatchmaking => 'Matchmaking';

  @override
  String get notificationsCategoryMatchmakingHint =>
      'Sua vez, avisos de expiração da busca.';

  @override
  String get notificationsCategoryTeams => 'Times';

  @override
  String get notificationsCategoryTeamsHint => 'Novos membros no time.';

  @override
  String get notificationsCategoryWeekendLeague => 'Weekend League';

  @override
  String get notificationsCategoryWeekendLeagueHint =>
      'Quando um evento de fim de semana termina.';

  @override
  String get notificationsCategoryRivals => 'Rivals';

  @override
  String get notificationsCategoryRivalsHint =>
      'Mudança de divisão de uma conta do time.';

  @override
  String get notificationsCategoryRankings => 'Rankings';

  @override
  String get notificationsCategoryRankingsHint =>
      'Novo líder, artilheiro ou garçom do time.';

  @override
  String get notificationsInboxTitle => 'Notificações';

  @override
  String get notificationsInboxMarkAllRead => 'Marcar tudo como lido';

  @override
  String get notificationsInboxEmptyTitle => 'Você ainda não tem notificações';

  @override
  String get notificationsInboxEmptyMessage =>
      'Avisos do time, do ranking e das suas buscas aparecem aqui.';

  @override
  String get notificationsInboxErrorMessage =>
      'Não deu para carregar suas notificações.';

  @override
  String get notificationsInboxRetry => 'Tentar de novo';

  @override
  String get notificationsGroupToday => 'Hoje';

  @override
  String get notificationsGroupYesterday => 'Ontem';

  @override
  String get notificationsGroupEarlier => 'Anteriores';

  @override
  String notificationTeamMemberJoined(String displayName, String teamName) {
    return '$displayName entrou em $teamName.';
  }

  @override
  String notificationTeamLeaderChanged(String leaderDisplayName) {
    return '$leaderDisplayName assumiu a liderança do ranking do time.';
  }

  @override
  String get notificationYouAreTeamLeader =>
      'Você assumiu a liderança do ranking do time!';

  @override
  String notificationTeamTopScorerChanged(
    String playerName,
    String displayName,
  ) {
    return '$playerName ($displayName) é o novo artilheiro do time.';
  }

  @override
  String notificationTeamTopAssistChanged(
    String playerName,
    String displayName,
  ) {
    return '$playerName ($displayName) lidera as assistências do time.';
  }

  @override
  String notificationWeekendLeagueFinished(
    String displayName,
    int wins,
    int losses,
  ) {
    return '$displayName terminou a Weekend League em $wins-$losses.';
  }

  @override
  String notificationRivalsDivisionChanged(
    String displayName,
    String division,
  ) {
    return '$displayName chegou à $division no Rivals.';
  }

  @override
  String get historyTabMatches => 'Partidas';

  @override
  String get historyTabStats => 'Estatísticas';

  @override
  String get historyPeriodAll => 'Sempre';

  @override
  String get historyPeriod7 => '7 dias';

  @override
  String get historyPeriod30 => '30 dias';

  @override
  String get historyPeriod90 => '90 dias';

  @override
  String get historyStatusAll => 'Todas';

  @override
  String get historyStatusMatchFound => 'Encontradas';

  @override
  String get historyStatusCancelled => 'Canceladas';

  @override
  String get historyStatusExpired => 'Expiradas';

  @override
  String get historyStatusMatchFoundLabel => 'Partida encontrada';

  @override
  String get historyStatusCancelledLabel => 'Cancelada';

  @override
  String get historyStatusExpiredLabel => 'Expirada';

  @override
  String get historyEmptyTitle => 'Nenhuma busca ainda';

  @override
  String get historyEmptyMessage =>
      'As buscas de partida do time aparecem aqui quando terminam.';

  @override
  String get activityScopeAll => 'Tudo';

  @override
  String get activityScopeGames => 'Partidas';

  @override
  String get activityScopeSearches => 'Buscas';

  @override
  String get activityNoResult => 'Resultado não informado';

  @override
  String get activityDetailMode => 'Modo';

  @override
  String get activityDetailDuration => 'Duração';

  @override
  String get activityDetailScore => 'Placar';

  @override
  String get activityDetailResult => 'Resultado';

  @override
  String get activityDetailStatus => 'Status';

  @override
  String get activityDetailFcAccount => 'Conta';

  @override
  String get historyLoadErrorTitle => 'Não foi possível carregar o histórico';

  @override
  String get historyLoadMore => 'Carregar mais';

  @override
  String historyEntryDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String historyEntryTime(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$timeString';
  }

  @override
  String get statsTotalSearches => 'Buscas';

  @override
  String get statsMatchFound => 'Encontradas';

  @override
  String get statsCancelled => 'Canceladas';

  @override
  String get statsExpired => 'Expiradas';

  @override
  String get statsSuccessRate => 'Taxa de sucesso';

  @override
  String get statsAvgDuration => 'Duração média';

  @override
  String get statsPlayersTitle => 'Por jogador';

  @override
  String get statsEmptyTitle => 'Sem dados no período';

  @override
  String get statsEmptyMessage =>
      'Quando o time buscar partidas, as estatísticas aparecem aqui.';

  @override
  String get statsLoadErrorTitle => 'Não foi possível carregar as estatísticas';

  @override
  String statsPlayerSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count buscas',
      one: '1 busca',
    );
    return '$_temp0';
  }

  @override
  String get gameModeSectionTitle => 'Modo';

  @override
  String get gameModeWeekendLeague => 'Weekend League';

  @override
  String get gameModeDivisionRivals => 'Division Rivals';

  @override
  String get pendingMatchTitle => 'Você tem uma partida sem resultado';

  @override
  String get pendingMatchWinAction => 'Vitória';

  @override
  String get pendingMatchLossAction => 'Derrota';

  @override
  String get pendingMatchAddScoreAction => 'Adicionar placar';

  @override
  String get finishMatchSheetTitle => 'Resultado da partida';

  @override
  String get finishMatchSheetMessage => 'Informe o placar da sua partida.';

  @override
  String get finishMatchGoalsForLabel => 'Seus gols';

  @override
  String get finishMatchGoalsAgainstLabel => 'Gols do adversário';

  @override
  String get finishMatchGoalsRequired => 'Informe um número válido.';

  @override
  String get finishMatchDrawError => 'Empate não é um resultado final válido.';

  @override
  String get finishMatchSubmitAction => 'Salvar resultado';

  @override
  String weekendLeagueBadge(int number) {
    return 'Weekend League #$number';
  }

  @override
  String weekendLeagueWindow(String start, String end) {
    return '$start – $end';
  }

  @override
  String get weekendLeagueActiveBadge => 'Em andamento';

  @override
  String get errorFcAccountNotFound => 'Conta não encontrada.';

  @override
  String get errorFcAccountNotLinkedToTeam =>
      'Esta conta não está vinculada a este time.';

  @override
  String get errorFcAccountInvalidName =>
      'Informe um nome de 2 a 40 caracteres.';

  @override
  String get errorFcAccountInvalidDivision => 'Divisão inválida.';

  @override
  String get errorFcAccountNotLinkedToAnyTeam =>
      'Esta conta não está vinculada a nenhum time.';

  @override
  String get validationFcAccountNameRequired => 'Informe um nome para a conta.';

  @override
  String validationFcAccountNameTooShort(int min) {
    return 'O nome precisa ter pelo menos $min caracteres.';
  }

  @override
  String validationFcAccountNameTooLong(int max) {
    return 'O nome pode ter no máximo $max caracteres.';
  }

  @override
  String get fcAccountRequiredToSearch =>
      'Crie ou selecione uma conta para buscar partida.';

  @override
  String fcAccountLinkCta(String accountName, String teamName) {
    return 'Vincular $accountName ao $teamName';
  }

  @override
  String get fcAccountsPageTitle => 'Minhas Contas';

  @override
  String get fcAccountsPageSubtitle => 'Suas contas de Ultimate Team';

  @override
  String get fcAccountsEmptyTitle => 'Você ainda não tem uma conta';

  @override
  String get fcAccountsEmptyMessage =>
      'Crie uma conta para vincular a times e começar a buscar partidas.';

  @override
  String get fcAccountCreateAction => 'Criar conta';

  @override
  String get fcAccountCreateTitle => 'Nova conta';

  @override
  String get fcAccountCreateSubtitle =>
      'Dê um nome para identificar esta conta.';

  @override
  String get fcAccountNameLabel => 'Nome da conta';

  @override
  String get fcAccountNameHint => 'Ex.: Conta principal';

  @override
  String get fcAccountRenameTitle => 'Renomear conta';

  @override
  String get fcAccountRenameAction => 'Renomear';

  @override
  String get fcAccountArchiveAction => 'Arquivar conta';

  @override
  String get fcAccountArchiveConfirmTitle => 'Arquivar conta?';

  @override
  String get fcAccountArchiveConfirmMessage =>
      'A conta deixa de aparecer na lista, mas o histórico dela é mantido.';

  @override
  String get fcAccountSwitchTitle => 'Trocar de conta';

  @override
  String get fcAccountSwitchCreateAction => '+ Criar nova conta';

  @override
  String get fcAccountLinkedTeamsTitle => 'Times vinculados';

  @override
  String get fcAccountLinkedTeamsEmpty =>
      'Esta conta ainda não está vinculada a nenhum time.';

  @override
  String get fcAccountLinkTeamAction => 'Vincular';

  @override
  String get fcAccountUnlinkTeamAction => 'Desvincular';

  @override
  String get fcAccountSettingsTitle => 'Configurações';

  @override
  String get fcAccountDivisionTitle => 'Divisão de Rivals';

  @override
  String get fcAccountDivisionPickerTitle => 'Selecionar divisão';

  @override
  String get fcAccountDivisionNone => 'Sem divisão definida';

  @override
  String get fcAccountWeekendLeagueTitle => 'Weekend League';

  @override
  String fcAccountWeekendLeagueComputedLabel(int wins, int losses) {
    return 'Registrado por partidas: $wins–$losses';
  }

  @override
  String fcAccountWeekendLeagueManualLabel(int wins, int losses) {
    return 'Resultado informado: $wins–$losses';
  }

  @override
  String get fcAccountWeekendLeagueEditAction => 'Informar resultado';

  @override
  String get fcAccountWeekendLeagueClearAction => 'Usar resultado das partidas';

  @override
  String get fcAccountWeekendLeagueSheetTitle => 'Informar resultado';

  @override
  String get fcAccountWeekendLeagueWinsLabel => 'Vitórias';

  @override
  String get fcAccountWeekendLeagueLossesLabel => 'Derrotas';

  @override
  String get fcAccountOnboardingTitle => 'Crie sua primeira conta';

  @override
  String get fcAccountOnboardingMessage =>
      'Uma conta representa um perfil seu no Ultimate Team. Crie uma para vincular aos seus times e começar a buscar partidas.';

  @override
  String get fcAccountOnboardingCreateAction => 'Criar conta';

  @override
  String pendingMatchElencoLabel(String name) {
    return 'Conta: $name';
  }

  @override
  String historyElencoLabel(String name) {
    return 'Conta: $name';
  }

  @override
  String get profileFcAccountsRow => 'Contas';

  @override
  String get rivalsDivisionDiv10 => 'Divisão 10';

  @override
  String get rivalsDivisionDiv9 => 'Divisão 9';

  @override
  String get rivalsDivisionDiv8 => 'Divisão 8';

  @override
  String get rivalsDivisionDiv7 => 'Divisão 7';

  @override
  String get rivalsDivisionDiv6 => 'Divisão 6';

  @override
  String get rivalsDivisionDiv5 => 'Divisão 5';

  @override
  String get rivalsDivisionDiv4 => 'Divisão 4';

  @override
  String get rivalsDivisionDiv3 => 'Divisão 3';

  @override
  String get rivalsDivisionDiv2 => 'Divisão 2';

  @override
  String get rivalsDivisionDiv1 => 'Divisão 1';

  @override
  String get rivalsDivisionElite => 'Elite';

  @override
  String get squadsSectionTitle => 'Squads';

  @override
  String get squadBuilderSaved => 'Salvo';

  @override
  String get squadBuilderSaving => 'Salvando…';

  @override
  String get squadsEmptyTitle => 'Nenhum squad configurado';

  @override
  String get squadsEmptyMessage =>
      'Crie um squad para montar sua escalação. Você pode buscar partida mesmo sem um.';

  @override
  String get squadCreateAction => 'Criar squad';

  @override
  String get squadCreateTitle => 'Novo squad';

  @override
  String get squadCreateSubtitle => 'Dê um nome e escolha a formação inicial.';

  @override
  String get squadNameLabel => 'Nome do squad';

  @override
  String get squadNameHint => 'Ex.: Principal';

  @override
  String get squadFormationLabel => 'Formação';

  @override
  String get squadRenameTitle => 'Renomear squad';

  @override
  String get squadRenameAction => 'Renomear';

  @override
  String get squadSetDefaultAction => 'Definir como padrão';

  @override
  String get squadDefaultBadge => 'Padrão';

  @override
  String get squadArchiveAction => 'Arquivar squad';

  @override
  String get squadArchiveConfirmTitle => 'Arquivar squad?';

  @override
  String get squadArchiveConfirmMessage =>
      'Ele sai da lista, mas o histórico das partidas jogadas com ele é mantido.';

  @override
  String get squadBenchTitle => 'Banco';

  @override
  String get squadManagerTitle => 'Técnico';

  @override
  String get squadManagerAddAction => 'Adicionar técnico';

  @override
  String get squadManagerRemoveAction => 'Remover técnico';

  @override
  String get squadManagerNationLabel => 'País';

  @override
  String get squadManagerLeagueLabel => 'Liga';

  @override
  String get squadManagerPickNationFirst =>
      'Escolha um país para ver os técnicos.';

  @override
  String get squadManagerNoneTitle => 'Sem técnico';

  @override
  String get squadFormationPickerTitle => 'Escolher formação';

  @override
  String get squadPlayerPickerTitle => 'Buscar jogador';

  @override
  String get squadPlayerSearchHint => 'Buscar jogador...';

  @override
  String get squadPlayerPickerEmpty => 'Nenhuma carta encontrada.';

  @override
  String get squadSlotChangeAction => 'Trocar jogador';

  @override
  String get squadSlotMoveAction => 'Mover';

  @override
  String get squadSlotRemoveAction => 'Remover';

  @override
  String get squadMoveHint => 'Toque em outro slot para trocar.';

  @override
  String get squadIncompleteLabel => 'Squad incompleto';

  @override
  String get squadLabel => 'Squad';

  @override
  String get squadNoneSelected => 'Sem squad';

  @override
  String get squadDevCatalogNotice =>
      'Cartas de desenvolvimento. O catálogo real chega na próxima etapa.';

  @override
  String get squadFilterLeagueLabel => 'Liga';

  @override
  String get squadFilterClubLabel => 'Clube';

  @override
  String get squadFilterNationLabel => 'Nação';

  @override
  String get errorSquadNotFound => 'Squad não encontrado.';

  @override
  String get errorSquadNameInvalid => 'Escolha um nome de 1 a 40 caracteres.';

  @override
  String get errorSquadFormationInvalid => 'Essa formação não está disponível.';

  @override
  String get errorSquadSlotInvalid => 'Essa posição não existe nesta formação.';

  @override
  String get errorSquadCardPosition => 'Esse jogador não atua nessa posição.';

  @override
  String get errorSquadInUse =>
      'Este squad está sendo usado em uma busca ativa.';

  @override
  String squadCompletionLabel(int filled, int total) {
    return '$filled/$total titulares';
  }

  @override
  String squadSummaryLabel(String name, String formation) {
    return '$name · $formation';
  }

  @override
  String squadSlotCountLabel(int filled, int total) {
    return '$filled/$total';
  }

  @override
  String squadOverallValue(int overall) {
    return 'OVR $overall';
  }

  @override
  String get squadOverallUnknown => 'OVR --';

  @override
  String squadChemistryValue(int chemistry) {
    return '$chemistry/33';
  }

  @override
  String get squadReserveTitle => 'Reservas';

  @override
  String get squadClearAction => 'Limpar escalação';

  @override
  String get squadClearConfirmTitle => 'Limpar escalação?';

  @override
  String get squadClearConfirmMessage =>
      'Isso remove todos os jogadores dos titulares, do banco e das reservas. O squad em si não é apagado.';

  @override
  String get squadFormationChangeConfirmTitle => 'Trocar formação?';

  @override
  String get squadFormationChangeConfirmMessage =>
      'Seus jogadores serão reposicionados automaticamente. Ninguém é removido, mas alguém pode ficar fora de posição.';

  @override
  String get squadFilterCompatibleLabel => 'Compatíveis';

  @override
  String get squadPositionBadgePrimary => 'Primária';

  @override
  String get squadPositionBadgeAlternative => 'Alternativa';

  @override
  String get squadPositionBadgeOutOfPosition => 'Fora de posição';

  @override
  String get squadCardDetailAction => 'Ver detalhes';

  @override
  String get squadCardDetailRatingLabel => 'Rating';

  @override
  String get squadCardDetailPositionLabel => 'Posição';

  @override
  String get squadCardDetailAltPositionsLabel => 'Posições alternativas';

  @override
  String get squadCardDetailStatsTitle => 'Atributos';

  @override
  String get squadCardDetailGkStatsTitle => 'Atributos de goleiro';

  @override
  String get squadCardDetailWeakFootLabel => 'Pé fraco';

  @override
  String get squadCardDetailSkillMovesLabel => 'Habilidades';

  @override
  String get squadCardDetailPreferredFootLabel => 'Pé preferido';

  @override
  String get squadCardDetailPreferredFootLeft => 'Esquerdo';

  @override
  String get squadCardDetailPreferredFootRight => 'Direito';

  @override
  String get squadCardDetailPlaystylesTitle => 'Playstyles';

  @override
  String get squadCardDetailRolesTitle => 'Funções';

  @override
  String get squadCardDetailClubLabel => 'Clube';

  @override
  String get squadCardDetailLeagueLabel => 'Liga';

  @override
  String get squadCardDetailNationLabel => 'Nação';

  @override
  String get squadCardDetailOtherVersionsTitle => 'Outras versões';

  @override
  String get squadCardDetailOtherVersionsComingSoon =>
      'Em breve: comparar todas as versões deste jogador.';

  @override
  String get actionMore => 'Mais';

  @override
  String get errorGameInvalidStatsPayload =>
      'Não foi possível salvar esses gols/assistências.';

  @override
  String get errorGamePlayerNotInSquad =>
      'Esse jogador não fez parte desta partida.';

  @override
  String get errorGameNoSquadSnapshot =>
      'Esta partida não tem escalação registrada.';

  @override
  String get errorGameMatchNotFinished =>
      'Finalize a partida antes de editar o resultado.';

  @override
  String get pendingMatchDetailsPromptTitle => 'Adicionar detalhes da partida?';

  @override
  String get pendingMatchDetailsPromptMessage =>
      'Você pode registrar gols e assistências por jogador agora ou depois, pelo Histórico.';

  @override
  String get pendingMatchDetailsPromptAddAction => 'Adicionar agora';

  @override
  String get pendingMatchDetailsPromptSkipAction => 'Agora não';

  @override
  String get matchDetailsTitle => 'Detalhe da partida';

  @override
  String get matchDetailsResultLabel => 'Resultado';

  @override
  String get matchDetailsScoreLabel => 'Placar';

  @override
  String get matchDetailsNoResultMessage => 'Sem resultado registrado.';

  @override
  String get matchDetailsEditResultAction => 'Editar resultado';

  @override
  String get matchDetailsAddDetailsAction => 'Adicionar gols e assistências';

  @override
  String get matchDetailsEditDetailsAction => 'Editar gols e assistências';

  @override
  String get matchDetailsSquadSectionTitle => 'Escalação';

  @override
  String get matchDetailsPlayerStatsTitle => 'Gols e assistências';

  @override
  String get matchDetailsPlayerStatsEmptyMessage =>
      'Nenhum gol ou assistência registrado nesta partida.';

  @override
  String get editMatchResultSheetTitle => 'Editar resultado';

  @override
  String get editMatchResultSheetMessage =>
      'Você pode corrigir o placar a qualquer momento, mesmo depois da partida encerrada.';

  @override
  String get editMatchResultSubmitAction => 'Salvar resultado';

  @override
  String get playerStatsEditorTitle => 'Gols e assistências';

  @override
  String get playerStatsEditorStartingLabel => 'Titulares';

  @override
  String get playerStatsEditorBenchLabel => 'Banco';

  @override
  String get playerStatsEditorSaveAction => 'Salvar detalhes';

  @override
  String get statsGoalsLabel => 'Gols';

  @override
  String get statsAssistsLabel => 'Assistências';

  @override
  String get statsMatchesLabel => 'Partidas';

  @override
  String get statsWinsLabel => 'Vitórias';

  @override
  String get statsLossesLabel => 'Derrotas';

  @override
  String get statsGoalDiffLabel => 'Saldo de gols';

  @override
  String get statsGoalsAgainstLabel => 'Gols sofridos';

  @override
  String get statsTopScorersTitle => 'Artilharia';

  @override
  String get statsTopAssistsTitle => 'Assistências';

  @override
  String get statsEmptyLeaderboardMessage =>
      'Nenhum gol ou assistência registrado ainda.';

  @override
  String statsTopScorerInlineLabel(String name, int goals) {
    return '$name · $goals gols';
  }

  @override
  String get fcAccountStatsTitle => 'Estatísticas';

  @override
  String get fcAccountStatsEmptyMessage => 'Nenhuma partida registrada ainda.';

  @override
  String get weekendLeagueDetailManualNote =>
      'O resultado informado manualmente é diferente do que as partidas detalhadas mostram até agora.';

  @override
  String get rivalsSectionTitle => 'Division Rivals';

  @override
  String get rivalsDetailTitle => 'Division Rivals';

  @override
  String get rivalsNoDivisionLabel => 'Divisão ainda não informada';

  @override
  String get rivalsAllTimeNote =>
      'Estatísticas de todas as partidas registradas (ainda sem separação por season/semana).';

  @override
  String get playerProfileSportSummaryTitle => 'Resumo esportivo';

  @override
  String get playerProfileRivalsLabel => 'Division Rivals';

  @override
  String get playerProfileNoStatsMessage => 'Ainda sem partidas detalhadas.';

  @override
  String get squadChemistryDetailTitle => 'Química da escalação';

  @override
  String get squadChemistryPlayerTitle => 'Química do jogador';

  @override
  String get squadChemistrySourceClub => 'Clube';

  @override
  String get squadChemistrySourceLeague => 'Liga';

  @override
  String get squadChemistrySourceNation => 'Nação';

  @override
  String get squadChemistrySourceManager => 'Técnico';

  @override
  String get squadChemistryNoSources =>
      'Este jogador não compartilha clube, liga nem nação com nenhum outro titular.';

  @override
  String get squadChemistryOutOfPositionExplain =>
      'Fora de posição: não pontua e não conta para a química dos companheiros.';

  @override
  String get squadChemistryCappedNote => 'Já está no máximo de 3.';

  @override
  String squadChemistryRuleNote(String version) {
    return 'Regra $version.';
  }

  @override
  String squadChemistryFullPlayers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogadores com química cheia',
      one: '1 jogador com química cheia',
      zero: 'Nenhum jogador com química cheia',
    );
    return '$_temp0';
  }

  @override
  String squadChemistryLowPlayers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogadores com química zero',
      one: '1 jogador com química zero',
      zero: 'Nenhum jogador com química zero',
    );
    return '$_temp0';
  }

  @override
  String squadChemistryOutOfPositionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogadores fora de posição',
      one: '1 jogador fora de posição',
      zero: 'Ninguém fora de posição',
    );
    return '$_temp0';
  }

  @override
  String squadChemistryEmptySlotsNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posições vazias',
      one: '1 posição vazia',
    );
    return '$_temp0';
  }

  @override
  String get squadPrimaryLineupTitle => 'Escalação Principal';

  @override
  String get squadPrimaryLineupEditAction => 'Editar escalação';

  @override
  String get squadPrimaryLineupCreateAction => 'Montar escalação';

  @override
  String get squadPrimaryLineupEmpty =>
      'Você ainda não montou uma escalação para este elenco.';

  @override
  String squadOtherLineupsAction(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ver outras $count escalações',
      one: 'Ver outra escalação',
    );
    return '$_temp0';
  }

  @override
  String get teamSportsSummaryTitle => 'Resumo';

  @override
  String get teamSportsMatches => 'Partidas';

  @override
  String get teamSportsWins => 'Vitórias';

  @override
  String get teamSportsLosses => 'Derrotas';

  @override
  String get teamSportsWinRate => 'Aproveitamento';

  @override
  String get teamSportsGoalsFor => 'Gols';

  @override
  String get teamSportsGoalsAgainst => 'Sofridos';

  @override
  String get teamSportsGoalDifference => 'Saldo';

  @override
  String get teamSportsRankingTitle => 'Ranking';

  @override
  String get teamSportsScorersTitle => 'Artilharia';

  @override
  String get teamSportsAssistsTitle => 'Assistências';

  @override
  String get teamSportsWeekendLeagueTitle => 'Weekend League';

  @override
  String get teamSportsRivalsTitle => 'Division Rivals';

  @override
  String get teamSportsActivityTitle => 'Atividade recente';

  @override
  String get teamSportsSeeAll => 'Ver tudo';

  @override
  String get teamSportsSmallSample => 'Amostra pequena';

  @override
  String get teamSportsNoMatchesYet =>
      'Este Time ainda não registrou partidas.';

  @override
  String get teamSportsNoMatchesMember => 'Sem partidas';

  @override
  String get teamSportsNoScorersYet => 'Nenhum gol registrado ainda.';

  @override
  String get teamSportsNoAssistsYet => 'Nenhuma assistência registrada ainda.';

  @override
  String get teamSportsNoActivityYet => 'Nenhuma partida concluída ainda.';

  @override
  String get teamSportsManualRecord => 'Manual';

  @override
  String get teamSportsNoDivision => 'Sem divisão';

  @override
  String get teamSportsActivityWin => 'venceu';

  @override
  String get teamSportsActivityLoss => 'perdeu';

  @override
  String teamSportsAccountsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Contas',
      one: '1 Conta',
    );
    return '$_temp0';
  }

  @override
  String teamSportsMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membros',
      one: '1 membro',
    );
    return '$_temp0';
  }

  @override
  String teamSportsMatchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partidas registradas',
      one: '1 partida registrada',
    );
    return '$_temp0';
  }

  @override
  String teamSportsRecordLine(int matches, int wins, int losses) {
    return '${matches}J · ${wins}V · ${losses}D';
  }

  @override
  String teamSportsMinSampleHint(int count) {
    return 'Ranqueado a partir de $count partidas.';
  }

  @override
  String teamSportsGoalsShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gols',
      one: '1 gol',
    );
    return '$_temp0';
  }

  @override
  String teamSportsAssistsShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count assistências',
      one: '1 assistência',
    );
    return '$_temp0';
  }

  @override
  String get profileSharingRow => 'Compartilhamento';

  @override
  String get publicProfileSectionTitle => 'Compartilhamento';

  @override
  String get publicProfileMasterSwitchLabel => 'Perfil público';

  @override
  String get publicProfileMasterSwitchHint =>
      'Deixe seu perfil visível por um link público, sem precisar de conta no app.';

  @override
  String get publicProfileStatusActive => 'Perfil público: Ativo';

  @override
  String get publicProfileStatusInactive => 'Perfil público: Inativo';

  @override
  String get publicProfileSlugLabel => 'Endereço do seu perfil';

  @override
  String get publicProfileSlugHint => '3 a 24 letras minúsculas, números ou _';

  @override
  String get publicProfileSlugAvailable => 'Disponível';

  @override
  String get publicProfileSlugUnavailable => 'Este endereço já está em uso';

  @override
  String get publicProfileSlugChecking => 'Verificando…';

  @override
  String get publicProfileSlugInvalid => 'Endereço inválido';

  @override
  String get publicProfileAccountLabel => 'Conta pública';

  @override
  String get publicProfileAccountEmpty => 'Nenhuma conta selecionada';

  @override
  String get publicProfileToggleSquad => 'Escalação Principal';

  @override
  String get publicProfileToggleWeekendLeague => 'Weekend League';

  @override
  String get publicProfileToggleRivals => 'Division Rivals';

  @override
  String get publicProfileToggleStats => 'Estatísticas gerais';

  @override
  String get publicProfileCopyLinkAction => 'Copiar link';

  @override
  String get publicProfileLinkCopied => 'Link copiado';

  @override
  String get publicProfileShareAction => 'Compartilhar';

  @override
  String get publicProfileShareImageAction => 'Compartilhar imagem';

  @override
  String get publicProfileShareImageError =>
      'Não foi possível compartilhar a imagem neste dispositivo.';

  @override
  String get publicProfileSaveAction => 'Salvar';

  @override
  String get publicProfileSaved => 'Configurações salvas';

  @override
  String get publicProfilePreviewTitle => 'Pré-visualização';

  @override
  String get publicProfilePageTitle => 'Perfil';

  @override
  String get publicProfileNotFoundTitle => 'Perfil não encontrado';

  @override
  String get publicProfileNotFoundMessage =>
      'Este link não existe ou não está mais disponível.';

  @override
  String get publicProfileShareAccountCta => 'Compartilhar esta Conta';

  @override
  String get publicProfileShareSquadCta => 'Compartilhar escalação';

  @override
  String get publicProfileEnableFirstMessage =>
      'Ative o perfil público para compartilhar sua escalação.';

  @override
  String get publicProfileGoToSettingsAction => 'Ir para Compartilhamento';

  @override
  String get publicProfileEditSharingCta => 'Editar compartilhamento';

  @override
  String get publicProfileNoAccountsHint =>
      'Crie um Elenco antes de compartilhar.';

  @override
  String get errorPublicProfileInvalidSlug =>
      'Endereço inválido. Use 3-24 letras minúsculas, números ou _.';

  @override
  String get errorPublicProfileReservedSlug =>
      'Este endereço é reservado, escolha outro.';

  @override
  String get errorPublicProfileSlugTaken => 'Este endereço já está em uso.';

  @override
  String get errorPublicProfileSlugRequired =>
      'Escolha um endereço antes de ativar o perfil público.';

  @override
  String get validationPublicProfileSlugRequired =>
      'Escolha um endereço para o perfil.';

  @override
  String validationPublicProfileSlugTooShort(int min) {
    return 'O endereço precisa ter pelo menos $min caracteres.';
  }

  @override
  String validationPublicProfileSlugTooLong(int max) {
    return 'O endereço pode ter no máximo $max caracteres.';
  }

  @override
  String get validationPublicProfileSlugInvalid =>
      'Use só letras minúsculas, números ou _.';

  @override
  String get errorSoleOwnerBlocksAccountDeletion =>
      'Você é dono único de um time com outros integrantes. Remova os outros integrantes ou aguarde suporte a transferência de posse antes de excluir sua conta.';

  @override
  String get profileLegalTitle => 'Sobre e legal';

  @override
  String get aboutTitle => 'Sobre';

  @override
  String get aboutDescription =>
      'FIFA Queue organiza a fila de busca de partida, elencos e estatísticas do seu time de EA SPORTS FC.';

  @override
  String get privacyPolicyTitle => 'Política de Privacidade';

  @override
  String get termsOfUseTitle => 'Termos de Uso';

  @override
  String legalUpdatedAt(String date) {
    return 'Atualizado em $date';
  }

  @override
  String get deleteAccountRow => 'Excluir minha conta';

  @override
  String get deleteAccountTitle => 'Excluir conta';

  @override
  String get deleteAccountWarningTitle => 'Esta ação é permanente';

  @override
  String get deleteAccountWarningMessage =>
      'Ao excluir sua conta, você perde acesso a tudo o que está listado abaixo. Não é possível desfazer ou recuperar depois.';

  @override
  String get deleteAccountConsequenceFcAccounts =>
      'Todos os seus elencos (Contas EA FC) e a divisão de Rivals registrada';

  @override
  String get deleteAccountConsequenceSquads =>
      'Suas escalações (Squad Builder)';

  @override
  String get deleteAccountConsequenceHistory =>
      'Sua participação nos times de que você faz parte';

  @override
  String get deleteAccountConsequenceStats =>
      'Seu histórico e estatísticas pessoais de partidas';

  @override
  String get deleteAccountConsequencePreferences =>
      'Suas preferências de notificação e dispositivos registrados';

  @override
  String get deleteAccountConsequencePublicProfile =>
      'Seu perfil público, se estiver ativado';

  @override
  String deleteAccountTypeToConfirm(String word) {
    return 'Para confirmar, digite $word no campo abaixo.';
  }

  @override
  String get deleteAccountConfirmWord => 'EXCLUIR';

  @override
  String get deleteAccountAction => 'Excluir minha conta permanentemente';

  @override
  String get homeFcAccountEyebrow => 'CONTA FC ATIVA';

  @override
  String get homeFcAccountSwitchAction => 'Trocar';

  @override
  String get homeFcAccountNoTeams => 'Ainda sem time';

  @override
  String homeFcAccountTeamCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Em $count times',
      one: 'Em 1 time',
    );
    return '$_temp0';
  }

  @override
  String get homeNoTeamTitle => 'Entre em um time';

  @override
  String get homeNoTeamMessage =>
      'Buscar partida exige um time. Rivals e Weekend League você já pode usar.';

  @override
  String get pendingMatchSkipAction => 'Não informar esta partida';

  @override
  String get pendingMatchSkipConfirmTitle => 'Não informar o resultado?';

  @override
  String get pendingMatchSkipConfirmMessage =>
      'A partida sai daqui sem contar como vitória nem derrota. Você pode buscar outra normalmente.';

  @override
  String get historyResultNotInformed => 'Resultado não informado';

  @override
  String get weekendLeagueWeekPickerTitle => 'Selecionar semana';

  @override
  String get weekendLeagueChangeWeekAction => 'Trocar';

  @override
  String get weekendLeagueCurrentWeekBadge => 'Em andamento';
}
