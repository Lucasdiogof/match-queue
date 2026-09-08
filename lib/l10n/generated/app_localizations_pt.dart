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
  String get navSearch => 'Buscar';

  @override
  String get navTeam => 'Time';

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
  String get homeTitle => 'Buscar partida';

  @override
  String get homeSubtitle => 'Coordene quem está procurando agora.';

  @override
  String get teamTitle => 'Meu time';

  @override
  String get teamSubtitle => 'Jogadores, cargos e convites.';

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
  String get teamCreateCta => 'Criar time';

  @override
  String get teamHaveInviteCode => 'Tenho um código de convite';

  @override
  String get teamCreateTitle => 'Crie seu time';

  @override
  String get teamCreateSubtitle =>
      'Dá para ajustar cores, logo e duração da busca depois.';

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
  String get teamSearchDurationLabel => 'Duração padrão da busca';

  @override
  String get teamSearchDurationHelper =>
      'Tempo que cada jogador fica na frente da fila.';

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
  String get matchmakingIdleTitle => 'Ninguém está buscando partida';

  @override
  String get matchmakingIdleMessage =>
      'Toque em buscar partida para começar. O time inteiro vê assim que alguém entra na fila.';

  @override
  String get matchmakingSearchAction => 'Buscar partida';

  @override
  String get matchmakingJoinQueueAction => 'Entrar na fila';

  @override
  String get matchmakingCancelAction => 'Cancelar busca';

  @override
  String get matchmakingLeaveQueueAction => 'Sair da fila';

  @override
  String get matchmakingMatchFoundAction => 'Partida encontrada';

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
}
