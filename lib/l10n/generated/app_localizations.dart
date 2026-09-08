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

  /// No description provided for @actionCopy.
  ///
  /// In pt, this message translates to:
  /// **'Copiar'**
  String get actionCopy;

  /// No description provided for @actionShare.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar'**
  String get actionShare;

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

  /// No description provided for @actionEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get actionEdit;

  /// No description provided for @navSearch.
  ///
  /// In pt, this message translates to:
  /// **'Jogar'**
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

  /// No description provided for @profilePreferencesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Preferências'**
  String get profilePreferencesTitle;

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

  /// No description provided for @inviteJoinTeam.
  ///
  /// In pt, this message translates to:
  /// **'Entrar no time'**
  String get inviteJoinTeam;

  /// No description provided for @inviteOpenTeam.
  ///
  /// In pt, this message translates to:
  /// **'Abrir time'**
  String get inviteOpenTeam;

  /// No description provided for @inviteJoinMessage.
  ///
  /// In pt, this message translates to:
  /// **'Você foi convidado para entrar neste time.'**
  String get inviteJoinMessage;

  /// No description provided for @inviteAlreadyMemberMessage.
  ///
  /// In pt, this message translates to:
  /// **'Você já faz parte deste time.'**
  String get inviteAlreadyMemberMessage;

  /// No description provided for @inviteSignInToAccept.
  ///
  /// In pt, this message translates to:
  /// **'Entrar para aceitar'**
  String get inviteSignInToAccept;

  /// No description provided for @inviteCreateAccount.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get inviteCreateAccount;

  /// No description provided for @inviteInvalidTitle.
  ///
  /// In pt, this message translates to:
  /// **'Convite não encontrado'**
  String get inviteInvalidTitle;

  /// No description provided for @inviteRevokedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Este link não está mais ativo'**
  String get inviteRevokedTitle;

  /// No description provided for @inviteExpiredTitle.
  ///
  /// In pt, this message translates to:
  /// **'Este link expirou'**
  String get inviteExpiredTitle;

  /// No description provided for @inviteExhaustedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Este link atingiu o limite de usos'**
  String get inviteExhaustedTitle;

  /// No description provided for @inviteEnterCodeMessage.
  ///
  /// In pt, this message translates to:
  /// **'Cole ou digite o código que você recebeu.'**
  String get inviteEnterCodeMessage;

  /// No description provided for @inviteCodeFieldLabel.
  ///
  /// In pt, this message translates to:
  /// **'Código do convite'**
  String get inviteCodeFieldLabel;

  /// No description provided for @inviteCodeFieldInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Código inválido.'**
  String get inviteCodeFieldInvalid;

  /// No description provided for @inviteSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Convidar jogadores'**
  String get inviteSectionTitle;

  /// No description provided for @inviteSectionSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhe este link com quem você quer adicionar ao time.'**
  String get inviteSectionSubtitle;

  /// No description provided for @inviteLinkCopied.
  ///
  /// In pt, this message translates to:
  /// **'Link copiado.'**
  String get inviteLinkCopied;

  /// No description provided for @inviteShareSubject.
  ///
  /// In pt, this message translates to:
  /// **'Convite para o time no FIFA Queue'**
  String get inviteShareSubject;

  /// No description provided for @inviteShareMessage.
  ///
  /// In pt, this message translates to:
  /// **'Entre no meu time pelo FIFA Queue: {url}'**
  String inviteShareMessage(String url);

  /// No description provided for @inviteShareMessageCodeOnly.
  ///
  /// In pt, this message translates to:
  /// **'Entre no meu time pelo FIFA Queue com o código: {code}'**
  String inviteShareMessageCodeOnly(String code);

  /// No description provided for @inviteManageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar link'**
  String get inviteManageTitle;

  /// No description provided for @inviteCreateLinkAction.
  ///
  /// In pt, this message translates to:
  /// **'Criar link de convite'**
  String get inviteCreateLinkAction;

  /// No description provided for @inviteUnavailableMessage.
  ///
  /// In pt, this message translates to:
  /// **'O link de convite deste time ainda não está disponível.'**
  String get inviteUnavailableMessage;

  /// No description provided for @inviteRotateAction.
  ///
  /// In pt, this message translates to:
  /// **'Gerar novo link'**
  String get inviteRotateAction;

  /// No description provided for @inviteRotateConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gerar um novo link?'**
  String get inviteRotateConfirmTitle;

  /// No description provided for @inviteRotateConfirmMessage.
  ///
  /// In pt, this message translates to:
  /// **'O link atual deixará de funcionar imediatamente.'**
  String get inviteRotateConfirmMessage;

  /// No description provided for @inviteRevokeAction.
  ///
  /// In pt, this message translates to:
  /// **'Desativar link'**
  String get inviteRevokeAction;

  /// No description provided for @inviteRevokeConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Desativar link?'**
  String get inviteRevokeConfirmTitle;

  /// No description provided for @inviteRevokeConfirmMessage.
  ///
  /// In pt, this message translates to:
  /// **'Ninguém poderá entrar no time usando o link atual.'**
  String get inviteRevokeConfirmMessage;

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

  /// No description provided for @forgotPasswordResend.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar'**
  String get forgotPasswordResend;

  /// No description provided for @forgotPasswordNotReceived.
  ///
  /// In pt, this message translates to:
  /// **'Não recebeu o e-mail?'**
  String get forgotPasswordNotReceived;

  /// No description provided for @forgotPasswordResending.
  ///
  /// In pt, this message translates to:
  /// **'Reenviando...'**
  String get forgotPasswordResending;

  /// No description provided for @forgotPasswordResendSuccess.
  ///
  /// In pt, this message translates to:
  /// **'E-mail reenviado.'**
  String get forgotPasswordResendSuccess;

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

  /// No description provided for @teamActiveCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 ativos} =1{1 ativo} other{{count} ativos}}'**
  String teamActiveCount(int count);

  /// No description provided for @teamSettingsInfoTitle.
  ///
  /// In pt, this message translates to:
  /// **'Informações'**
  String get teamSettingsInfoTitle;

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

  /// No description provided for @teamSearchDurationReadOnlyHelper.
  ///
  /// In pt, this message translates to:
  /// **'Só o dono ou um admin pode alterar.'**
  String get teamSearchDurationReadOnlyHelper;

  /// No description provided for @teamStatusInMatch.
  ///
  /// In pt, this message translates to:
  /// **'Em jogo'**
  String get teamStatusInMatch;

  /// No description provided for @teamStatusSearching.
  ///
  /// In pt, this message translates to:
  /// **'Buscando'**
  String get teamStatusSearching;

  /// No description provided for @teamStatusQueued.
  ///
  /// In pt, this message translates to:
  /// **'Na fila'**
  String get teamStatusQueued;

  /// No description provided for @teamStatusQueuedWithPosition.
  ///
  /// In pt, this message translates to:
  /// **'Na fila · #{position}'**
  String teamStatusQueuedWithPosition(int position);

  /// No description provided for @teamStatusOffline.
  ///
  /// In pt, this message translates to:
  /// **'Offline'**
  String get teamStatusOffline;

  /// No description provided for @teamStatusActiveNow.
  ///
  /// In pt, this message translates to:
  /// **'Ativo agora'**
  String get teamStatusActiveNow;

  /// No description provided for @teamStatusActiveMinutesAgo.
  ///
  /// In pt, this message translates to:
  /// **'Há {minutes} min'**
  String teamStatusActiveMinutesAgo(int minutes);

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

  /// No description provided for @errorInviteNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Convite não encontrado.'**
  String get errorInviteNotFound;

  /// No description provided for @errorInviteNotActive.
  ///
  /// In pt, this message translates to:
  /// **'Este convite não é mais válido.'**
  String get errorInviteNotActive;

  /// No description provided for @errorInviteExpired.
  ///
  /// In pt, this message translates to:
  /// **'Este convite expirou.'**
  String get errorInviteExpired;

  /// No description provided for @errorInviteExhausted.
  ///
  /// In pt, this message translates to:
  /// **'Este convite atingiu o limite de usos.'**
  String get errorInviteExhausted;

  /// No description provided for @errorInviteGenerationFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível gerar o link de convite. Tente novamente.'**
  String get errorInviteGenerationFailed;

  /// No description provided for @errorInvitePermissionDenied.
  ///
  /// In pt, this message translates to:
  /// **'Você não tem permissão para gerenciar o convite deste time.'**
  String get errorInvitePermissionDenied;

  /// No description provided for @errorMatchmakingNoActiveSearch.
  ///
  /// In pt, this message translates to:
  /// **'Não há busca ativa no momento.'**
  String get errorMatchmakingNoActiveSearch;

  /// No description provided for @errorMatchmakingNotCurrentSearcher.
  ///
  /// In pt, this message translates to:
  /// **'Você não é mais quem está buscando partida.'**
  String get errorMatchmakingNotCurrentSearcher;

  /// No description provided for @errorMatchmakingAlreadyInOtherState.
  ///
  /// In pt, this message translates to:
  /// **'Você já está em outro estado da fila.'**
  String get errorMatchmakingAlreadyInOtherState;

  /// No description provided for @errorMatchmakingTeamInactive.
  ///
  /// In pt, this message translates to:
  /// **'Este time está inativo no momento.'**
  String get errorMatchmakingTeamInactive;

  /// No description provided for @errorGameCooldown.
  ///
  /// In pt, this message translates to:
  /// **'Espere um pouco antes de buscar de novo.'**
  String get errorGameCooldown;

  /// No description provided for @errorGameMatchNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Partida não encontrada.'**
  String get errorGameMatchNotFound;

  /// No description provided for @errorGameMatchAlreadyFinished.
  ///
  /// In pt, this message translates to:
  /// **'Esta partida já foi finalizada.'**
  String get errorGameMatchAlreadyFinished;

  /// No description provided for @errorGameInvalidMode.
  ///
  /// In pt, this message translates to:
  /// **'Modo de jogo inválido.'**
  String get errorGameInvalidMode;

  /// No description provided for @errorGameInvalidResult.
  ///
  /// In pt, this message translates to:
  /// **'Informe um resultado ou um placar sem empate.'**
  String get errorGameInvalidResult;

  /// No description provided for @matchmakingIdleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ninguém está buscando partida'**
  String get matchmakingIdleTitle;

  /// No description provided for @matchmakingIdleMessage.
  ///
  /// In pt, this message translates to:
  /// **'Toque em buscar partida para começar. O time inteiro vê assim que alguém entra na fila.'**
  String get matchmakingIdleMessage;

  /// No description provided for @matchmakingSearchAction.
  ///
  /// In pt, this message translates to:
  /// **'Buscar partida'**
  String get matchmakingSearchAction;

  /// No description provided for @matchmakingJoinQueueAction.
  ///
  /// In pt, this message translates to:
  /// **'Entrar na fila'**
  String get matchmakingJoinQueueAction;

  /// No description provided for @matchmakingCancelAction.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get matchmakingCancelAction;

  /// No description provided for @matchmakingLeaveQueueAction.
  ///
  /// In pt, this message translates to:
  /// **'Sair da fila'**
  String get matchmakingLeaveQueueAction;

  /// No description provided for @matchmakingMatchFoundAction.
  ///
  /// In pt, this message translates to:
  /// **'Encontrei'**
  String get matchmakingMatchFoundAction;

  /// No description provided for @matchmakingSearchingSelfTitle.
  ///
  /// In pt, this message translates to:
  /// **'Buscando partida'**
  String get matchmakingSearchingSelfTitle;

  /// No description provided for @matchmakingSearchingSelfMessage.
  ///
  /// In pt, this message translates to:
  /// **'Assim que a partida começar, toque em partida encontrada.'**
  String get matchmakingSearchingSelfMessage;

  /// No description provided for @matchmakingSearchingOtherTitle.
  ///
  /// In pt, this message translates to:
  /// **'{name} está buscando partida'**
  String matchmakingSearchingOtherTitle(String name);

  /// No description provided for @matchmakingQueuePositionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Posição {position} na fila'**
  String matchmakingQueuePositionLabel(int position);

  /// No description provided for @matchmakingQueueSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Fila de espera'**
  String get matchmakingQueueSectionTitle;

  /// No description provided for @matchmakingQueueEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Ninguém na fila.'**
  String get matchmakingQueueEmptyMessage;

  /// No description provided for @matchmakingYouBadge.
  ///
  /// In pt, this message translates to:
  /// **'Você'**
  String get matchmakingYouBadge;

  /// No description provided for @matchmakingCancelConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar busca?'**
  String get matchmakingCancelConfirmTitle;

  /// No description provided for @matchmakingCancelConfirmMessage.
  ///
  /// In pt, this message translates to:
  /// **'Você vai perder sua posição na busca atual.'**
  String get matchmakingCancelConfirmMessage;

  /// No description provided for @matchmakingYourTurnTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sua vez de buscar!'**
  String get matchmakingYourTurnTitle;

  /// No description provided for @matchmakingReconnecting.
  ///
  /// In pt, this message translates to:
  /// **'Reconectando…'**
  String get matchmakingReconnecting;

  /// No description provided for @notificationsSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get notificationsSectionTitle;

  /// No description provided for @notificationsToggleYourTurn.
  ///
  /// In pt, this message translates to:
  /// **'Sua vez de buscar'**
  String get notificationsToggleYourTurn;

  /// No description provided for @notificationsToggleYourTurnHint.
  ///
  /// In pt, this message translates to:
  /// **'Quando chegar a sua vez na fila do time.'**
  String get notificationsToggleYourTurnHint;

  /// No description provided for @notificationsToggleExpiring.
  ///
  /// In pt, this message translates to:
  /// **'30 segundos restantes'**
  String get notificationsToggleExpiring;

  /// No description provided for @notificationsToggleExpiringHint.
  ///
  /// In pt, this message translates to:
  /// **'Um aviso antes de a sua busca expirar.'**
  String get notificationsToggleExpiringHint;

  /// No description provided for @notificationsToggleExpired.
  ///
  /// In pt, this message translates to:
  /// **'Tempo de busca encerrado'**
  String get notificationsToggleExpired;

  /// No description provided for @notificationsToggleExpiredHint.
  ///
  /// In pt, this message translates to:
  /// **'Quando a sua busca termina sem partida.'**
  String get notificationsToggleExpiredHint;

  /// No description provided for @notificationsEnableCta.
  ///
  /// In pt, this message translates to:
  /// **'Ativar notificações'**
  String get notificationsEnableCta;

  /// No description provided for @notificationsPermissionDeniedHint.
  ///
  /// In pt, this message translates to:
  /// **'As notificações estão bloqueadas. Ative-as nas configurações do sistema.'**
  String get notificationsPermissionDeniedHint;

  /// No description provided for @notificationsUnsupportedHint.
  ///
  /// In pt, this message translates to:
  /// **'Este dispositivo ainda não recebe notificações push.'**
  String get notificationsUnsupportedHint;

  /// No description provided for @notificationsEnableTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não perca a sua vez'**
  String get notificationsEnableTitle;

  /// No description provided for @notificationsEnableMessage.
  ///
  /// In pt, this message translates to:
  /// **'Ative as notificações para saber na hora quando for a sua vez de buscar partida — mesmo com o app fechado.'**
  String get notificationsEnableMessage;

  /// No description provided for @notificationsChannelQueueAlertsName.
  ///
  /// In pt, this message translates to:
  /// **'Alertas da fila'**
  String get notificationsChannelQueueAlertsName;

  /// No description provided for @notificationsChannelQueueAlertsDescription.
  ///
  /// In pt, this message translates to:
  /// **'Avisos sobre a sua vez de buscar e o andamento da sua busca.'**
  String get notificationsChannelQueueAlertsDescription;

  /// No description provided for @historyTabMatches.
  ///
  /// In pt, this message translates to:
  /// **'Partidas'**
  String get historyTabMatches;

  /// No description provided for @historyTabStats.
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas'**
  String get historyTabStats;

  /// No description provided for @historyPeriodAll.
  ///
  /// In pt, this message translates to:
  /// **'Sempre'**
  String get historyPeriodAll;

  /// No description provided for @historyPeriod7.
  ///
  /// In pt, this message translates to:
  /// **'7 dias'**
  String get historyPeriod7;

  /// No description provided for @historyPeriod30.
  ///
  /// In pt, this message translates to:
  /// **'30 dias'**
  String get historyPeriod30;

  /// No description provided for @historyPeriod90.
  ///
  /// In pt, this message translates to:
  /// **'90 dias'**
  String get historyPeriod90;

  /// No description provided for @historyStatusAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get historyStatusAll;

  /// No description provided for @historyStatusMatchFound.
  ///
  /// In pt, this message translates to:
  /// **'Encontradas'**
  String get historyStatusMatchFound;

  /// No description provided for @historyStatusCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Canceladas'**
  String get historyStatusCancelled;

  /// No description provided for @historyStatusExpired.
  ///
  /// In pt, this message translates to:
  /// **'Expiradas'**
  String get historyStatusExpired;

  /// No description provided for @historyStatusMatchFoundLabel.
  ///
  /// In pt, this message translates to:
  /// **'Partida encontrada'**
  String get historyStatusMatchFoundLabel;

  /// No description provided for @historyStatusCancelledLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelada'**
  String get historyStatusCancelledLabel;

  /// No description provided for @historyStatusExpiredLabel.
  ///
  /// In pt, this message translates to:
  /// **'Expirada'**
  String get historyStatusExpiredLabel;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma busca ainda'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'As buscas de partida do time aparecem aqui quando terminam.'**
  String get historyEmptyMessage;

  /// No description provided for @activityScopeAll.
  ///
  /// In pt, this message translates to:
  /// **'Tudo'**
  String get activityScopeAll;

  /// No description provided for @activityScopeGames.
  ///
  /// In pt, this message translates to:
  /// **'Partidas'**
  String get activityScopeGames;

  /// No description provided for @activityScopeSearches.
  ///
  /// In pt, this message translates to:
  /// **'Buscas'**
  String get activityScopeSearches;

  /// No description provided for @activityNoResult.
  ///
  /// In pt, this message translates to:
  /// **'Resultado não informado'**
  String get activityNoResult;

  /// No description provided for @activityDetailMode.
  ///
  /// In pt, this message translates to:
  /// **'Modo'**
  String get activityDetailMode;

  /// No description provided for @activityDetailDuration.
  ///
  /// In pt, this message translates to:
  /// **'Duração'**
  String get activityDetailDuration;

  /// No description provided for @activityDetailScore.
  ///
  /// In pt, this message translates to:
  /// **'Placar'**
  String get activityDetailScore;

  /// No description provided for @activityDetailResult.
  ///
  /// In pt, this message translates to:
  /// **'Resultado'**
  String get activityDetailResult;

  /// No description provided for @activityDetailStatus.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get activityDetailStatus;

  /// No description provided for @historyLoadErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o histórico'**
  String get historyLoadErrorTitle;

  /// No description provided for @historyLoadMore.
  ///
  /// In pt, this message translates to:
  /// **'Carregar mais'**
  String get historyLoadMore;

  /// No description provided for @historyEntryDate.
  ///
  /// In pt, this message translates to:
  /// **'{date}'**
  String historyEntryDate(DateTime date);

  /// No description provided for @historyEntryTime.
  ///
  /// In pt, this message translates to:
  /// **'{time}'**
  String historyEntryTime(DateTime time);

  /// No description provided for @statsTotalSearches.
  ///
  /// In pt, this message translates to:
  /// **'Buscas'**
  String get statsTotalSearches;

  /// No description provided for @statsMatchFound.
  ///
  /// In pt, this message translates to:
  /// **'Encontradas'**
  String get statsMatchFound;

  /// No description provided for @statsCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Canceladas'**
  String get statsCancelled;

  /// No description provided for @statsExpired.
  ///
  /// In pt, this message translates to:
  /// **'Expiradas'**
  String get statsExpired;

  /// No description provided for @statsSuccessRate.
  ///
  /// In pt, this message translates to:
  /// **'Taxa de sucesso'**
  String get statsSuccessRate;

  /// No description provided for @statsAvgDuration.
  ///
  /// In pt, this message translates to:
  /// **'Duração média'**
  String get statsAvgDuration;

  /// No description provided for @statsPlayersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Por jogador'**
  String get statsPlayersTitle;

  /// No description provided for @statsEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sem dados no período'**
  String get statsEmptyTitle;

  /// No description provided for @statsEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Quando o time buscar partidas, as estatísticas aparecem aqui.'**
  String get statsEmptyMessage;

  /// No description provided for @statsLoadErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as estatísticas'**
  String get statsLoadErrorTitle;

  /// No description provided for @statsPlayerSearches.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 busca} other{{count} buscas}}'**
  String statsPlayerSearches(int count);

  /// No description provided for @gameModeWeekendLeague.
  ///
  /// In pt, this message translates to:
  /// **'Weekend League'**
  String get gameModeWeekendLeague;

  /// No description provided for @gameModeDivisionRivals.
  ///
  /// In pt, this message translates to:
  /// **'Division Rivals'**
  String get gameModeDivisionRivals;

  /// No description provided for @pendingMatchTitle.
  ///
  /// In pt, this message translates to:
  /// **'Você tem uma partida sem resultado'**
  String get pendingMatchTitle;

  /// No description provided for @pendingMatchWinAction.
  ///
  /// In pt, this message translates to:
  /// **'Vitória'**
  String get pendingMatchWinAction;

  /// No description provided for @pendingMatchLossAction.
  ///
  /// In pt, this message translates to:
  /// **'Derrota'**
  String get pendingMatchLossAction;

  /// No description provided for @pendingMatchAddScoreAction.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar placar'**
  String get pendingMatchAddScoreAction;

  /// No description provided for @finishMatchSheetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resultado da partida'**
  String get finishMatchSheetTitle;

  /// No description provided for @finishMatchSheetMessage.
  ///
  /// In pt, this message translates to:
  /// **'Informe o placar da sua partida.'**
  String get finishMatchSheetMessage;

  /// No description provided for @finishMatchGoalsForLabel.
  ///
  /// In pt, this message translates to:
  /// **'Seus gols'**
  String get finishMatchGoalsForLabel;

  /// No description provided for @finishMatchGoalsAgainstLabel.
  ///
  /// In pt, this message translates to:
  /// **'Gols do adversário'**
  String get finishMatchGoalsAgainstLabel;

  /// No description provided for @finishMatchGoalsRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe um número válido.'**
  String get finishMatchGoalsRequired;

  /// No description provided for @finishMatchDrawError.
  ///
  /// In pt, this message translates to:
  /// **'Empate não é um resultado final válido.'**
  String get finishMatchDrawError;

  /// No description provided for @finishMatchSubmitAction.
  ///
  /// In pt, this message translates to:
  /// **'Salvar resultado'**
  String get finishMatchSubmitAction;

  /// No description provided for @weekendLeagueBadge.
  ///
  /// In pt, this message translates to:
  /// **'Weekend League #{number}'**
  String weekendLeagueBadge(int number);

  /// No description provided for @weekendLeagueWindow.
  ///
  /// In pt, this message translates to:
  /// **'{start} – {end}'**
  String weekendLeagueWindow(String start, String end);

  /// No description provided for @weekendLeagueActiveBadge.
  ///
  /// In pt, this message translates to:
  /// **'Em andamento'**
  String get weekendLeagueActiveBadge;
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
