// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Match Queue';

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
  String get profileSignOutConfirmTitle => 'Sair da conta?';

  @override
  String get profileSignOutConfirmMessage =>
      'Você pode entrar de novo a qualquer momento com seu e-mail e senha.';

  @override
  String get actionEdit => 'Editar';

  @override
  String get navCentral => 'Central';

  @override
  String get navControl => 'Jogar';

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
  String get startEyebrow => 'MATCH QUEUE';

  @override
  String get startTitle => 'Visão geral';

  @override
  String get startSubtitle => 'Seu time e sua semana em um lugar.';

  @override
  String get startShortcutsTitle => 'Atalhos';

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
  String get teamPublicPageMembersTitle => 'Membros';

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
  String get inviteShareSubject => 'Convite para o time no Match Queue';

  @override
  String inviteShareMessage(String url) {
    return 'Entre no meu time pelo Match Queue: $url';
  }

  @override
  String inviteShareMessageCodeOnly(String code) {
    return 'Entre no meu time pelo Match Queue com o código: $code';
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
  String get startupErrorTitle => 'Não foi possível iniciar o Match Queue';

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
  String get authEmailHint => 'email@exemplo.com';

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
      'Escolha uma nova senha para voltar a usar o Match Queue.';

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

    return 'No Match Queue desde $dateString';
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
  String get playerProfileSquadLabel => 'Escalação';

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
      'Nenhum evento de Champions registrado.';

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
  String get teamRoleManager => 'Gerente';

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
  String get errorAlreadyTeamMember => 'Você já faz parte deste time.';

  @override
  String get errorDuplicateTeamRequest => 'Já existe uma solicitação pendente.';

  @override
  String get errorTeamRequestNotFound => 'Esta solicitação não existe mais.';

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
  String get errorMatchmakingNotInQueue => 'Você não está na fila deste time.';

  @override
  String get errorMatchmakingNoActiveSearchToPrioritize =>
      'Ninguém está buscando partida por este time agora.';

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
      'Quando entrar na partida, marque que encontrou.';

  @override
  String get matchmakingSearchingOtherTitle => 'Alguém está buscando partida';

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
  String get matchmakingYourTurnTitle => 'Sua vez de buscar!';

  @override
  String get matchmakingBottomSheetTitle => 'Busca em andamento';

  @override
  String matchmakingBottomSheetMessage(String teamName) {
    return 'Alguém está buscando partida pelo Time $teamName.';
  }

  @override
  String matchmakingPlayerLabel(int position) {
    return 'Jogador $position';
  }

  @override
  String matchmakingCooldownLabel(int seconds) {
    return 'Aguarde ${seconds}s';
  }

  @override
  String get matchmakingExpiredTitle => 'Tempo esgotado';

  @override
  String get matchmakingExpiredMessage =>
      'O tempo de busca acabou e você foi removido da fila. Pode buscar de novo quando quiser.';

  @override
  String get matchmakingRequestPriorityAction => 'Solicitar prioridade';

  @override
  String get matchmakingPriorityRequestedConfirmation =>
      'Prioridade solicitada';

  @override
  String matchmakingSearchingElsewhereMessage(String teamName) {
    return 'Você está buscando partida pelo Time $teamName.';
  }

  @override
  String get matchmakingNotLinkedMessage =>
      'Vincule esta Conta FC a este time para poder buscar partida.';

  @override
  String get matchmakingLinkAccountAction => 'Vincular Conta ao time';

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
      'Novos membros, ranking, Champions e Rivals.';

  @override
  String get notificationsCategoryMatchmaking => 'Matchmaking';

  @override
  String get notificationsCategoryMatchmakingHint =>
      'Sua vez, avisos de expiração da busca.';

  @override
  String get notificationsCategoryTeams => 'Convites para time';

  @override
  String get notificationsCategoryTeamsHint =>
      'Pedidos e convites de entrada, novos membros no time.';

  @override
  String get notificationsCategoryWeekendLeague => 'Champions';

  @override
  String get notificationsCategoryWeekendLeagueHint =>
      'Quando o Champions termina.';

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
    return '$displayName terminou o Champions em $wins-$losses.';
  }

  @override
  String notificationRivalsDivisionChanged(
    String displayName,
    String division,
  ) {
    return '$displayName chegou à $division no Rivals.';
  }

  @override
  String notificationTeamJoinRequestReceived(
    String requesterDisplayName,
    String teamName,
  ) {
    return '$requesterDisplayName pediu para entrar no $teamName.';
  }

  @override
  String notificationTeamJoinRequestApproved(String teamName) {
    return 'Seu pedido para entrar no $teamName foi aprovado.';
  }

  @override
  String notificationTeamJoinRequestRejected(String teamName) {
    return 'Seu pedido para entrar no $teamName foi recusado.';
  }

  @override
  String notificationTeamInvitationReceived(String teamName) {
    return 'Você recebeu um convite para o $teamName.';
  }

  @override
  String notificationTeamInvitationAccepted(
    String displayName,
    String teamName,
  ) {
    return '$displayName aceitou seu convite para o $teamName.';
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
  String get activityScopeGames => 'Jogos';

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
  String get gameModeWeekendLeague => 'Champions';

  @override
  String get gameModeDivisionRivals => 'Rivals';

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
    return 'Champions #$number';
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
  String get fcAccountLinkedTeamsTitle => 'Times';

  @override
  String get fcAccountLinkedTeamsEmpty =>
      'Esta conta ainda não está vinculada a nenhum time.';

  @override
  String get fcAccountSharingAction => 'Compartilhamento';

  @override
  String get fcAccountAvatarChangeAction => 'Alterar foto';

  @override
  String get fcAccountAvatarRemoveAction => 'Remover foto';

  @override
  String get fcAccountAvatarRemoveConfirmTitle => 'Remover a foto da conta?';

  @override
  String get fcAccountAvatarRemoveConfirmMessage =>
      'A conta volta a mostrar as iniciais no lugar da foto.';

  @override
  String get fcAccountLinkTeamAction => 'Vincular';

  @override
  String get fcAccountUnlinkTeamAction => 'Sair do time';

  @override
  String get fcAccountLeaveTeamConfirmTitle => 'Sair do time?';

  @override
  String fcAccountLeaveTeamConfirmMessage(String teamName) {
    return 'Essa conta vai deixar de representar o Time $teamName. Você pode vincular de novo quando quiser.';
  }

  @override
  String get fcAccountSettingsTitle => 'Configurações';

  @override
  String get fcAccountDivisionTitle => 'Divisão de Rivals';

  @override
  String get fcAccountDivisionPickerTitle => 'Selecionar divisão';

  @override
  String get fcAccountDivisionNone => 'Sem divisão definida';

  @override
  String get fcAccountWeekendLeagueTitle => 'Champions';

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
  String get fcAccountOnboardingTitle => 'Adicione sua primeira conta';

  @override
  String get fcAccountOnboardingMessage =>
      'Cadastre a conta que você joga ou gerencia para participar de times, buscar partidas e acompanhar seu progresso.';

  @override
  String get fcAccountOnboardingCreateAction => 'Adicionar conta';

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
  String get squadsSectionTitle => 'Escalações';

  @override
  String get squadBuilderSaved => 'Salvo';

  @override
  String get squadBuilderSaving => 'Salvando…';

  @override
  String get squadsEmptyTitle => 'Nenhuma escalação configurada';

  @override
  String get squadsEmptyMessage =>
      'Crie uma escalação para colocar seus jogadores em campo. Você pode buscar partida mesmo sem uma.';

  @override
  String get squadCreateAction => 'Criar escalação';

  @override
  String get squadCreateTitle => 'Nova escalação';

  @override
  String get squadCreateSubtitle => 'Dê um nome e escolha a formação inicial.';

  @override
  String get squadNameLabel => 'Nome da escalação';

  @override
  String get squadNameHint => 'Ex.: Principal';

  @override
  String get squadFormationLabel => 'Formação';

  @override
  String get squadRenameTitle => 'Renomear escalação';

  @override
  String get squadRenameAction => 'Renomear';

  @override
  String get squadSetDefaultAction => 'Definir como padrão';

  @override
  String get squadDefaultBadge => 'Padrão';

  @override
  String get squadArchiveAction => 'Arquivar escalação';

  @override
  String get squadArchiveConfirmTitle => 'Arquivar escalação?';

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
  String get squadIncompleteLabel => 'Escalação incompleta';

  @override
  String get squadLabel => 'Escalação';

  @override
  String get playAccountLabel => 'Conta';

  @override
  String get playSquadEmpty => 'Nenhuma escalação montada';

  @override
  String get playSquadBuildAction => 'Montar escalação';

  @override
  String get playSquadEditAction => 'Editar escalação';

  @override
  String get squadNoneSelected => 'Sem escalação';

  @override
  String get squadFilterLeagueLabel => 'Liga';

  @override
  String get squadFilterNationLabel => 'Nação';

  @override
  String get squadFilterClearAction => 'Limpar filtros';

  @override
  String get errorSquadNotFound => 'Escalação não encontrada.';

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
      'Esta escalação está sendo usada em uma busca ativa.';

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
      'Isso remove todos os jogadores dos titulares, do banco e das reservas. A escalação em si não é apagada.';

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
  String get squadCardDetailPlaystylesPlusTitle => 'PlayStyles+';

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
  String get statsWinsLabel => 'Vitórias';

  @override
  String get statsLossesLabel => 'Derrotas';

  @override
  String get recordAddWinTooltip => 'Adicionar vitória';

  @override
  String get recordAddLossTooltip => 'Adicionar derrota';

  @override
  String get recordRemoveWinTooltip => 'Remover vitória';

  @override
  String get recordRemoveLossTooltip => 'Remover derrota';

  @override
  String get statsEmptyLeaderboardMessage =>
      'Nenhum gol ou assistência registrado ainda.';

  @override
  String get rivalsSectionTitle => 'Rivals';

  @override
  String get rivalsDetailTitle => 'Rivals';

  @override
  String get rivalsNoDivisionLabel => 'Divisão ainda não informada';

  @override
  String get rivalsAllTimeNote =>
      'Contador manual, sem separação por season/semana ainda.';

  @override
  String get playerProfileSportSummaryTitle => 'Resumo esportivo';

  @override
  String get playerProfileRivalsLabel => 'Rivals';

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
      'Você ainda não montou uma escalação para esta Conta.';

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
  String get teamSportsWeekendLeagueTitle => 'Champions';

  @override
  String get teamSportsRivalsTitle => 'Rivals';

  @override
  String get teamSportsActivityTitle => 'Atividade recente';

  @override
  String get teamSportsNoMatchesYet =>
      'Este Time ainda não registrou partidas.';

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
  String get publicProfileSectionTitle => 'Privacidade';

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
  String get publicProfileToggleWeekendLeague => 'Champions';

  @override
  String get publicProfileToggleRivals => 'Rivals';

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
      'Crie uma Conta antes de compartilhar.';

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
      'Match Queue organiza a fila de busca de partida, Contas e estatísticas do seu time de EA SPORTS FC.';

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
      'Todas as suas Contas e a divisão de Rivals registrada';

  @override
  String get deleteAccountConsequenceSquads => 'Suas escalações';

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
      'Buscar partida exige um time. Rivals e Champions você já pode usar.';

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

  @override
  String get rivalsSetDivisionAction => 'Informar';

  @override
  String get controlNoTeamTitle => 'Você precisa de um time';

  @override
  String get controlNoTeamMessage =>
      'A fila é do time. Entre em um ou crie o seu para começar a buscar.';

  @override
  String get controlNoTeamAction => 'Ver times';

  @override
  String get controlAccountNotLinkedMessage =>
      'Crie ou vincule esta conta a algum time para poder buscar partidas.';

  @override
  String get controlGoToTeamsAction => 'Ir para Times';

  @override
  String get navRequests => 'Convites';

  @override
  String get requestsPageTitle => 'Solicitações';

  @override
  String get requestsSegmentRequests => 'Pedidos';

  @override
  String get requestsSegmentInvites => 'Convites';

  @override
  String get requestsEmptyRequestsTitle => 'Nenhum pedido pendente';

  @override
  String get requestsEmptyRequestsMessage =>
      'Pedidos de entrada nos times que você administra aparecem aqui.';

  @override
  String get requestsEmptyInvitesTitle => 'Nenhum convite pendente';

  @override
  String get requestsEmptyInvitesMessage =>
      'Convites que você receber de outros times aparecem aqui.';

  @override
  String requestsMemberCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membros',
      one: '1 membro',
    );
    return '$_temp0';
  }

  @override
  String requestsJoinRequestWantsToJoin(String account) {
    return 'Quer entrar com $account';
  }

  @override
  String get requestsApproveAction => 'Aprovar';

  @override
  String get requestsRejectAction => 'Recusar';

  @override
  String get requestsAcceptAction => 'Aceitar';

  @override
  String get requestsDeclineAction => 'Recusar';

  @override
  String get requestsApprovedMessage => 'Pedido aprovado.';

  @override
  String get requestsRejectedMessage => 'Pedido recusado.';

  @override
  String get requestsInvitationAcceptedMessage => 'Convite aceito.';

  @override
  String get requestsInvitationRejectedMessage => 'Convite recusado.';

  @override
  String get requestsLoadErrorTitle =>
      'Não foi possível carregar as solicitações';

  @override
  String get teamPublicRequestToJoinAction => 'Pedir para entrar';

  @override
  String get teamPublicRequestSentAction => 'Solicitação enviada';

  @override
  String get teamPublicRequestCancelAction => 'Cancelar solicitação';

  @override
  String get teamPublicChooseAccountTitle => 'Qual Conta você quer vincular?';

  @override
  String get teamPublicRequestSentMessage =>
      'Pedido enviado. O dono do time vai revisar.';

  @override
  String get teamPublicRequestCancelledMessage => 'Solicitação cancelada.';

  @override
  String get teamDetailInviteAction => 'Convidar jogador';

  @override
  String get teamInviteSheetTitle => 'Convidar jogador';

  @override
  String get teamInviteSlugFieldLabel => 'Nick ou código do perfil';

  @override
  String get teamInviteSlugFieldHint =>
      'Digite o nome ou o código do perfil público do jogador';

  @override
  String get teamInviteSendAction => 'Enviar convite';

  @override
  String get teamInviteNotFoundMessage => 'Nenhum perfil público encontrado.';

  @override
  String get teamInviteSentMessage => 'Convite enviado.';

  @override
  String get teamPendingRequestsSectionTitle => 'Pedidos pendentes';

  @override
  String get teamSentInvitationsSectionTitle => 'Convites pendentes';

  @override
  String get teamInviteRevokeAction => 'Cancelar convite';

  @override
  String get teamMemberPromoteAction => 'Tornar gerente';

  @override
  String get teamMemberDemoteAction => 'Remover da gerência';

  @override
  String get teamMemberRemoveAction => 'Remover do time';

  @override
  String teamMemberRemoveConfirmTitle(String name) {
    return 'Remover $name do time?';
  }

  @override
  String get teamMemberRemoveConfirmMessage =>
      'Essa pessoa deixa de fazer parte do time. O histórico dela é preservado.';

  @override
  String get teamMemberRemovedMessage => 'Jogador removido do time.';

  @override
  String get teamMemberRoleUpdatedMessage => 'Cargo atualizado.';

  @override
  String get teamLogoChangeAction => 'Alterar logo';

  @override
  String get teamLogoAddAction => 'Adicionar logo';

  @override
  String get teamLogoRemoveAction => 'Remover logo';

  @override
  String get teamLogoRemoveConfirmTitle => 'Remover a logo do time?';

  @override
  String get teamLogoRemoveConfirmMessage =>
      'O time volta a mostrar as iniciais no lugar da logo.';

  @override
  String pendingMatchesCardTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partidas sem resultado',
      one: '1 partida sem resultado',
    );
    return '$_temp0';
  }

  @override
  String pendingMatchesCardLatest(String mode, String date, String time) {
    return 'Mais recente: $mode · $date às $time';
  }

  @override
  String get pendingMatchesOpenListAction => 'Ver partidas';

  @override
  String get pendingMatchesDismissAllAction => 'Não informar';

  @override
  String get pendingMatchesDismissAllTitle => 'Não informar nenhuma?';

  @override
  String get pendingMatchesDismissAllMessage =>
      'Todas saem da lista sem contar como vitória nem derrota.';

  @override
  String get pendingMatchesSheetTitle => 'Partidas sem resultado';

  @override
  String get pendingMatchesSheetMessage =>
      'Informe o que quiser. Deixar em branco não bloqueia nada.';

  @override
  String get pendingMatchesSkipOneAction => 'Não informar';

  @override
  String get pendingMatchesAllClear => 'Nenhuma partida pendente.';

  @override
  String get errorWeekendLeagueLimit =>
      'O Champions tem 15 partidas: vitórias e derrotas somadas não podem passar disso.';

  @override
  String get squadNoneSelectedHint => 'Escolha uma escalação para esta busca';

  @override
  String get catalogCardsTitle => 'Jogadores';

  @override
  String get catalogCardsSearchLabel => 'Buscar carta';

  @override
  String get catalogCardsSearchHint => 'Nome do jogador';

  @override
  String get catalogCardsEmptyTitle => 'Nenhuma carta encontrada';

  @override
  String get catalogCardsEmptyMessage =>
      'Ajuste a busca ou os filtros para ver outras cartas.';

  @override
  String get catalogClubsTitle => 'Clubes';

  @override
  String get catalogClubsSearchLabel => 'Buscar clube';

  @override
  String get catalogClubsSearchHint => 'Nome do clube';

  @override
  String get catalogClubsEmptyTitle => 'Nenhum clube encontrado';

  @override
  String get catalogClubsEmptyMessage =>
      'Ajuste a busca ou os filtros para ver outros clubes.';

  @override
  String get catalogClubAverageLabel => 'Média';

  @override
  String catalogClubCardsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartas',
      one: '1 carta',
    );
    return '$_temp0';
  }

  @override
  String get catalogGenderMen => 'Masculino';

  @override
  String get catalogGenderWomen => 'Feminino';

  @override
  String get catalogPositionGroupGoalkeeper => 'Goleiro';

  @override
  String get catalogPositionGroupDefender => 'Defensor';

  @override
  String get catalogPositionGroupMidfielder => 'Meio-campista';

  @override
  String get catalogPositionGroupForward => 'Atacante';

  @override
  String get filterAll => 'Todas';

  @override
  String get startShortcutPlayHint =>
      'Escolha a conta, o modo e entre na fila.';

  @override
  String get startCatalogTitle => 'Catálogo';

  @override
  String get startCatalogCardsHint => 'Explore as cartas do jogo.';

  @override
  String get startCatalogClubsHint => 'Clubes por overall médio.';

  @override
  String get catalogClubsFilterAll => 'Todos';

  @override
  String get centralSectionCatalog => 'Catálogo';

  @override
  String get centralSectionMechanics => 'Mecânicas';

  @override
  String get centralSectionControls => 'Controles';

  @override
  String get catalogManagersEntryLabel => 'Managers';

  @override
  String get catalogConsumablesEntryLabel => 'Consumíveis';

  @override
  String get mechanicsPlaystylesLabel => 'PlayStyles';

  @override
  String get mechanicsPlaystylesHint => 'Habilidades especiais de cada carta.';

  @override
  String get mechanicsChemistryLabel => 'Chemistry';

  @override
  String get mechanicsChemistryHint => 'Como a química da escalação funciona.';

  @override
  String get mechanicsChemistryStylesLabel => 'Chemistry Styles';

  @override
  String get mechanicsChemistryStylesHint => 'Estilos que reforçam atributos.';

  @override
  String get mechanicsEvolutionsLabel => 'Evolutions';

  @override
  String get mechanicsEvolutionsHint =>
      'Como jogadores evoluem no Ultimate Team.';

  @override
  String mechanicsPlaystylesCardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartas',
      one: '1 carta',
      zero: 'Nenhuma carta',
    );
    return '$_temp0';
  }

  @override
  String get mechanicsPlaystyleEffectLabel => 'Efeito';

  @override
  String get mechanicsPlaystylePlusEffectLabel => 'Efeito Plus';

  @override
  String get playstyleCategoryFinishing => 'Finalização';

  @override
  String get playstyleCategoryPassing => 'Passe';

  @override
  String get playstyleCategoryDefending => 'Defesa';

  @override
  String get playstyleCategoryBallControl => 'Controle de bola';

  @override
  String get playstyleCategoryPhysical => 'Físico';

  @override
  String get playstyleCategoryGoalkeeper => 'Goleiro';

  @override
  String get playstyleEffectFinesseShot =>
      'Melhora curva, precisão e velocidade de execução do chute de efeito.';

  @override
  String get playstylePlusEffectFinesseShot =>
      'Reforça ainda mais curva, precisão e execução do chute de efeito.';

  @override
  String get playstyleEffectChipShot =>
      'Cavadinhas mais rápidas e precisas sobre o goleiro adiantado.';

  @override
  String get playstylePlusEffectChipShot =>
      'Cavadinha ainda mais rápida e precisa.';

  @override
  String get playstyleEffectPowerShot =>
      'Aumenta força e velocidade da bola no chute de potência.';

  @override
  String get playstylePlusEffectPowerShot =>
      'Chute de potência mais forte, com trajetória mais baixa e controlada.';

  @override
  String get playstyleEffectDeadBall =>
      'Cobranças de falta e escanteio com mais velocidade, curva e precisão, e prévia de trajetória estendida.';

  @override
  String get playstylePlusEffectDeadBall =>
      'Cobranças com velocidade, curva e precisão excepcionais, prévia de trajetória no máximo.';

  @override
  String get playstyleEffectPrecisionHeader =>
      'Melhora precisão e potência de cabeceio controlado.';

  @override
  String get playstylePlusEffectPrecisionHeader =>
      'Ganho de precisão e potência ainda maior no cabeceio.';

  @override
  String get playstyleEffectAcrobatic =>
      'Melhora precisão de voleios e libera animações acrobáticas extras.';

  @override
  String get playstylePlusEffectAcrobatic =>
      'Precisão maior e acesso a finalizações acrobáticas mais eficazes.';

  @override
  String get playstyleEffectLowDrivenShot =>
      'Melhora a precisão do chute rasteiro e forte.';

  @override
  String get playstylePlusEffectLowDrivenShot =>
      'Bônus de precisão maior no chute rasteiro e forte.';

  @override
  String get playstyleEffectGamechanger =>
      'Chutes de efeito e de trivela (parte externa do pé) com mais precisão.';

  @override
  String get playstylePlusEffectGamechanger =>
      'Chutes de efeito e trivela com precisão muito maior.';

  @override
  String get playstyleEffectIncisivePass =>
      'Melhora precisão do passe em profundidade, curva do passe com efeito e velocidade do passe de precisão.';

  @override
  String get playstylePlusEffectIncisivePass =>
      'Reforça ainda mais os três, sem melhorar o primeiro toque de quem recebe.';

  @override
  String get playstyleEffectPingedPass =>
      'Passes rasteiros viajam mais rápido sem dificultar o primeiro toque de quem recebe.';

  @override
  String get playstylePlusEffectPingedPass =>
      'Passes rasteiros consideravelmente mais rápidos.';

  @override
  String get playstyleEffectLongBallPass =>
      'Lançamentos longos mais precisos, rápidos e difíceis de interceptar.';

  @override
  String get playstylePlusEffectLongBallPass =>
      'Reforça ainda mais precisão, velocidade e eficácia dos lançamentos longos.';

  @override
  String get playstyleEffectTikiTaka =>
      'Melhora passes curtos e de primeira difíceis, com backheels contextuais.';

  @override
  String get playstylePlusEffectTikiTaka =>
      'Bônus de precisão maior nos passes curtos e de primeira.';

  @override
  String get playstyleEffectWhippedPass =>
      'Cruzamentos com mais precisão, velocidade e curva.';

  @override
  String get playstylePlusEffectWhippedPass =>
      'Cruzamentos ainda mais fortes, com cruzamento forte de potência excepcional.';

  @override
  String get playstyleEffectInventive =>
      'Passes de efeito e de trivela com mais precisão.';

  @override
  String get playstylePlusEffectInventive =>
      'Passes de efeito e trivela com precisão muito maior.';

  @override
  String get playstyleEffectJockey =>
      'Melhora o movimento ao marcar de frente (contain) e a transição entre marcar e correr.';

  @override
  String get playstylePlusEffectJockey =>
      'Bônus de marcação maior, embora a diferença pra um defensor forte sem o estilo seja menor no FC 27.';

  @override
  String get playstyleEffectBlock =>
      'Aumenta alcance e eficácia ao bloquear chutes e passes.';

  @override
  String get playstylePlusEffectBlock =>
      'Alcance e eficácia de bloqueio ainda maiores.';

  @override
  String get playstyleEffectIntercept =>
      'Melhora alcance de interceptação e a chance de manter a bola depois dela.';

  @override
  String get playstylePlusEffectIntercept =>
      'Reforça ainda mais alcance e retenção de bola pós-interceptação.';

  @override
  String get playstyleEffectAnticipate =>
      'Melhora o sucesso do carrinho em pé e a chance de sair com a bola.';

  @override
  String get playstylePlusEffectAnticipate =>
      'Bônus significativamente maior no carrinho em pé e na retenção pós-desarme.';

  @override
  String get playstyleEffectSlideTackle =>
      'Melhora a retenção da bola perto do jogador após um carrinho deslizante bem-sucedido.';

  @override
  String get playstylePlusEffectSlideTackle =>
      'Cobertura de carrinho deslizante e retenção de bola ainda maiores.';

  @override
  String get playstyleEffectAerialFortress =>
      'Permite saltos mais altos e mais presença física em disputas aéreas defensivas.';

  @override
  String get playstylePlusEffectAerialFortress =>
      'Saltos ainda mais altos e presença física ainda maior nas disputas aéreas.';

  @override
  String get playstyleEffectTechnical =>
      'Melhora a velocidade da corrida controlada e o controle em curvas mais largas.';

  @override
  String get playstylePlusEffectTechnical =>
      'Bônus maior de corrida controlada e controle de drible.';

  @override
  String get playstyleEffectRapid =>
      'Melhora o drible em velocidade máxima e reduz erros em toques em alta velocidade.';

  @override
  String get playstylePlusEffectRapid => 'Bônus maior de drible em sprint.';

  @override
  String get playstyleEffectFirstTouch =>
      'Reduz o erro de primeiro toque e acelera a transição pro drible.';

  @override
  String get playstylePlusEffectFirstTouch =>
      'Reduz ainda mais o erro de primeiro toque, transição pro drible ainda mais rápida.';

  @override
  String get playstyleEffectTrickster =>
      'Libera embaixadinhas/floreios únicos.';

  @override
  String get playstylePlusEffectTrickster =>
      'Libera floreios extras e mais agilidade ao driblar de lado.';

  @override
  String get playstyleEffectPressProven =>
      'Mantém a bola mais perto ao trotar e melhora a proteção contra oponentes mais fortes.';

  @override
  String get playstylePlusEffectPressProven =>
      'Controle excepcional ao trotar e proteção de bola muito melhor.';

  @override
  String get playstyleEffectQuickStep =>
      'Melhora a aceleração no sprint explosivo.';

  @override
  String get playstylePlusEffectQuickStep =>
      'Bônus de aceleração maior que o normal, mas dependente do atributo de Aceleração do jogador.';

  @override
  String get playstyleEffectRelentless =>
      'Reduz o cansaço durante a partida e melhora a recuperação de fôlego no intervalo.';

  @override
  String get playstylePlusEffectRelentless =>
      'Reduz muito mais o efeito do cansaço de longo prazo nos atributos.';

  @override
  String get playstyleEffectLongThrow =>
      'Aumenta força e distância do arremesso lateral.';

  @override
  String get playstylePlusEffectLongThrow =>
      'Arremesso lateral com ainda mais força e distância máxima.';

  @override
  String get playstyleEffectBruiser =>
      'Mais força em disputas físicas de carrinho.';

  @override
  String get playstylePlusEffectBruiser =>
      'Vantagem de força ainda maior nas disputas físicas.';

  @override
  String get playstyleEffectEnforcer =>
      'Melhora disputas de ombro ao driblar e torna a proteção de bola mais eficaz.';

  @override
  String get playstylePlusEffectEnforcer =>
      'Melhora muito mais as disputas de ombro e a proteção de bola.';

  @override
  String get playstyleEffectFarThrow =>
      'Arremessos do goleiro com mais velocidade e distância.';

  @override
  String get playstylePlusEffectFarThrow =>
      'Arremessos com velocidade e distância ainda maiores.';

  @override
  String get playstyleEffectFootwork =>
      'Defesas com os pés mais rápidas e com mais alcance.';

  @override
  String get playstylePlusEffectFootwork =>
      'Defesas com os pés ainda mais rápidas e com mais alcance.';

  @override
  String get playstyleEffectCrossClaimer =>
      'Sai para cruzamentos com mais ritmo, melhor leitura de trajetória, e mais alcance/força no soco.';

  @override
  String get playstylePlusEffectCrossClaimer =>
      'Ainda mais ritmo, leitura e força no soco em cruzamentos.';

  @override
  String get playstyleEffectRushOut =>
      'Aumenta velocidade de saída e reação em situações de um contra um.';

  @override
  String get playstylePlusEffectRushOut =>
      'Velocidade de saída muito maior e reações mais rápidas.';

  @override
  String get playstyleEffectFarReach =>
      'Melhora o alcance em defesas de mergulho e libera animações de alcance estendido.';

  @override
  String get playstylePlusEffectFarReach =>
      'Alcance de mergulho ainda maior e defesas de alcance estendido mais fortes.';

  @override
  String get playstyleEffectDeflector =>
      'Melhora a capacidade de espalmar a bola pra áreas mais seguras, controlando o rebote.';

  @override
  String get playstylePlusEffectDeflector =>
      'Mais controle de espalmada, podendo direcionar a defesa pra um lugar seguro ou pra um companheiro.';

  @override
  String get mechanicsPlaystyleFilterAny => 'Todas';

  @override
  String get mechanicsPlaystyleFilterPlusOnly => 'Só Plus';

  @override
  String get controlsDribblingLabel => 'Dribles';

  @override
  String get controlsPassingLabel => 'Passes';

  @override
  String get controlsShootingLabel => 'Finalização';

  @override
  String get controlsDefendingLabel => 'Defesa';

  @override
  String get controlsActionColumnLabel => 'Ação';

  @override
  String get controlsHeadingControls => 'Controles';

  @override
  String get controlsShootingAction1 => 'Chute normal / voleio / cabeceio';

  @override
  String get controlsShootingAction2 => 'Chute rasteiro e forte';

  @override
  String get controlsShootingPs2 => '◯, depois ◯ de novo ao carregar';

  @override
  String get controlsShootingXbox2 => 'B, depois B de novo ao carregar';

  @override
  String get controlsShootingAction3 => 'Cavadinha';

  @override
  String get controlsShootingAction4 => 'Chute de efeito';

  @override
  String get controlsShootingAction5 => 'Chute de efeito rasteiro';

  @override
  String get controlsShootingPs5 => 'R1 + ◯, depois ◯ de novo';

  @override
  String get controlsShootingXbox5 => 'RB + B, depois B de novo';

  @override
  String get controlsShootingAction6 => 'Chute de potência';

  @override
  String get controlsShootingAction7 => 'Chute de potência rasteiro';

  @override
  String get controlsShootingPs7 => 'L1 + R1 + ◯, depois ◯ de novo';

  @override
  String get controlsShootingXbox7 => 'LB + RB + B, depois B de novo';

  @override
  String get controlsShootingAction8 =>
      'Chute de estilo (trivela, bicicleta...)';

  @override
  String get controlsShootingAction9 => 'Fake de chute';

  @override
  String get controlsShootingPs9 => '◯ depois ✕ + direção';

  @override
  String get controlsShootingXbox9 => 'B depois A + direção';

  @override
  String get controlsShootingAction10 => 'Cancelar chute';

  @override
  String get controlsShootingPs10 => 'L2 + R2 durante a animação';

  @override
  String get controlsShootingXbox10 => 'LT + RT durante a animação';

  @override
  String get controlsShootingHeadingWhenToUse => 'Quando usar cada um';

  @override
  String get controlsShootingBullet1 =>
      'Chute normal: opção mais versátil, funciona bem na maioria das situações dentro da área.';

  @override
  String get controlsShootingBullet2 =>
      'Chute rasteiro: bom pra bater cruzado ou no goleiro adiantado, rasteiro nos cantos.';

  @override
  String get controlsShootingBullet3 =>
      'Chute de efeito: prioriza colocação e curva -- ótimo cortando pra dentro pelo lado e mirando o canto mais longe.';

  @override
  String get controlsShootingBullet4 =>
      'Chute de potência: exige mais tempo e espaço livre, melhor fora da área do que dentro dela.';

  @override
  String get controlsShootingBullet5 =>
      'Cavadinha: quando o goleiro sai da linha e sobra espaço por cima dele.';

  @override
  String get controlsShootingBullet6 =>
      'Chute de estilo: mais imprevisível, deixa a animação decidir entre bicicleta, carrinho de fora ou outro floreio conforme a posição do jogador.';

  @override
  String get controlsShootingBullet7 =>
      'Fake de chute: engana o goleiro ou o defensor mudando de direção sem finalizar de verdade.';

  @override
  String get controlsShootingHeadingPower => 'Potência e mira';

  @override
  String get controlsShootingPowerParagraph =>
      'Quanto mais tempo segura o botão de chute, mais força o chute recebe. Perto do gol, potência baixa ou média costuma funcionar melhor que o chute no talo -- excesso de força é mais difícil de controlar de perto.';

  @override
  String get controlsPassingHeadingShort => 'Passe curto (rasteiro)';

  @override
  String get controlsPassingAction1 => 'Passe rasteiro';

  @override
  String get controlsPassingAction2 => 'Passe rasteiro elevado';

  @override
  String get controlsPassingAction3 => 'Passe rasteiro forte';

  @override
  String get controlsPassingAction4 => 'Passe de efeito';

  @override
  String get controlsPassingAction5 => 'Passe rasteiro de precisão (com curva)';

  @override
  String get controlsPassingHeadingThrough =>
      'Passe em profundidade (through pass)';

  @override
  String get controlsPassingAction6 => 'Passe em profundidade';

  @override
  String get controlsPassingAction7 => 'Passe em profundidade elevado';

  @override
  String get controlsPassingAction8 => 'Passe em profundidade de precisão';

  @override
  String get controlsPassingAction9 => 'Passe em profundidade lobado';

  @override
  String get controlsPassingAction10 => 'Passe em profundidade forte';

  @override
  String get controlsPassingAction11 => 'Passe em profundidade de efeito';

  @override
  String get controlsPassingHeadingCrossing => 'Lançamento e cruzamento';

  @override
  String get controlsPassingAction12 => 'Lançamento / cruzamento';

  @override
  String get controlsPassingAction13 => 'Cruzamento rasteiro';

  @override
  String get controlsPassingAction14 => 'Lançamento de precisão';

  @override
  String get controlsPassingAction15 => 'Lançamento forte';

  @override
  String get controlsPassingAction16 => 'Cruzamento rasteiro forte';

  @override
  String get controlsPassingAction17 => 'Lançamento bem alto';

  @override
  String get controlsPassingAction18 => 'Lançamento de efeito';

  @override
  String get controlsPassingHeadingOthers => 'Outros';

  @override
  String get controlsPassingAction19 => 'Toque e vai (Pass and Go)';

  @override
  String get controlsPassingAction20 => 'Fake de passe';

  @override
  String get controlsPassingPs20 => '□ depois ✕ + direção';

  @override
  String get controlsPassingXbox20 => 'X depois A + direção';

  @override
  String get controlsPassingHeadingIdeas => 'Ideias pra aplicar';

  @override
  String get controlsPassingBullet1 =>
      'Passe rasteiro mantém a posse no meio-campo; passe em profundidade serve pra jogadores fazendo corrida por trás da defesa.';

  @override
  String get controlsPassingBullet2 =>
      'Lançamento troca o jogo rápido pro lado aberto do campo.';

  @override
  String get controlsPassingBullet3 =>
      'Passe forte (driven) sai mais rápido sob pressão, mas com menos controle do que o de precisão.';

  @override
  String get controlsPassingBullet4 =>
      'Quanto mais tempo segura o botão, mais força o passe recebe -- combinar o tipo certo com a força certa importa tanto quanto escolher o companheiro certo.';

  @override
  String get controlsDefendingAction1 => 'Trocar de jogador';

  @override
  String get controlsDefendingAction2 => 'Marcação (contain / jockey)';

  @override
  String get controlsDefendingPs2 => 'Segurar L2';

  @override
  String get controlsDefendingXbox2 => 'Segurar LT';

  @override
  String get controlsDefendingAction3 => 'Marcação em sprint';

  @override
  String get controlsDefendingPs3 => 'Segurar L2 + R2';

  @override
  String get controlsDefendingXbox3 => 'Segurar LT + RT';

  @override
  String get controlsDefendingAction4 => 'Carrinho em pé';

  @override
  String get controlsDefendingAction5 => 'Carrinho em pé forte';

  @override
  String get controlsDefendingAction6 => 'Carrinho deslizante';

  @override
  String get controlsDefendingAction7 => 'Carrinho deslizante forte';

  @override
  String get controlsDefendingAction8 => 'Pedir pressão de um companheiro';

  @override
  String get controlsDefendingPs8 => 'Segurar R1';

  @override
  String get controlsDefendingXbox8 => 'Segurar RB';

  @override
  String get controlsDefendingAction9 => 'Pressão coletiva parcial';

  @override
  String get controlsDefendingPs9 => 'R1, depois segurar R1';

  @override
  String get controlsDefendingXbox9 => 'RB, depois segurar RB';

  @override
  String get controlsDefendingAction10 => 'Goleiro adiantar a linha';

  @override
  String get controlsDefendingPs10 => 'Segurar △';

  @override
  String get controlsDefendingXbox10 => 'Segurar Y';

  @override
  String get controlsDefendingHeadingTips => 'Dicas';

  @override
  String get controlsDefendingBullet1 =>
      'Marcação (jockey) primeiro, carrinho depois: mantenha o defensor de frente pro atacante, reduza o espaço, e só tente o desarme quando a bola ficar exposta.';

  @override
  String get controlsDefendingBullet2 =>
      'Carrinho deslizante é opção de último recurso -- errar deixa o adversário livre ou pode virar falta, cartão ou pênalti.';

  @override
  String get controlsDefendingBullet3 =>
      'Troque de jogador manualmente em vez de sempre pegar o mais perto da bola: às vezes cobrir a linha de passe mais perigosa importa mais do que pressionar quem já está marcado.';

  @override
  String get controlsDefendingBullet4 =>
      'Não puxe o zagueiro pra frente sem necessidade -- isso abre espaço nas costas da defesa pra um passe em profundidade.';

  @override
  String get controlsDefendingBullet5 =>
      'Contra um contra-ataque, prioridade é atrasar o avanço (recuar protegendo o meio) e só então fechar o lance, dando tempo pros companheiros se recomporem.';

  @override
  String get controlsDefendingBullet6 =>
      'Ao defender cruzamento, não olhe só pro ponta -- cubra também quem chega no segundo pau.';

  @override
  String get controlsDribblingIntroParagraph =>
      'Cada jogador tem uma nota de Skill Moves (1 a 5 estrelas) que define quais desses movimentos ele consegue fazer. Comandos usam o analógico direito e são iguais em PlayStation e Xbox/PC.';

  @override
  String controlsDribblingStarWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'estrelas',
      one: 'estrela',
    );
    return '$_temp0';
  }

  @override
  String get controlsDribblingSkillName1 => 'Elástico simples pro lado';

  @override
  String get controlsDribblingSkillControl1 => 'Segurar L1+R1 + direção';

  @override
  String get controlsDribblingSkillName2 => 'Chapéu (Flick Up)';

  @override
  String get controlsDribblingSkillControl2 => 'R3';

  @override
  String get controlsDribblingSkillName3 => 'Giro de corpo pra frente';

  @override
  String get controlsDribblingSkillControl3 =>
      'Segurar L1+R1 + esquerdo p/ baixo';

  @override
  String get controlsDribblingSkillName4 => 'Pedalada (Stepover) direita';

  @override
  String get controlsDribblingSkillControl4 => 'Girar direito ↑→';

  @override
  String get controlsDribblingSkillName5 => 'Pedalada (Stepover) esquerda';

  @override
  String get controlsDribblingSkillControl5 => 'Girar direito ↑←';

  @override
  String get controlsDribblingSkillName6 => 'Corta-luz (Ball Roll) direita';

  @override
  String get controlsDribblingSkillControl6 => 'Segurar direito →';

  @override
  String get controlsDribblingSkillName7 => 'Corta-luz (Ball Roll) esquerda';

  @override
  String get controlsDribblingSkillControl7 => 'Segurar direito ←';

  @override
  String get controlsDribblingSkillName8 => 'Puxada de bola (Drag Back)';

  @override
  String get controlsDribblingSkillControl8 => 'L2+R2 + flick esquerdo ↓';

  @override
  String get controlsDribblingSkillName9 => 'Roleta direita';

  @override
  String get controlsDribblingSkillControl9 => 'Girar direito ↓ até ←';

  @override
  String get controlsDribblingSkillName10 => 'Roleta esquerda';

  @override
  String get controlsDribblingSkillControl10 => 'Girar direito ↓ até →';

  @override
  String get controlsDribblingSkillName11 => 'Finta e vai pra direita';

  @override
  String get controlsDribblingSkillControl11 => 'Girar direito ←↓→';

  @override
  String get controlsDribblingSkillName12 => 'Finta e vai pra esquerda';

  @override
  String get controlsDribblingSkillControl12 => 'Girar direito →↓←';

  @override
  String get controlsDribblingSkillName13 => 'Corte de calcanhar correndo';

  @override
  String get controlsDribblingSkillControl13 =>
      'Segurar L2 + ■/○ então X + esquerdo';

  @override
  String get controlsDribblingSkillName14 => 'Arco-íris simples';

  @override
  String get controlsDribblingSkillControl14 => 'Flick direito ↓↑↑';

  @override
  String get controlsDribblingSkillName15 => 'Giro pra esquerda';

  @override
  String get controlsDribblingSkillControl15 =>
      'Segurar R2+R1 + girar direito ↖';

  @override
  String get controlsDribblingSkillName16 => 'Giro pra direita';

  @override
  String get controlsDribblingSkillControl16 =>
      'Segurar R2+R1 + girar direito ↗';

  @override
  String get controlsDribblingSkillName17 => 'Fake de passe';

  @override
  String get controlsDribblingSkillControl17 => 'Segurar R2 + ■/○ então X';

  @override
  String get controlsDribblingSkillName18 => 'Corte com corta-luz';

  @override
  String get controlsDribblingSkillControl18 =>
      'Segurar direito ← + esquerdo →';

  @override
  String get controlsDribblingSkillName19 => 'Elástico';

  @override
  String get controlsDribblingSkillControl19 => 'Direito → girar ↓←';

  @override
  String get controlsDribblingSkillName20 => 'Elástico invertido';

  @override
  String get controlsDribblingSkillControl20 => 'Direito ← girar ↓→';

  @override
  String get controlsDribblingSkillName21 => 'Arco-íris avançado';

  @override
  String get controlsDribblingSkillControl21 => 'Flick direito ↓ segurar ↑↑';

  @override
  String get controlsDribblingSkillName22 =>
      'Sombrero (chapéu em cima do marcador)';

  @override
  String get controlsDribblingSkillControl22 => 'Flick direito ↑↑↓';

  @override
  String get controlsDribblingSkillName23 => 'Rabona fake';

  @override
  String get controlsDribblingSkillControl23 =>
      'Segurar L2 + ■/○ então X + esquerdo ↓';

  @override
  String get controlsDribblingHeadingOtherControls =>
      'Outros comandos de drible';

  @override
  String get controlsDribblingAction1 => 'Corrida controlada';

  @override
  String get controlsDribblingPs1 => 'Segurar R1 + direção';

  @override
  String get controlsDribblingXbox1 => 'Segurar RB + direção';

  @override
  String get controlsDribblingAction2 => 'Proteger a bola';

  @override
  String get controlsDribblingPs2 => 'Segurar L2';

  @override
  String get controlsDribblingXbox2 => 'Segurar LT';

  @override
  String get controlsDribblingAction3 => 'Toque de esforço';

  @override
  String get controlsDribblingPs3 => 'R1 + flick direito';

  @override
  String get controlsDribblingXbox3 => 'RB + flick direito';

  @override
  String get controlsDribblingAction4 => 'Fake de chute';

  @override
  String get controlsDribblingPs4 => '◯ depois ✕ + direção';

  @override
  String get controlsDribblingXbox4 => 'B depois A + direção';

  @override
  String get controlsDribblingHeadingIdeas => 'Ideias pra aplicar';

  @override
  String get controlsDribblingBullet1 =>
      'Um drible bom reage ao movimento do defensor -- floreio sem motivo costuma facilitar perder a bola.';

  @override
  String get controlsDribblingBullet2 =>
      'Mude de velocidade em vez de correr sempre no talo: normal perto do defensor, corrida controlada pra se aproximar, sprint só quando o espaço já está aberto.';

  @override
  String get controlsDribblingBullet3 =>
      'Crie espaço primeiro, acelere depois: mude de direção ou faça um drible simples, espere o marcador se comprometer, só então acelere pro espaço livre.';

  @override
  String get chemistryIntroParagraph =>
      'Chemistry define o quanto o Chemistry Style aplicado numa carta realmente entrega. Não é mais um sistema de \"linhas\" entre jogadores adjacentes como em gerações antigas do jogo -- é construído em cima da escalação titular inteira.';

  @override
  String get chemistryHeadingHowEarned => 'Como cada jogador ganha Chemistry';

  @override
  String get chemistryHowEarnedParagraph =>
      'Todo titular pode ter de 0 a 3 pontos de Chemistry. O time inteiro soma até 33 pontos de Squad Chemistry.';

  @override
  String get chemistryHowEarnedBullet1 =>
      '0 de Chemistry: nenhum bônus de Chemistry Style, mas o jogador continua com os atributos normais da carta.';

  @override
  String get chemistryHowEarnedBullet2 =>
      '1 de Chemistry: bônus pequeno do Chemistry Style aplicado.';

  @override
  String get chemistryHowEarnedBullet3 => '2 de Chemistry: bônus médio.';

  @override
  String get chemistryHowEarnedBullet4 => '3 de Chemistry: bônus máximo.';

  @override
  String get chemistryHeadingPosition => 'Pré-requisito: posição preferida';

  @override
  String get chemistryPositionParagraph =>
      'Um jogador só ganha e contribui Chemistry se estiver numa das posições preferidas dele na formação. Fora disso, fica com 0 de Chemistry e não conta pros totais de clube, liga ou nação -- mesmo estando na escalação.';

  @override
  String get chemistryHeadingClubLeagueNation => 'Clube, liga e nação/região';

  @override
  String get chemistryClubLeagueNationParagraph =>
      'Os titulares contribuem juntos pros totais de clube, liga e nação/região do time inteiro -- não precisa mais estar do lado de outro jogador igual antes.';

  @override
  String get chemistryClubLeagueNationBullet1 =>
      '2 jogadores do mesmo clube: +1 de Chemistry de clube.';

  @override
  String get chemistryClubLeagueNationBullet2 =>
      '4 jogadores do mesmo clube: +2.';

  @override
  String get chemistryClubLeagueNationBullet3 =>
      '7 jogadores do mesmo clube: +3.';

  @override
  String get chemistryClubLeagueNationBullet4 =>
      '2 jogadores da mesma nação/região: +1.';

  @override
  String get chemistryClubLeagueNationBullet5 =>
      '5 jogadores da mesma nação/região: +2.';

  @override
  String get chemistryClubLeagueNationBullet6 =>
      '8 jogadores da mesma nação/região: +3.';

  @override
  String get chemistryClubLeagueNationBullet7 =>
      '3 jogadores da mesma liga: +1.';

  @override
  String get chemistryClubLeagueNationBullet8 =>
      '5 jogadores da mesma liga: +2.';

  @override
  String get chemistryClubLeagueNationBullet9 =>
      '8 jogadores da mesma liga: +3.';

  @override
  String get chemistryHeadingManager => 'Técnico';

  @override
  String get chemistryManagerParagraph =>
      'O técnico pode dar +1 de Chemistry extra a um jogador que compartilhe liga ou nação/região com ele, até o máximo de 3.';

  @override
  String get chemistryHeadingIconsHeroes => 'Ícones e Heróis';

  @override
  String get chemistryIconsHeroesParagraph =>
      'Ícones e Heróis sempre têm Chemistry máximo (3) quando jogam na posição certa. Ícones contam pra todas as ligas representadas no time, além da própria nação; Heróis dão Chemistry extra pra própria liga e nação. Isso facilita muito montar times híbridos.';

  @override
  String get chemistryHeadingMenWomen => 'Masculino e feminino';

  @override
  String get chemistryMenWomenParagraph =>
      'Jogadores e jogadoras contribuem Chemistry juntos quando compartilham nação/região, ou quando os clubes masculino e feminino são afiliados -- mas não se conectam pela liga.';

  @override
  String get chemistryHeadingSubs => 'Reservas';

  @override
  String get chemistrySubsParagraph =>
      'Só o time titular conta pro Squad Chemistry. Reservas e quem entra durante a partida não geram Chemistry nem recebem bônus de Chemistry Style.';

  @override
  String get chemistryStylesIntroParagraph =>
      'Chemistry Style é um item que reforça atributos específicos de uma carta -- mas só entrega o bônus se a carta tiver Chemistry (0 de Chemistry = nenhum boost, não importa o estilo aplicado). Cada carta só pode ter um Chemistry Style ativo por vez; aplicar outro substitui o anterior.';

  @override
  String get chemistryStylesHeadingAll => 'Todos os estilos';

  @override
  String get chemistryStyleBoostsBasic =>
      'Boost equilibrado em vários atributos';

  @override
  String get chemistryStyleBestForBasic => 'Uso geral';

  @override
  String get chemistryStyleBoostsSniper => 'Finalização, Drible';

  @override
  String get chemistryStyleBestForSniper => 'Finalizadores clínicos';

  @override
  String get chemistryStyleBoostsFinisher => 'Finalização, Físico';

  @override
  String get chemistryStyleBestForFinisher => 'Atacantes de força';

  @override
  String get chemistryStyleBoostsDeadeye => 'Finalização, Passe';

  @override
  String get chemistryStyleBestForDeadeye => 'Atacantes criativos';

  @override
  String get chemistryStyleBoostsMarksman => 'Finalização, Drible, Físico';

  @override
  String get chemistryStyleBestForMarksman => 'Atacantes fortes';

  @override
  String get chemistryStyleBoostsHawk => 'Ritmo, Finalização, Físico';

  @override
  String get chemistryStyleBestForHawk => 'Atacantes rápidos';

  @override
  String get chemistryStyleBoostsArtist => 'Passe, Drible';

  @override
  String get chemistryStyleBestForArtist => 'Armadores';

  @override
  String get chemistryStyleBoostsArchitect => 'Passe, Físico';

  @override
  String get chemistryStyleBestForArchitect => 'Meias recuados';

  @override
  String get chemistryStyleBoostsPowerhouse => 'Passe, Defesa';

  @override
  String get chemistryStyleBestForPowerhouse => 'Volantes';

  @override
  String get chemistryStyleBoostsMaestro => 'Passe, Drible, Finalização';

  @override
  String get chemistryStyleBestForMaestro => 'Meias ofensivos';

  @override
  String get chemistryStyleBoostsEngine => 'Ritmo, Passe, Drible';

  @override
  String get chemistryStyleBestForEngine => 'Meias box-to-box e pontas';

  @override
  String get chemistryStyleBoostsSentinel => 'Defesa, Físico';

  @override
  String get chemistryStyleBestForSentinel => 'Zagueiros';

  @override
  String get chemistryStyleBoostsGuardian => 'Defesa, Drible';

  @override
  String get chemistryStyleBestForGuardian => 'Laterais';

  @override
  String get chemistryStyleBoostsGladiator => 'Finalização, Defesa';

  @override
  String get chemistryStyleBestForGladiator => 'Versáteis';

  @override
  String get chemistryStyleBoostsBackbone => 'Passe, Defesa, Físico';

  @override
  String get chemistryStyleBestForBackbone => 'Defensores';

  @override
  String get chemistryStyleBoostsAnchor => 'Ritmo, Defesa, Físico';

  @override
  String get chemistryStyleBestForAnchor => 'Zagueiros e volantes';

  @override
  String get chemistryStyleBoostsHunter => 'Ritmo, Finalização';

  @override
  String get chemistryStyleBestForHunter => 'Atacantes';

  @override
  String get chemistryStyleBoostsCatalyst => 'Ritmo, Passe';

  @override
  String get chemistryStyleBestForCatalyst => 'Pontas e laterais';

  @override
  String get chemistryStyleBoostsShadow => 'Ritmo, Defesa';

  @override
  String get chemistryStyleBestForShadow => 'Defensores';

  @override
  String get chemistryStyleBoostsWall =>
      'Defesa (Mergulho, Reflexos, Reposição)';

  @override
  String get chemistryStyleBestForWall => 'Goleiros';

  @override
  String get chemistryStyleBoostsShield =>
      'Defesa (Reposição, Reflexos, Velocidade)';

  @override
  String get chemistryStyleBestForShield => 'Goleiros';

  @override
  String get chemistryStyleBoostsCat =>
      'Defesa (Reflexos, Velocidade, Posicionamento)';

  @override
  String get chemistryStyleBestForCat => 'Goleiros';

  @override
  String get chemistryStyleBoostsGlove =>
      'Defesa (Elasticidade, Mergulho, Posicionamento)';

  @override
  String get chemistryStyleBestForGlove => 'Goleiros';

  @override
  String get chemistryStyleBoostsBasicGk => 'Boost equilibrado de goleiro';

  @override
  String get chemistryStyleBestForBasicGk => 'Uso geral';

  @override
  String get evolutionsIntroParagraph =>
      'Evolutions são programas de desenvolvimento pra cartas elegíveis do Ultimate Team: em vez de depender só de novas cartas promocionais, dá pra evoluir jogadores que você já tem completando uma série de desafios.';

  @override
  String get evolutionsHeadingWhatChanges => 'O que uma Evolution pode mudar';

  @override
  String get evolutionsWhatChangesBullet1 =>
      'Atributos (ritmo, finalização, passe, drible, defesa, físico ou de goleiro).';

  @override
  String get evolutionsWhatChangesBullet2 => 'PlayStyles e PlayStyles+.';

  @override
  String get evolutionsWhatChangesBullet3 =>
      'Posição, incluindo posições alternativas novas.';

  @override
  String get evolutionsWhatChangesBullet4 =>
      'Roles e a familiaridade com eles.';

  @override
  String get evolutionsWhatChangesBullet5 => 'Skill Moves e pé fraco.';

  @override
  String get evolutionsWhatChangesBullet6 =>
      'Visual da carta (design, fundo, tema).';

  @override
  String get evolutionsHeadingHowItWorks => 'Como funciona, em linhas gerais';

  @override
  String get evolutionsHowItWorksBullet1 =>
      'Cada Evolution tem requisitos de entrada (rating máximo, posição, atributos, raridade, liga, nação, PlayStyles já existentes etc.) -- nem toda carta é elegível.';

  @override
  String get evolutionsHowItWorksBullet2 =>
      'O programa é dividido em níveis; cada nível tem seus próprios desafios (jogar partidas, vencer, marcar, dar assistência, manter o gol invicto...).';

  @override
  String get evolutionsHowItWorksBullet3 =>
      'Alguns níveis oferecem mais de uma recompensa pra escolher, em vez de um único caminho fixo pra todo mundo.';

  @override
  String get evolutionsHowItWorksBullet4 =>
      'É possível remover a última Evolution aplicada (ou todas de uma vez), o que devolve o status de negociável a uma carta que tinha vindo do mercado.';

  @override
  String get evolutionsHowItWorksBullet5 =>
      'A mesma carta pode encadear várias Evolutions ao longo da temporada, desde que siga sendo elegível pra cada uma.';

  @override
  String get evolutionsHeadingWhyNoList =>
      'Por que esta tela não lista programas ativos';

  @override
  String get evolutionsWhyNoListParagraph =>
      'Os programas de Evolution mudam com frequência dentro do próprio ciclo de Ultimate Team, e não temos hoje uma fonte que acompanhe isso de forma confiável e atualizada. Preferimos explicar o conceito de verdade a mostrar uma lista estática se passando por informação ao vivo.';

  @override
  String get managersBlockedTitle => 'Ainda sem dado real';

  @override
  String get managersBlockedMessage =>
      'Hoje só existem registros de teste (nomes fictícios usados no seletor de técnico da escalação). Precisamos de uma fonte real de managers do FC 27 antes de mostrar isso como catálogo.';

  @override
  String get consumablesBlockedTitle => 'Ainda sem dado real';

  @override
  String get consumablesBlockedMessage =>
      'Chemistry Styles já tem sua própria seção em Mecânicas. Os demais consumíveis não existem no nosso catálogo hoje.';

  @override
  String get errorSquadEditConflict =>
      'Esta escalação foi alterada em outro dispositivo. Recarregue a versão mais recente antes de continuar.';

  @override
  String get errorSquadDuplicatedPlayer =>
      'O mesmo jogador não pode ocupar duas posições.';

  @override
  String get errorSquadInvalidLineup =>
      'Não foi possível salvar esta escalação.';

  @override
  String get squadSaveAction => 'Salvar';

  @override
  String get squadSavedFeedback => 'Escalação salva';

  @override
  String get squadDiscardTitle => 'Descartar alterações?';

  @override
  String get squadDiscardMessage =>
      'Existem alterações na escalação que ainda não foram salvas.';

  @override
  String get squadDiscardKeep => 'Continuar editando';

  @override
  String get squadDiscardConfirm => 'Descartar';

  @override
  String get squadReloadAction => 'Recarregar';

  @override
  String get squadChemistryUpdating => 'Recalculando…';

  @override
  String get squadChemistryUnavailable =>
      'Não foi possível recalcular a química.';

  @override
  String get squadManagerLabel => 'Técnico';

  @override
  String get squadManagerEmpty => 'Selecionar técnico';

  @override
  String get squadShareAction => 'Compartilhar escalação';

  @override
  String get squadOverallLabel => 'Overall';

  @override
  String get squadChemistryLabel => 'Química';

  @override
  String squadFormationDroppedPlayers(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count jogadores saíram da escalação: não têm posição compatível na nova formação ($names).',
      one:
          '1 jogador saiu da escalação: não tem posição compatível na nova formação ($names).',
    );
    return '$_temp0';
  }
}
