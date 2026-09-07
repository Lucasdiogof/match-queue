import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @appName.
  ///
  /// In pt, this message translates to:
  /// **'FIFA Queue'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In pt, this message translates to:
  /// **'Um de cada vez na fila.'**
  String get appTagline;

  /// No description provided for @actionContinue.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get actionContinue;

  /// No description provided for @actionCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get actionCancel;

  /// No description provided for @actionRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get actionRetry;

  /// No description provided for @actionClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get actionClose;

  /// No description provided for @actionSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get actionSave;

  /// No description provided for @actionBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get actionBack;

  /// No description provided for @actionNotNow.
  ///
  /// In pt, this message translates to:
  /// **'Agora não'**
  String get actionNotNow;

  /// No description provided for @actionSignOut.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get actionSignOut;

  /// No description provided for @navSearch.
  ///
  /// In pt, this message translates to:
  /// **'Buscar'**
  String get navSearch;

  /// No description provided for @navTeam.
  ///
  /// In pt, this message translates to:
  /// **'Time'**
  String get navTeam;

  /// No description provided for @navHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico'**
  String get navHistory;

  /// No description provided for @navProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @comingSoonTitle.
  ///
  /// In pt, this message translates to:
  /// **'Em construção'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonMessage.
  ///
  /// In pt, this message translates to:
  /// **'Esta área será construída nas próximas etapas do projeto.'**
  String get comingSoonMessage;

  /// No description provided for @comingSoonNextStage.
  ///
  /// In pt, this message translates to:
  /// **'Etapa 3'**
  String get comingSoonNextStage;

  /// No description provided for @homeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Buscar partida'**
  String get homeTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Coordene quem está procurando agora.'**
  String get homeSubtitle;

  /// No description provided for @teamTitle.
  ///
  /// In pt, this message translates to:
  /// **'Meu time'**
  String get teamTitle;

  /// No description provided for @teamSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Jogadores, cargos e convites.'**
  String get teamSubtitle;

  /// No description provided for @historyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico'**
  String get historyTitle;

  /// No description provided for @historySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Buscas, partidas encontradas e expirações.'**
  String get historySubtitle;

  /// No description provided for @profileTitle.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Conta, aparência e idioma.'**
  String get profileSubtitle;

  /// No description provided for @authSignIn.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get authSignUp;

  /// No description provided for @authForgotPassword.
  ///
  /// In pt, this message translates to:
  /// **'Esqueci minha senha'**
  String get authForgotPassword;

  /// No description provided for @authEmail.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get authPassword;

  /// No description provided for @authRevealPassword.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar senha'**
  String get authRevealPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar senha'**
  String get authHidePassword;

  /// No description provided for @authSignedInAs.
  ///
  /// In pt, this message translates to:
  /// **'Conectado como {email}'**
  String authSignedInAs(String email);

  /// No description provided for @settingsAppearance.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get settingsAppearance;

  /// No description provided for @settingsLanguage.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// No description provided for @themeSystem.
  ///
  /// In pt, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get themeDark;

  /// No description provided for @languageSystem.
  ///
  /// In pt, this message translates to:
  /// **'Idioma do dispositivo'**
  String get languageSystem;

  /// No description provided for @languagePortuguese.
  ///
  /// In pt, this message translates to:
  /// **'Português (Brasil)'**
  String get languagePortuguese;

  /// No description provided for @languageEnglish.
  ///
  /// In pt, this message translates to:
  /// **'Inglês'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In pt, this message translates to:
  /// **'Espanhol'**
  String get languageSpanish;

  /// No description provided for @inviteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Você foi convidado para'**
  String get inviteTitle;

  /// No description provided for @inviteJoinTeam.
  ///
  /// In pt, this message translates to:
  /// **'Entrar no time'**
  String get inviteJoinTeam;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Código do convite: {code}'**
  String inviteCodeLabel(String code);

  /// No description provided for @inviteSignInRequiredTitle.
  ///
  /// In pt, this message translates to:
  /// **'Entre para aceitar o convite'**
  String get inviteSignInRequiredTitle;

  /// No description provided for @inviteSignInRequiredMessage.
  ///
  /// In pt, this message translates to:
  /// **'Guardamos este convite. Assim que você entrar, ele será retomado automaticamente.'**
  String get inviteSignInRequiredMessage;

  /// No description provided for @invitePendingRestored.
  ///
  /// In pt, this message translates to:
  /// **'Convite pendente retomado.'**
  String get invitePendingRestored;

  /// No description provided for @inviteResolutionComingSoon.
  ///
  /// In pt, this message translates to:
  /// **'A entrada no time será implementada na próxima etapa.'**
  String get inviteResolutionComingSoon;

  /// No description provided for @invitePlayersCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Nenhum jogador} =1{1 jogador} other{{count} jogadores}}'**
  String invitePlayersCount(int count);

  /// No description provided for @inviteReceivedAt.
  ///
  /// In pt, this message translates to:
  /// **'Convite recebido em {date}'**
  String inviteReceivedAt(DateTime date);

  /// No description provided for @queuePositionLabel.
  ///
  /// In pt, this message translates to:
  /// **'#{position} na fila'**
  String queuePositionLabel(int position);

  /// No description provided for @errorNetwork.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão. Verifique sua internet e tente novamente.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In pt, this message translates to:
  /// **'A operação demorou demais. Tente novamente.'**
  String get errorTimeout;

  /// No description provided for @errorServer.
  ///
  /// In pt, this message translates to:
  /// **'Algo deu errado no servidor. Tente novamente em instantes.'**
  String get errorServer;

  /// No description provided for @errorPermission.
  ///
  /// In pt, this message translates to:
  /// **'Você não tem permissão para fazer isso.'**
  String get errorPermission;

  /// No description provided for @errorNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Não encontramos o que você procurava.'**
  String get errorNotFound;

  /// No description provided for @errorConflict.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação conflita com o estado atual. Atualize e tente de novo.'**
  String get errorConflict;

  /// No description provided for @errorUnexpected.
  ///
  /// In pt, this message translates to:
  /// **'Erro inesperado. Tente novamente.'**
  String get errorUnexpected;

  /// No description provided for @errorConfiguration.
  ///
  /// In pt, this message translates to:
  /// **'Configuração ausente: {keys}'**
  String errorConfiguration(String keys);

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In pt, this message translates to:
  /// **'E-mail ou senha incorretos.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailAlreadyRegistered.
  ///
  /// In pt, this message translates to:
  /// **'Este e-mail já está cadastrado.'**
  String get errorEmailAlreadyRegistered;

  /// No description provided for @errorWeakPassword.
  ///
  /// In pt, this message translates to:
  /// **'Escolha uma senha mais forte.'**
  String get errorWeakPassword;

  /// No description provided for @errorUserNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Conta não encontrada.'**
  String get errorUserNotFound;

  /// No description provided for @errorSessionExpired.
  ///
  /// In pt, this message translates to:
  /// **'Sua sessão expirou. Entre novamente.'**
  String get errorSessionExpired;

  /// No description provided for @errorEmailConfirmationRequired.
  ///
  /// In pt, this message translates to:
  /// **'Enviamos um link de confirmação para o seu e-mail. Confirme o endereço para entrar.'**
  String get errorEmailConfirmationRequired;

  /// No description provided for @errorAuthUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir a autenticação.'**
  String get errorAuthUnknown;

  /// No description provided for @startupErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível iniciar o FIFA Queue'**
  String get startupErrorTitle;

  /// No description provided for @startupErrorMessage.
  ///
  /// In pt, this message translates to:
  /// **'Faltam variáveis de ambiente obrigatórias: {keys}'**
  String startupErrorMessage(String keys);

  /// No description provided for @environmentBadge.
  ///
  /// In pt, this message translates to:
  /// **'Ambiente: {environment}'**
  String environmentBadge(String environment);

  /// No description provided for @notFoundTitle.
  ///
  /// In pt, this message translates to:
  /// **'Página não encontrada'**
  String get notFoundTitle;

  /// No description provided for @notFoundMessage.
  ///
  /// In pt, this message translates to:
  /// **'O endereço acessado não existe neste aplicativo.'**
  String get notFoundMessage;

  /// No description provided for @notFoundAction.
  ///
  /// In pt, this message translates to:
  /// **'Ir para o início'**
  String get notFoundAction;

  /// No description provided for @loginTitle.
  ///
  /// In pt, this message translates to:
  /// **'Entre na sua conta'**
  String get loginTitle;

  /// No description provided for @loginNoAccount.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não tem uma conta?'**
  String get loginNoAccount;

  /// No description provided for @loginLocalModeBadge.
  ///
  /// In pt, this message translates to:
  /// **'Modo local'**
  String get loginLocalModeBadge;

  /// No description provided for @loginLocalModeMessage.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum projeto Supabase configurado. As contas criadas aqui existem só neste dispositivo.'**
  String get loginLocalModeMessage;

  /// No description provided for @signUpTitle.
  ///
  /// In pt, this message translates to:
  /// **'Crie sua conta'**
  String get signUpTitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha como o seu time vai te chamar.'**
  String get signUpSubtitle;

  /// No description provided for @signUpHaveAccount.
  ///
  /// In pt, this message translates to:
  /// **'Já tem uma conta?'**
  String get signUpHaveAccount;

  /// No description provided for @authDisplayName.
  ///
  /// In pt, this message translates to:
  /// **'Nome ou apelido'**
  String get authDisplayName;

  /// No description provided for @authDisplayNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Lucas, ratowrld, Panda...'**
  String get authDisplayNameHint;

  /// No description provided for @authEmailHint.
  ///
  /// In pt, this message translates to:
  /// **'voce@exemplo.com'**
  String get authEmailHint;

  /// No description provided for @authConfirmPassword.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar senha'**
  String get authConfirmPassword;

  /// No description provided for @authPasswordHelper.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo de {count} caracteres'**
  String authPasswordHelper(int count);

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Recuperar acesso'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordMessage.
  ///
  /// In pt, this message translates to:
  /// **'Informe o e-mail da sua conta e enviaremos o link para criar uma nova senha.'**
  String get forgotPasswordMessage;

  /// No description provided for @forgotPasswordAction.
  ///
  /// In pt, this message translates to:
  /// **'Enviar instruções'**
  String get forgotPasswordAction;

  /// No description provided for @forgotPasswordSentTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confira seu e-mail'**
  String get forgotPasswordSentTitle;

  /// No description provided for @forgotPasswordSentMessage.
  ///
  /// In pt, this message translates to:
  /// **'Se houver uma conta associada a este e-mail, você vai receber as instruções para redefinir a senha.'**
  String get forgotPasswordSentMessage;

  /// No description provided for @forgotPasswordBackToLogin.
  ///
  /// In pt, this message translates to:
  /// **'Voltar para o login'**
  String get forgotPasswordBackToLogin;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Definir nova senha'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordMessage.
  ///
  /// In pt, this message translates to:
  /// **'Escolha uma nova senha para voltar a usar o FIFA Queue.'**
  String get resetPasswordMessage;

  /// No description provided for @resetPasswordNewPassword.
  ///
  /// In pt, this message translates to:
  /// **'Nova senha'**
  String get resetPasswordNewPassword;

  /// No description provided for @resetPasswordAction.
  ///
  /// In pt, this message translates to:
  /// **'Salvar nova senha'**
  String get resetPasswordAction;

  /// No description provided for @resetPasswordSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Senha atualizada. Bem-vindo de volta.'**
  String get resetPasswordSuccess;

  /// No description provided for @resetPasswordInvalidTitle.
  ///
  /// In pt, this message translates to:
  /// **'Link expirado ou inválido'**
  String get resetPasswordInvalidTitle;

  /// No description provided for @resetPasswordInvalidMessage.
  ///
  /// In pt, this message translates to:
  /// **'Peça um novo link de recuperação para definir sua senha.'**
  String get resetPasswordInvalidMessage;

  /// No description provided for @validationEmailRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu e-mail.'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Informe um e-mail válido.'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe sua senha.'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In pt, this message translates to:
  /// **'A senha precisa ter pelo menos {count} caracteres.'**
  String validationPasswordTooShort(int count);

  /// No description provided for @validationPasswordConfirmationRequired.
  ///
  /// In pt, this message translates to:
  /// **'Confirme sua senha.'**
  String get validationPasswordConfirmationRequired;

  /// No description provided for @validationPasswordConfirmationMismatch.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem.'**
  String get validationPasswordConfirmationMismatch;

  /// No description provided for @validationDisplayNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe um nome ou apelido.'**
  String get validationDisplayNameRequired;

  /// No description provided for @validationDisplayNameTooShort.
  ///
  /// In pt, this message translates to:
  /// **'Use pelo menos {count} caracteres.'**
  String validationDisplayNameTooShort(int count);

  /// No description provided for @validationDisplayNameTooLong.
  ///
  /// In pt, this message translates to:
  /// **'Use no máximo {count} caracteres.'**
  String validationDisplayNameTooLong(int count);

  /// No description provided for @errorTooManyRequests.
  ///
  /// In pt, this message translates to:
  /// **'Muitas tentativas. Espere um instante e tente de novo.'**
  String get errorTooManyRequests;

  /// No description provided for @errorSignUpFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível criar sua conta.'**
  String get errorSignUpFailed;

  /// No description provided for @homeGreeting.
  ///
  /// In pt, this message translates to:
  /// **'Olá, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeSearchPlaceholderTitle.
  ///
  /// In pt, this message translates to:
  /// **'A busca coordenada chega na Etapa 3'**
  String get homeSearchPlaceholderTitle;

  /// No description provided for @homeSearchPlaceholderMessage.
  ///
  /// In pt, this message translates to:
  /// **'Primeiro vamos criar times e membros. Depois disso, só um jogador do time procura partida por vez.'**
  String get homeSearchPlaceholderMessage;

  /// No description provided for @profileAccountSection.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get profileAccountSection;

  /// No description provided for @profileDisplayNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome ou apelido'**
  String get profileDisplayNameLabel;

  /// No description provided for @profileEmailLabel.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get profileEmailLabel;

  /// No description provided for @profileEditName.
  ///
  /// In pt, this message translates to:
  /// **'Editar nome'**
  String get profileEditName;

  /// No description provided for @profileEditNameTitle.
  ///
  /// In pt, this message translates to:
  /// **'Como podemos te chamar?'**
  String get profileEditNameTitle;

  /// No description provided for @profileDisplayNameCounter.
  ///
  /// In pt, this message translates to:
  /// **'{count}/{max}'**
  String profileDisplayNameCounter(int count, int max);

  /// No description provided for @profileSaved.
  ///
  /// In pt, this message translates to:
  /// **'Nome atualizado.'**
  String get profileSaved;

  /// No description provided for @profileLoadErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar seu perfil'**
  String get profileLoadErrorTitle;

  /// No description provided for @profileMemberSince.
  ///
  /// In pt, this message translates to:
  /// **'No FIFA Queue desde {date}'**
  String profileMemberSince(DateTime date);

  /// No description provided for @teamNoTeamTitle.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não faz parte de um time'**
  String get teamNoTeamTitle;

  /// No description provided for @teamNoTeamMessage.
  ///
  /// In pt, this message translates to:
  /// **'Crie o seu time ou entre com um código de convite para começar.'**
  String get teamNoTeamMessage;

  /// No description provided for @teamCreateCta.
  ///
  /// In pt, this message translates to:
  /// **'Criar time'**
  String get teamCreateCta;

  /// No description provided for @teamHaveInviteCode.
  ///
  /// In pt, this message translates to:
  /// **'Tenho um código de convite'**
  String get teamHaveInviteCode;

  /// No description provided for @teamInviteComingSoonTitle.
  ///
  /// In pt, this message translates to:
  /// **'Convites chegam na próxima etapa'**
  String get teamInviteComingSoonTitle;

  /// No description provided for @teamInviteComingSoonMessage.
  ///
  /// In pt, this message translates to:
  /// **'A entrada por link e código será liberada em breve. Por enquanto, crie um time para começar.'**
  String get teamInviteComingSoonMessage;

  /// No description provided for @teamCreateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Crie seu time'**
  String get teamCreateTitle;

  /// No description provided for @teamCreateSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Dá para ajustar cores, logo e duração da busca depois.'**
  String get teamCreateSubtitle;

  /// No description provided for @teamNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do time'**
  String get teamNameLabel;

  /// No description provided for @teamNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Falcons FC'**
  String get teamNameHint;

  /// No description provided for @teamTagLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tag (opcional)'**
  String get teamTagLabel;

  /// No description provided for @teamTagHint.
  ///
  /// In pt, this message translates to:
  /// **'FLC'**
  String get teamTagHint;

  /// No description provided for @teamTagHelper.
  ///
  /// In pt, this message translates to:
  /// **'2 a 6 letras ou números'**
  String get teamTagHelper;

  /// No description provided for @teamCreateAction.
  ///
  /// In pt, this message translates to:
  /// **'Criar time'**
  String get teamCreateAction;

  /// No description provided for @teamCreateAnother.
  ///
  /// In pt, this message translates to:
  /// **'Criar outro time'**
  String get teamCreateAnother;

  /// No description provided for @teamMembersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Membros'**
  String get teamMembersTitle;

  /// No description provided for @teamMembersCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Nenhum jogador} =1{1 jogador} other{{count} jogadores}}'**
  String teamMembersCount(int count);

  /// No description provided for @teamRoleOwner.
  ///
  /// In pt, this message translates to:
  /// **'Dono'**
  String get teamRoleOwner;

  /// No description provided for @teamRoleAdmin.
  ///
  /// In pt, this message translates to:
  /// **'Admin'**
  String get teamRoleAdmin;

  /// No description provided for @teamRolePlayer.
  ///
  /// In pt, this message translates to:
  /// **'Jogador'**
  String get teamRolePlayer;

  /// No description provided for @teamYou.
  ///
  /// In pt, this message translates to:
  /// **'Você'**
  String get teamYou;

  /// No description provided for @teamManageAction.
  ///
  /// In pt, this message translates to:
  /// **'Configurações do time'**
  String get teamManageAction;

  /// No description provided for @teamEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar time'**
  String get teamEditTitle;

  /// No description provided for @teamInvitePlayers.
  ///
  /// In pt, this message translates to:
  /// **'Convidar jogadores'**
  String get teamInvitePlayers;

  /// No description provided for @teamInvitePlayersHint.
  ///
  /// In pt, this message translates to:
  /// **'Disponível na próxima etapa.'**
  String get teamInvitePlayersHint;

  /// No description provided for @teamSwitchTitle.
  ///
  /// In pt, this message translates to:
  /// **'Seus times'**
  String get teamSwitchTitle;

  /// No description provided for @teamSwitchAction.
  ///
  /// In pt, this message translates to:
  /// **'Trocar de time'**
  String get teamSwitchAction;

  /// No description provided for @teamNoActiveSearchTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma busca ativa'**
  String get teamNoActiveSearchTitle;

  /// No description provided for @teamNoActiveSearchMessage.
  ///
  /// In pt, this message translates to:
  /// **'A fila de partidas chega em breve. Aqui é onde o time vai coordenar quem procura agora.'**
  String get teamNoActiveSearchMessage;

  /// No description provided for @teamSearchDurationLabel.
  ///
  /// In pt, this message translates to:
  /// **'Duração padrão da busca'**
  String get teamSearchDurationLabel;

  /// No description provided for @teamSearchDurationHelper.
  ///
  /// In pt, this message translates to:
  /// **'Tempo que cada jogador fica na frente da fila.'**
  String get teamSearchDurationHelper;

  /// No description provided for @teamDurationSeconds.
  ///
  /// In pt, this message translates to:
  /// **'{seconds} s'**
  String teamDurationSeconds(int seconds);

  /// No description provided for @teamDurationMinutes.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 min} other{{count} min}}'**
  String teamDurationMinutes(int count);

  /// No description provided for @teamLoadErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar seus times'**
  String get teamLoadErrorTitle;

  /// No description provided for @teamMembersErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os membros'**
  String get teamMembersErrorTitle;

  /// No description provided for @validationTeamNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o nome do time.'**
  String get validationTeamNameRequired;

  /// No description provided for @validationTeamNameTooShort.
  ///
  /// In pt, this message translates to:
  /// **'Use pelo menos {count} caracteres.'**
  String validationTeamNameTooShort(int count);

  /// No description provided for @validationTeamNameTooLong.
  ///
  /// In pt, this message translates to:
  /// **'Use no máximo {count} caracteres.'**
  String validationTeamNameTooLong(int count);

  /// No description provided for @validationTeamTagTooShort.
  ///
  /// In pt, this message translates to:
  /// **'A tag precisa ter pelo menos {count} caracteres.'**
  String validationTeamTagTooShort(int count);

  /// No description provided for @validationTeamTagTooLong.
  ///
  /// In pt, this message translates to:
  /// **'A tag pode ter no máximo {count} caracteres.'**
  String validationTeamTagTooLong(int count);

  /// No description provided for @validationTeamTagInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Use apenas letras e números.'**
  String get validationTeamTagInvalid;

  /// No description provided for @errorTeamNameInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um nome de time válido.'**
  String get errorTeamNameInvalid;

  /// No description provided for @errorTeamTagInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Escolha uma tag válida.'**
  String get errorTeamTagInvalid;

  /// No description provided for @errorTeamSearchDurationInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Escolha uma duração de busca válida.'**
  String get errorTeamSearchDurationInvalid;

  /// No description provided for @errorTeamNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Time não encontrado.'**
  String get errorTeamNotFound;

  /// No description provided for @errorTeamPermissionDenied.
  ///
  /// In pt, this message translates to:
  /// **'Você não tem permissão para gerenciar este time.'**
  String get errorTeamPermissionDenied;

  /// No description provided for @errorTeamProfileMissing.
  ///
  /// In pt, this message translates to:
  /// **'Finalize seu perfil antes de criar um time.'**
  String get errorTeamProfileMissing;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
