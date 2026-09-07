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
  String comingSoonStage(String stage) {
    return 'Previsto para a $stage';
  }

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
  String get authWelcomeTitle => 'Entre para coordenar seu time';

  @override
  String get authWelcomeMessage =>
      'As telas de autenticação serão construídas na próxima etapa. A arquitetura de auth já está pronta.';

  @override
  String get authLocalModeTitle => 'Modo local de desenvolvimento';

  @override
  String get authLocalModeMessage =>
      'Nenhum projeto Supabase foi configurado. Você pode entrar com uma sessão local para navegar pela estrutura do app.';

  @override
  String get authLocalModeAction => 'Entrar em modo local';

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
}
