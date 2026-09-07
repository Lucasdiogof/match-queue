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
  String get inviteTitle => 'Você foi convidado para';

  @override
  String get inviteJoinTeam => 'Entrar no time';

  @override
  String inviteCodeLabel(String code) {
    return 'Código do convite: $code';
  }

  @override
  String get inviteSignInRequiredTitle => 'Entre para aceitar o convite';

  @override
  String get inviteSignInRequiredMessage =>
      'Guardamos este convite. Assim que você entrar, ele será retomado automaticamente.';

  @override
  String get invitePendingRestored => 'Convite pendente retomado.';

  @override
  String get inviteResolutionComingSoon =>
      'A entrada no time será implementada na próxima etapa.';

  @override
  String invitePlayersCount(int count) {
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
  String inviteReceivedAt(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Convite recebido em $dateString';
  }

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
  String get loginLocalModeBadge => 'Modo local';

  @override
  String get loginLocalModeMessage =>
      'Nenhum projeto Supabase configurado. As contas criadas aqui existem só neste dispositivo.';

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
}
