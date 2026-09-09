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

  /// No description provided for @navHome.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get navHome;

  /// No description provided for @navControl.
  ///
  /// In pt, this message translates to:
  /// **'Jogar'**
  String get navControl;

  /// No description provided for @navTeam.
  ///
  /// In pt, this message translates to:
  /// **'Times'**
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

  /// No description provided for @startEyebrow.
  ///
  /// In pt, this message translates to:
  /// **'FIFA QUEUE'**
  String get startEyebrow;

  /// No description provided for @startTitle.
  ///
  /// In pt, this message translates to:
  /// **'Visão geral'**
  String get startTitle;

  /// No description provided for @startSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Seu time e sua semana em um lugar.'**
  String get startSubtitle;

  /// No description provided for @startShortcutsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atalhos'**
  String get startShortcutsTitle;

  /// No description provided for @controlEyebrow.
  ///
  /// In pt, this message translates to:
  /// **'JOGAR'**
  String get controlEyebrow;

  /// No description provided for @controlTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sua vez na fila'**
  String get controlTitle;

  /// No description provided for @controlSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Fila, adversário e squad em um só lugar.'**
  String get controlSubtitle;

  /// No description provided for @controlDiscoverCardsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Explorar cartas'**
  String get controlDiscoverCardsTitle;

  /// No description provided for @controlDiscoverCardsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Jogadores em destaque no catálogo completo.'**
  String get controlDiscoverCardsSubtitle;

  /// No description provided for @controlDiscoverClubsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Clubes'**
  String get controlDiscoverClubsTitle;

  /// No description provided for @controlDiscoverClubsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Explore os clubes do catálogo FC27.'**
  String get controlDiscoverClubsSubtitle;

  /// No description provided for @controlEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pronto pra entrar em campo?'**
  String get controlEmptyTitle;

  /// No description provided for @controlEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Escolha uma conta e um modo pra começar a buscar partida.'**
  String get controlEmptyMessage;

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

  /// No description provided for @teamsEyebrow.
  ///
  /// In pt, this message translates to:
  /// **'FIFA QUEUE'**
  String get teamsEyebrow;

  /// No description provided for @teamsListSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Seus times e status operacional.'**
  String get teamsListSubtitle;

  /// No description provided for @teamsMineTab.
  ///
  /// In pt, this message translates to:
  /// **'Meus Times'**
  String get teamsMineTab;

  /// No description provided for @teamsExploreTab.
  ///
  /// In pt, this message translates to:
  /// **'Explorar'**
  String get teamsExploreTab;

  /// No description provided for @teamsExploreEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum time público ainda'**
  String get teamsExploreEmptyTitle;

  /// No description provided for @teamsExploreEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Times públicos aparecem aqui quando existirem.'**
  String get teamsExploreEmptyMessage;

  /// No description provided for @teamVisibilitySectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Visibilidade'**
  String get teamVisibilitySectionTitle;

  /// No description provided for @teamVisibilityPublic.
  ///
  /// In pt, this message translates to:
  /// **'Público'**
  String get teamVisibilityPublic;

  /// No description provided for @teamVisibilityPrivate.
  ///
  /// In pt, this message translates to:
  /// **'Privado'**
  String get teamVisibilityPrivate;

  /// No description provided for @teamVisibilityPublicHint.
  ///
  /// In pt, this message translates to:
  /// **'Aparece em Explorar e tem página pública.'**
  String get teamVisibilityPublicHint;

  /// No description provided for @teamVisibilityPrivateHint.
  ///
  /// In pt, this message translates to:
  /// **'Não aparece em Explorar nem em buscas públicas.'**
  String get teamVisibilityPrivateHint;

  /// No description provided for @teamPublicPageMembersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Elenco'**
  String get teamPublicPageMembersTitle;

  /// No description provided for @teamPublicPageRecordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Retrospecto'**
  String get teamPublicPageRecordTitle;

  /// No description provided for @teamPublicPageRecordLine.
  ///
  /// In pt, this message translates to:
  /// **'{wins} vitórias • {losses} derrotas'**
  String teamPublicPageRecordLine(int wins, int losses);

  /// No description provided for @teamPublicPageNotFoundTitle.
  ///
  /// In pt, this message translates to:
  /// **'Time não encontrado'**
  String get teamPublicPageNotFoundTitle;

  /// No description provided for @teamPublicPageNotFoundMessage.
  ///
  /// In pt, this message translates to:
  /// **'Este time não existe ou não está disponível publicamente.'**
  String get teamPublicPageNotFoundMessage;

  /// No description provided for @historyEyebrow.
  ///
  /// In pt, this message translates to:
  /// **'FIFA QUEUE'**
  String get historyEyebrow;

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

  /// No description provided for @historyNoTeamMessage.
  ///
  /// In pt, this message translates to:
  /// **'Sem time não há histórico pra mostrar. Crie o seu ou entre com um código de convite para começar a registrar buscas e partidas.'**
  String get historyNoTeamMessage;

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

  /// No description provided for @teamCreateFcAccountsSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Quais Contas FC fazem parte deste time?'**
  String get teamCreateFcAccountsSectionTitle;

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

  /// No description provided for @teamsListEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não faz parte de um time.'**
  String get teamsListEmptyMessage;

  /// No description provided for @teamDetailPlayersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Jogadores'**
  String get teamDetailPlayersTitle;

  /// No description provided for @playerProfileTitle.
  ///
  /// In pt, this message translates to:
  /// **'Perfil do jogador'**
  String get playerProfileTitle;

  /// No description provided for @playerProfileAccountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get playerProfileAccountLabel;

  /// No description provided for @playerProfileNoAccountMessage.
  ///
  /// In pt, this message translates to:
  /// **'Este jogador não tem uma conta vinculada a este time.'**
  String get playerProfileNoAccountMessage;

  /// No description provided for @playerProfileSquadLabel.
  ///
  /// In pt, this message translates to:
  /// **'Escalação principal'**
  String get playerProfileSquadLabel;

  /// No description provided for @playerProfileSquadNoneMessage.
  ///
  /// In pt, this message translates to:
  /// **'Ainda sem escalação montada.'**
  String get playerProfileSquadNoneMessage;

  /// No description provided for @playerProfileCompletenessLabel.
  ///
  /// In pt, this message translates to:
  /// **'{count}/{total} titulares'**
  String playerProfileCompletenessLabel(int count, int total);

  /// No description provided for @playerProfileSelectAccountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Este jogador tem mais de uma conta neste time'**
  String get playerProfileSelectAccountTitle;

  /// No description provided for @playerProfileWeekendLeagueEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum evento de Weekend League registrado.'**
  String get playerProfileWeekendLeagueEmptyMessage;

  /// No description provided for @playerProfileWeekendLeagueRecordLabel.
  ///
  /// In pt, this message translates to:
  /// **'{wins}V–{losses}D'**
  String playerProfileWeekendLeagueRecordLabel(int wins, int losses);

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
  /// **'Quando entrar na partida, marque que encontrou.'**
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

  /// No description provided for @notificationsChannelAppUpdatesName.
  ///
  /// In pt, this message translates to:
  /// **'Atualizações do time'**
  String get notificationsChannelAppUpdatesName;

  /// No description provided for @notificationsChannelAppUpdatesDescription.
  ///
  /// In pt, this message translates to:
  /// **'Novos membros, ranking, Weekend League e Rivals.'**
  String get notificationsChannelAppUpdatesDescription;

  /// No description provided for @notificationsCategoryMatchmaking.
  ///
  /// In pt, this message translates to:
  /// **'Matchmaking'**
  String get notificationsCategoryMatchmaking;

  /// No description provided for @notificationsCategoryMatchmakingHint.
  ///
  /// In pt, this message translates to:
  /// **'Sua vez, avisos de expiração da busca.'**
  String get notificationsCategoryMatchmakingHint;

  /// No description provided for @notificationsCategoryTeams.
  ///
  /// In pt, this message translates to:
  /// **'Times'**
  String get notificationsCategoryTeams;

  /// No description provided for @notificationsCategoryTeamsHint.
  ///
  /// In pt, this message translates to:
  /// **'Novos membros no time.'**
  String get notificationsCategoryTeamsHint;

  /// No description provided for @notificationsCategoryWeekendLeague.
  ///
  /// In pt, this message translates to:
  /// **'Weekend League'**
  String get notificationsCategoryWeekendLeague;

  /// No description provided for @notificationsCategoryWeekendLeagueHint.
  ///
  /// In pt, this message translates to:
  /// **'Quando uma Weekend League termina.'**
  String get notificationsCategoryWeekendLeagueHint;

  /// No description provided for @notificationsCategoryRivals.
  ///
  /// In pt, this message translates to:
  /// **'Rivals'**
  String get notificationsCategoryRivals;

  /// No description provided for @notificationsCategoryRivalsHint.
  ///
  /// In pt, this message translates to:
  /// **'Mudança de divisão de uma conta do time.'**
  String get notificationsCategoryRivalsHint;

  /// No description provided for @notificationsCategoryRankings.
  ///
  /// In pt, this message translates to:
  /// **'Rankings'**
  String get notificationsCategoryRankings;

  /// No description provided for @notificationsCategoryRankingsHint.
  ///
  /// In pt, this message translates to:
  /// **'Novo líder, artilheiro ou garçom do time.'**
  String get notificationsCategoryRankingsHint;

  /// No description provided for @notificationsInboxTitle.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get notificationsInboxTitle;

  /// No description provided for @notificationsInboxMarkAllRead.
  ///
  /// In pt, this message translates to:
  /// **'Marcar tudo como lido'**
  String get notificationsInboxMarkAllRead;

  /// No description provided for @notificationsInboxEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não tem notificações'**
  String get notificationsInboxEmptyTitle;

  /// No description provided for @notificationsInboxEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Avisos do time, do ranking e das suas buscas aparecem aqui.'**
  String get notificationsInboxEmptyMessage;

  /// No description provided for @notificationsInboxErrorMessage.
  ///
  /// In pt, this message translates to:
  /// **'Não deu para carregar suas notificações.'**
  String get notificationsInboxErrorMessage;

  /// No description provided for @notificationsInboxRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get notificationsInboxRetry;

  /// No description provided for @notificationsGroupToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get notificationsGroupToday;

  /// No description provided for @notificationsGroupYesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get notificationsGroupYesterday;

  /// No description provided for @notificationsGroupEarlier.
  ///
  /// In pt, this message translates to:
  /// **'Anteriores'**
  String get notificationsGroupEarlier;

  /// No description provided for @notificationTeamMemberJoined.
  ///
  /// In pt, this message translates to:
  /// **'{displayName} entrou em {teamName}.'**
  String notificationTeamMemberJoined(String displayName, String teamName);

  /// No description provided for @notificationTeamLeaderChanged.
  ///
  /// In pt, this message translates to:
  /// **'{leaderDisplayName} assumiu a liderança do ranking do time.'**
  String notificationTeamLeaderChanged(String leaderDisplayName);

  /// No description provided for @notificationYouAreTeamLeader.
  ///
  /// In pt, this message translates to:
  /// **'Você assumiu a liderança do ranking do time!'**
  String get notificationYouAreTeamLeader;

  /// No description provided for @notificationTeamTopScorerChanged.
  ///
  /// In pt, this message translates to:
  /// **'{playerName} ({displayName}) é o novo artilheiro do time.'**
  String notificationTeamTopScorerChanged(
    String playerName,
    String displayName,
  );

  /// No description provided for @notificationTeamTopAssistChanged.
  ///
  /// In pt, this message translates to:
  /// **'{playerName} ({displayName}) lidera as assistências do time.'**
  String notificationTeamTopAssistChanged(
    String playerName,
    String displayName,
  );

  /// No description provided for @notificationWeekendLeagueFinished.
  ///
  /// In pt, this message translates to:
  /// **'{displayName} terminou a Weekend League em {wins}-{losses}.'**
  String notificationWeekendLeagueFinished(
    String displayName,
    int wins,
    int losses,
  );

  /// No description provided for @notificationRivalsDivisionChanged.
  ///
  /// In pt, this message translates to:
  /// **'{displayName} chegou à {division} no Rivals.'**
  String notificationRivalsDivisionChanged(String displayName, String division);

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
  /// **'Jogos'**
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

  /// No description provided for @activityDetailFcAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get activityDetailFcAccount;

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

  /// No description provided for @gameModeSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Modo'**
  String get gameModeSectionTitle;

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

  /// No description provided for @errorFcAccountNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Conta não encontrada.'**
  String get errorFcAccountNotFound;

  /// No description provided for @errorFcAccountNotLinkedToTeam.
  ///
  /// In pt, this message translates to:
  /// **'Esta conta não está vinculada a este time.'**
  String get errorFcAccountNotLinkedToTeam;

  /// No description provided for @errorFcAccountInvalidName.
  ///
  /// In pt, this message translates to:
  /// **'Informe um nome de 2 a 40 caracteres.'**
  String get errorFcAccountInvalidName;

  /// No description provided for @errorFcAccountInvalidDivision.
  ///
  /// In pt, this message translates to:
  /// **'Divisão inválida.'**
  String get errorFcAccountInvalidDivision;

  /// No description provided for @errorFcAccountNotLinkedToAnyTeam.
  ///
  /// In pt, this message translates to:
  /// **'Esta conta não está vinculada a nenhum time.'**
  String get errorFcAccountNotLinkedToAnyTeam;

  /// No description provided for @validationFcAccountNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe um nome para a conta.'**
  String get validationFcAccountNameRequired;

  /// No description provided for @validationFcAccountNameTooShort.
  ///
  /// In pt, this message translates to:
  /// **'O nome precisa ter pelo menos {min} caracteres.'**
  String validationFcAccountNameTooShort(int min);

  /// No description provided for @validationFcAccountNameTooLong.
  ///
  /// In pt, this message translates to:
  /// **'O nome pode ter no máximo {max} caracteres.'**
  String validationFcAccountNameTooLong(int max);

  /// No description provided for @fcAccountRequiredToSearch.
  ///
  /// In pt, this message translates to:
  /// **'Crie ou selecione uma conta para buscar partida.'**
  String get fcAccountRequiredToSearch;

  /// No description provided for @fcAccountLinkCta.
  ///
  /// In pt, this message translates to:
  /// **'Vincular {accountName} ao {teamName}'**
  String fcAccountLinkCta(String accountName, String teamName);

  /// No description provided for @fcAccountsPageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Minhas Contas'**
  String get fcAccountsPageTitle;

  /// No description provided for @fcAccountsPageSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Suas contas de Ultimate Team'**
  String get fcAccountsPageSubtitle;

  /// No description provided for @fcAccountsEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não tem uma conta'**
  String get fcAccountsEmptyTitle;

  /// No description provided for @fcAccountsEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Crie uma conta para vincular a times e começar a buscar partidas.'**
  String get fcAccountsEmptyMessage;

  /// No description provided for @fcAccountCreateAction.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get fcAccountCreateAction;

  /// No description provided for @fcAccountCreateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova conta'**
  String get fcAccountCreateTitle;

  /// No description provided for @fcAccountCreateSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Dê um nome para identificar esta conta.'**
  String get fcAccountCreateSubtitle;

  /// No description provided for @fcAccountNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome da conta'**
  String get fcAccountNameLabel;

  /// No description provided for @fcAccountNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Conta principal'**
  String get fcAccountNameHint;

  /// No description provided for @fcAccountRenameTitle.
  ///
  /// In pt, this message translates to:
  /// **'Renomear conta'**
  String get fcAccountRenameTitle;

  /// No description provided for @fcAccountRenameAction.
  ///
  /// In pt, this message translates to:
  /// **'Renomear'**
  String get fcAccountRenameAction;

  /// No description provided for @fcAccountArchiveAction.
  ///
  /// In pt, this message translates to:
  /// **'Arquivar conta'**
  String get fcAccountArchiveAction;

  /// No description provided for @fcAccountArchiveConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Arquivar conta?'**
  String get fcAccountArchiveConfirmTitle;

  /// No description provided for @fcAccountArchiveConfirmMessage.
  ///
  /// In pt, this message translates to:
  /// **'A conta deixa de aparecer na lista, mas o histórico dela é mantido.'**
  String get fcAccountArchiveConfirmMessage;

  /// No description provided for @fcAccountSwitchTitle.
  ///
  /// In pt, this message translates to:
  /// **'Trocar de conta'**
  String get fcAccountSwitchTitle;

  /// No description provided for @fcAccountSwitchCreateAction.
  ///
  /// In pt, this message translates to:
  /// **'+ Criar nova conta'**
  String get fcAccountSwitchCreateAction;

  /// No description provided for @fcAccountLinkedTeamsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Times vinculados'**
  String get fcAccountLinkedTeamsTitle;

  /// No description provided for @fcAccountLinkedTeamsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Esta conta ainda não está vinculada a nenhum time.'**
  String get fcAccountLinkedTeamsEmpty;

  /// No description provided for @fcAccountLinkTeamAction.
  ///
  /// In pt, this message translates to:
  /// **'Vincular'**
  String get fcAccountLinkTeamAction;

  /// No description provided for @fcAccountUnlinkTeamAction.
  ///
  /// In pt, this message translates to:
  /// **'Desvincular'**
  String get fcAccountUnlinkTeamAction;

  /// No description provided for @fcAccountSettingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get fcAccountSettingsTitle;

  /// No description provided for @fcAccountDivisionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Divisão de Rivals'**
  String get fcAccountDivisionTitle;

  /// No description provided for @fcAccountDivisionPickerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar divisão'**
  String get fcAccountDivisionPickerTitle;

  /// No description provided for @fcAccountDivisionNone.
  ///
  /// In pt, this message translates to:
  /// **'Sem divisão definida'**
  String get fcAccountDivisionNone;

  /// No description provided for @fcAccountWeekendLeagueTitle.
  ///
  /// In pt, this message translates to:
  /// **'Weekend League'**
  String get fcAccountWeekendLeagueTitle;

  /// No description provided for @fcAccountWeekendLeagueComputedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Registrado por partidas: {wins}–{losses}'**
  String fcAccountWeekendLeagueComputedLabel(int wins, int losses);

  /// No description provided for @fcAccountWeekendLeagueManualLabel.
  ///
  /// In pt, this message translates to:
  /// **'Resultado informado: {wins}–{losses}'**
  String fcAccountWeekendLeagueManualLabel(int wins, int losses);

  /// No description provided for @fcAccountWeekendLeagueEditAction.
  ///
  /// In pt, this message translates to:
  /// **'Informar resultado'**
  String get fcAccountWeekendLeagueEditAction;

  /// No description provided for @fcAccountWeekendLeagueClearAction.
  ///
  /// In pt, this message translates to:
  /// **'Usar resultado das partidas'**
  String get fcAccountWeekendLeagueClearAction;

  /// No description provided for @fcAccountWeekendLeagueSheetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Informar resultado'**
  String get fcAccountWeekendLeagueSheetTitle;

  /// No description provided for @fcAccountWeekendLeagueWinsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Vitórias'**
  String get fcAccountWeekendLeagueWinsLabel;

  /// No description provided for @fcAccountWeekendLeagueLossesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Derrotas'**
  String get fcAccountWeekendLeagueLossesLabel;

  /// No description provided for @fcAccountOnboardingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Crie sua primeira conta'**
  String get fcAccountOnboardingTitle;

  /// No description provided for @fcAccountOnboardingMessage.
  ///
  /// In pt, this message translates to:
  /// **'Uma conta representa um perfil seu no Ultimate Team. Crie uma para vincular aos seus times e começar a buscar partidas.'**
  String get fcAccountOnboardingMessage;

  /// No description provided for @fcAccountOnboardingCreateAction.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get fcAccountOnboardingCreateAction;

  /// No description provided for @pendingMatchElencoLabel.
  ///
  /// In pt, this message translates to:
  /// **'Conta: {name}'**
  String pendingMatchElencoLabel(String name);

  /// No description provided for @historyElencoLabel.
  ///
  /// In pt, this message translates to:
  /// **'Conta: {name}'**
  String historyElencoLabel(String name);

  /// No description provided for @profileFcAccountsRow.
  ///
  /// In pt, this message translates to:
  /// **'Contas'**
  String get profileFcAccountsRow;

  /// No description provided for @rivalsDivisionDiv10.
  ///
  /// In pt, this message translates to:
  /// **'Divisão 10'**
  String get rivalsDivisionDiv10;

  /// No description provided for @rivalsDivisionDiv9.
  ///
  /// In pt, this message translates to:
  /// **'Divisão 9'**
  String get rivalsDivisionDiv9;

  /// No description provided for @rivalsDivisionDiv8.
  ///
  /// In pt, this message translates to:
  /// **'Divisão 8'**
  String get rivalsDivisionDiv8;

  /// No description provided for @rivalsDivisionDiv7.
  ///
  /// In pt, this message translates to:
  /// **'Divisão 7'**
  String get rivalsDivisionDiv7;

  /// No description provided for @rivalsDivisionDiv6.
  ///
  /// In pt, this message translates to:
  /// **'Divisão 6'**
  String get rivalsDivisionDiv6;

  /// No description provided for @rivalsDivisionDiv5.
  ///
  /// In pt, this message translates to:
  /// **'Divisão 5'**
  String get rivalsDivisionDiv5;

  /// No description provided for @rivalsDivisionDiv4.
  ///
  /// In pt, this message translates to:
  /// **'Divisão 4'**
  String get rivalsDivisionDiv4;

  /// No description provided for @rivalsDivisionDiv3.
  ///
  /// In pt, this message translates to:
  /// **'Divisão 3'**
  String get rivalsDivisionDiv3;

  /// No description provided for @rivalsDivisionDiv2.
  ///
  /// In pt, this message translates to:
  /// **'Divisão 2'**
  String get rivalsDivisionDiv2;

  /// No description provided for @rivalsDivisionDiv1.
  ///
  /// In pt, this message translates to:
  /// **'Divisão 1'**
  String get rivalsDivisionDiv1;

  /// No description provided for @rivalsDivisionElite.
  ///
  /// In pt, this message translates to:
  /// **'Elite'**
  String get rivalsDivisionElite;

  /// No description provided for @squadsSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Squads'**
  String get squadsSectionTitle;

  /// No description provided for @squadBuilderSaved.
  ///
  /// In pt, this message translates to:
  /// **'Salvo'**
  String get squadBuilderSaved;

  /// No description provided for @squadBuilderSaving.
  ///
  /// In pt, this message translates to:
  /// **'Salvando…'**
  String get squadBuilderSaving;

  /// No description provided for @squadsEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum squad configurado'**
  String get squadsEmptyTitle;

  /// No description provided for @squadsEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Crie um squad para montar sua escalação. Você pode buscar partida mesmo sem um.'**
  String get squadsEmptyMessage;

  /// No description provided for @squadCreateAction.
  ///
  /// In pt, this message translates to:
  /// **'Criar squad'**
  String get squadCreateAction;

  /// No description provided for @squadCreateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo squad'**
  String get squadCreateTitle;

  /// No description provided for @squadCreateSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Dê um nome e escolha a formação inicial.'**
  String get squadCreateSubtitle;

  /// No description provided for @squadNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do squad'**
  String get squadNameLabel;

  /// No description provided for @squadNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Principal'**
  String get squadNameHint;

  /// No description provided for @squadFormationLabel.
  ///
  /// In pt, this message translates to:
  /// **'Formação'**
  String get squadFormationLabel;

  /// No description provided for @squadRenameTitle.
  ///
  /// In pt, this message translates to:
  /// **'Renomear squad'**
  String get squadRenameTitle;

  /// No description provided for @squadRenameAction.
  ///
  /// In pt, this message translates to:
  /// **'Renomear'**
  String get squadRenameAction;

  /// No description provided for @squadSetDefaultAction.
  ///
  /// In pt, this message translates to:
  /// **'Definir como padrão'**
  String get squadSetDefaultAction;

  /// No description provided for @squadDefaultBadge.
  ///
  /// In pt, this message translates to:
  /// **'Padrão'**
  String get squadDefaultBadge;

  /// No description provided for @squadArchiveAction.
  ///
  /// In pt, this message translates to:
  /// **'Arquivar squad'**
  String get squadArchiveAction;

  /// No description provided for @squadArchiveConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Arquivar squad?'**
  String get squadArchiveConfirmTitle;

  /// No description provided for @squadArchiveConfirmMessage.
  ///
  /// In pt, this message translates to:
  /// **'Ele sai da lista, mas o histórico das partidas jogadas com ele é mantido.'**
  String get squadArchiveConfirmMessage;

  /// No description provided for @squadBenchTitle.
  ///
  /// In pt, this message translates to:
  /// **'Banco'**
  String get squadBenchTitle;

  /// No description provided for @squadManagerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Técnico'**
  String get squadManagerTitle;

  /// No description provided for @squadManagerAddAction.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar técnico'**
  String get squadManagerAddAction;

  /// No description provided for @squadManagerRemoveAction.
  ///
  /// In pt, this message translates to:
  /// **'Remover técnico'**
  String get squadManagerRemoveAction;

  /// No description provided for @squadManagerNationLabel.
  ///
  /// In pt, this message translates to:
  /// **'País'**
  String get squadManagerNationLabel;

  /// No description provided for @squadManagerLeagueLabel.
  ///
  /// In pt, this message translates to:
  /// **'Liga'**
  String get squadManagerLeagueLabel;

  /// No description provided for @squadManagerPickNationFirst.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um país para ver os técnicos.'**
  String get squadManagerPickNationFirst;

  /// No description provided for @squadManagerNoneTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sem técnico'**
  String get squadManagerNoneTitle;

  /// No description provided for @squadFormationPickerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolher formação'**
  String get squadFormationPickerTitle;

  /// No description provided for @squadPlayerPickerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Buscar jogador'**
  String get squadPlayerPickerTitle;

  /// No description provided for @squadPlayerSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar jogador...'**
  String get squadPlayerSearchHint;

  /// No description provided for @squadPlayerPickerEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma carta encontrada.'**
  String get squadPlayerPickerEmpty;

  /// No description provided for @squadSlotChangeAction.
  ///
  /// In pt, this message translates to:
  /// **'Trocar jogador'**
  String get squadSlotChangeAction;

  /// No description provided for @squadSlotMoveAction.
  ///
  /// In pt, this message translates to:
  /// **'Mover'**
  String get squadSlotMoveAction;

  /// No description provided for @squadSlotRemoveAction.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get squadSlotRemoveAction;

  /// No description provided for @squadMoveHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque em outro slot para trocar.'**
  String get squadMoveHint;

  /// No description provided for @squadIncompleteLabel.
  ///
  /// In pt, this message translates to:
  /// **'Squad incompleto'**
  String get squadIncompleteLabel;

  /// No description provided for @squadLabel.
  ///
  /// In pt, this message translates to:
  /// **'Squad'**
  String get squadLabel;

  /// No description provided for @squadNoneSelected.
  ///
  /// In pt, this message translates to:
  /// **'Sem squad'**
  String get squadNoneSelected;

  /// No description provided for @squadDevCatalogNotice.
  ///
  /// In pt, this message translates to:
  /// **'Cartas de desenvolvimento. O catálogo real chega na próxima etapa.'**
  String get squadDevCatalogNotice;

  /// No description provided for @squadFilterLeagueLabel.
  ///
  /// In pt, this message translates to:
  /// **'Liga'**
  String get squadFilterLeagueLabel;

  /// No description provided for @squadFilterClubLabel.
  ///
  /// In pt, this message translates to:
  /// **'Clube'**
  String get squadFilterClubLabel;

  /// No description provided for @squadFilterNationLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nação'**
  String get squadFilterNationLabel;

  /// No description provided for @errorSquadNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Squad não encontrado.'**
  String get errorSquadNotFound;

  /// No description provided for @errorSquadNameInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um nome de 1 a 40 caracteres.'**
  String get errorSquadNameInvalid;

  /// No description provided for @errorSquadFormationInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Essa formação não está disponível.'**
  String get errorSquadFormationInvalid;

  /// No description provided for @errorSquadSlotInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Essa posição não existe nesta formação.'**
  String get errorSquadSlotInvalid;

  /// No description provided for @errorSquadCardPosition.
  ///
  /// In pt, this message translates to:
  /// **'Esse jogador não atua nessa posição.'**
  String get errorSquadCardPosition;

  /// No description provided for @errorSquadInUse.
  ///
  /// In pt, this message translates to:
  /// **'Este squad está sendo usado em uma busca ativa.'**
  String get errorSquadInUse;

  /// No description provided for @squadCompletionLabel.
  ///
  /// In pt, this message translates to:
  /// **'{filled}/{total} titulares'**
  String squadCompletionLabel(int filled, int total);

  /// No description provided for @squadSummaryLabel.
  ///
  /// In pt, this message translates to:
  /// **'{name} · {formation}'**
  String squadSummaryLabel(String name, String formation);

  /// No description provided for @squadSlotCountLabel.
  ///
  /// In pt, this message translates to:
  /// **'{filled}/{total}'**
  String squadSlotCountLabel(int filled, int total);

  /// No description provided for @squadOverallValue.
  ///
  /// In pt, this message translates to:
  /// **'OVR {overall}'**
  String squadOverallValue(int overall);

  /// No description provided for @squadOverallUnknown.
  ///
  /// In pt, this message translates to:
  /// **'OVR --'**
  String get squadOverallUnknown;

  /// No description provided for @squadChemistryValue.
  ///
  /// In pt, this message translates to:
  /// **'{chemistry}/33'**
  String squadChemistryValue(int chemistry);

  /// No description provided for @squadReserveTitle.
  ///
  /// In pt, this message translates to:
  /// **'Reservas'**
  String get squadReserveTitle;

  /// No description provided for @squadClearAction.
  ///
  /// In pt, this message translates to:
  /// **'Limpar escalação'**
  String get squadClearAction;

  /// No description provided for @squadClearConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Limpar escalação?'**
  String get squadClearConfirmTitle;

  /// No description provided for @squadClearConfirmMessage.
  ///
  /// In pt, this message translates to:
  /// **'Isso remove todos os jogadores dos titulares, do banco e das reservas. O squad em si não é apagado.'**
  String get squadClearConfirmMessage;

  /// No description provided for @squadFormationChangeConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Trocar formação?'**
  String get squadFormationChangeConfirmTitle;

  /// No description provided for @squadFormationChangeConfirmMessage.
  ///
  /// In pt, this message translates to:
  /// **'Seus jogadores serão reposicionados automaticamente. Ninguém é removido, mas alguém pode ficar fora de posição.'**
  String get squadFormationChangeConfirmMessage;

  /// No description provided for @squadFilterCompatibleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Compatíveis'**
  String get squadFilterCompatibleLabel;

  /// No description provided for @squadPositionBadgePrimary.
  ///
  /// In pt, this message translates to:
  /// **'Primária'**
  String get squadPositionBadgePrimary;

  /// No description provided for @squadPositionBadgeAlternative.
  ///
  /// In pt, this message translates to:
  /// **'Alternativa'**
  String get squadPositionBadgeAlternative;

  /// No description provided for @squadPositionBadgeOutOfPosition.
  ///
  /// In pt, this message translates to:
  /// **'Fora de posição'**
  String get squadPositionBadgeOutOfPosition;

  /// No description provided for @squadCardDetailAction.
  ///
  /// In pt, this message translates to:
  /// **'Ver detalhes'**
  String get squadCardDetailAction;

  /// No description provided for @squadCardDetailRatingLabel.
  ///
  /// In pt, this message translates to:
  /// **'Rating'**
  String get squadCardDetailRatingLabel;

  /// No description provided for @squadCardDetailPositionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Posição'**
  String get squadCardDetailPositionLabel;

  /// No description provided for @squadCardDetailAltPositionsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Posições alternativas'**
  String get squadCardDetailAltPositionsLabel;

  /// No description provided for @squadCardDetailStatsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atributos'**
  String get squadCardDetailStatsTitle;

  /// No description provided for @squadCardDetailGkStatsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atributos de goleiro'**
  String get squadCardDetailGkStatsTitle;

  /// No description provided for @squadCardDetailWeakFootLabel.
  ///
  /// In pt, this message translates to:
  /// **'Pé fraco'**
  String get squadCardDetailWeakFootLabel;

  /// No description provided for @squadCardDetailSkillMovesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Habilidades'**
  String get squadCardDetailSkillMovesLabel;

  /// No description provided for @squadCardDetailPreferredFootLabel.
  ///
  /// In pt, this message translates to:
  /// **'Pé preferido'**
  String get squadCardDetailPreferredFootLabel;

  /// No description provided for @squadCardDetailPreferredFootLeft.
  ///
  /// In pt, this message translates to:
  /// **'Esquerdo'**
  String get squadCardDetailPreferredFootLeft;

  /// No description provided for @squadCardDetailPreferredFootRight.
  ///
  /// In pt, this message translates to:
  /// **'Direito'**
  String get squadCardDetailPreferredFootRight;

  /// No description provided for @squadCardDetailPlaystylesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Playstyles'**
  String get squadCardDetailPlaystylesTitle;

  /// No description provided for @squadCardDetailRolesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Funções'**
  String get squadCardDetailRolesTitle;

  /// No description provided for @squadCardDetailClubLabel.
  ///
  /// In pt, this message translates to:
  /// **'Clube'**
  String get squadCardDetailClubLabel;

  /// No description provided for @squadCardDetailLeagueLabel.
  ///
  /// In pt, this message translates to:
  /// **'Liga'**
  String get squadCardDetailLeagueLabel;

  /// No description provided for @squadCardDetailNationLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nação'**
  String get squadCardDetailNationLabel;

  /// No description provided for @squadCardDetailOtherVersionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Outras versões'**
  String get squadCardDetailOtherVersionsTitle;

  /// No description provided for @squadCardDetailOtherVersionsComingSoon.
  ///
  /// In pt, this message translates to:
  /// **'Em breve: comparar todas as versões deste jogador.'**
  String get squadCardDetailOtherVersionsComingSoon;

  /// No description provided for @actionMore.
  ///
  /// In pt, this message translates to:
  /// **'Mais'**
  String get actionMore;

  /// No description provided for @errorGameInvalidStatsPayload.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar esses gols/assistências.'**
  String get errorGameInvalidStatsPayload;

  /// No description provided for @errorGamePlayerNotInSquad.
  ///
  /// In pt, this message translates to:
  /// **'Esse jogador não fez parte desta partida.'**
  String get errorGamePlayerNotInSquad;

  /// No description provided for @errorGameNoSquadSnapshot.
  ///
  /// In pt, this message translates to:
  /// **'Esta partida não tem escalação registrada.'**
  String get errorGameNoSquadSnapshot;

  /// No description provided for @errorGameMatchNotFinished.
  ///
  /// In pt, this message translates to:
  /// **'Finalize a partida antes de editar o resultado.'**
  String get errorGameMatchNotFinished;

  /// No description provided for @pendingMatchDetailsPromptTitle.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar detalhes da partida?'**
  String get pendingMatchDetailsPromptTitle;

  /// No description provided for @pendingMatchDetailsPromptMessage.
  ///
  /// In pt, this message translates to:
  /// **'Você pode registrar gols e assistências por jogador agora ou depois, pelo Histórico.'**
  String get pendingMatchDetailsPromptMessage;

  /// No description provided for @pendingMatchDetailsPromptAddAction.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar agora'**
  String get pendingMatchDetailsPromptAddAction;

  /// No description provided for @pendingMatchDetailsPromptSkipAction.
  ///
  /// In pt, this message translates to:
  /// **'Agora não'**
  String get pendingMatchDetailsPromptSkipAction;

  /// No description provided for @matchDetailsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Detalhe da partida'**
  String get matchDetailsTitle;

  /// No description provided for @matchDetailsResultLabel.
  ///
  /// In pt, this message translates to:
  /// **'Resultado'**
  String get matchDetailsResultLabel;

  /// No description provided for @matchDetailsScoreLabel.
  ///
  /// In pt, this message translates to:
  /// **'Placar'**
  String get matchDetailsScoreLabel;

  /// No description provided for @matchDetailsNoResultMessage.
  ///
  /// In pt, this message translates to:
  /// **'Sem resultado registrado.'**
  String get matchDetailsNoResultMessage;

  /// No description provided for @matchDetailsEditResultAction.
  ///
  /// In pt, this message translates to:
  /// **'Editar resultado'**
  String get matchDetailsEditResultAction;

  /// No description provided for @matchDetailsAddDetailsAction.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar gols e assistências'**
  String get matchDetailsAddDetailsAction;

  /// No description provided for @matchDetailsEditDetailsAction.
  ///
  /// In pt, this message translates to:
  /// **'Editar gols e assistências'**
  String get matchDetailsEditDetailsAction;

  /// No description provided for @matchDetailsSquadSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Escalação'**
  String get matchDetailsSquadSectionTitle;

  /// No description provided for @matchDetailsPlayerStatsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gols e assistências'**
  String get matchDetailsPlayerStatsTitle;

  /// No description provided for @matchDetailsPlayerStatsEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum gol ou assistência registrado nesta partida.'**
  String get matchDetailsPlayerStatsEmptyMessage;

  /// No description provided for @editMatchResultSheetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar resultado'**
  String get editMatchResultSheetTitle;

  /// No description provided for @editMatchResultSheetMessage.
  ///
  /// In pt, this message translates to:
  /// **'Você pode corrigir o placar a qualquer momento, mesmo depois da partida encerrada.'**
  String get editMatchResultSheetMessage;

  /// No description provided for @editMatchResultSubmitAction.
  ///
  /// In pt, this message translates to:
  /// **'Salvar resultado'**
  String get editMatchResultSubmitAction;

  /// No description provided for @playerStatsEditorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gols e assistências'**
  String get playerStatsEditorTitle;

  /// No description provided for @playerStatsEditorStartingLabel.
  ///
  /// In pt, this message translates to:
  /// **'Titulares'**
  String get playerStatsEditorStartingLabel;

  /// No description provided for @playerStatsEditorBenchLabel.
  ///
  /// In pt, this message translates to:
  /// **'Banco'**
  String get playerStatsEditorBenchLabel;

  /// No description provided for @playerStatsEditorSaveAction.
  ///
  /// In pt, this message translates to:
  /// **'Salvar detalhes'**
  String get playerStatsEditorSaveAction;

  /// No description provided for @statsGoalsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Gols'**
  String get statsGoalsLabel;

  /// No description provided for @statsAssistsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Assistências'**
  String get statsAssistsLabel;

  /// No description provided for @statsMatchesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Partidas'**
  String get statsMatchesLabel;

  /// No description provided for @statsWinsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Vitórias'**
  String get statsWinsLabel;

  /// No description provided for @statsLossesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Derrotas'**
  String get statsLossesLabel;

  /// No description provided for @statsGoalDiffLabel.
  ///
  /// In pt, this message translates to:
  /// **'Saldo de gols'**
  String get statsGoalDiffLabel;

  /// No description provided for @statsGoalsAgainstLabel.
  ///
  /// In pt, this message translates to:
  /// **'Gols sofridos'**
  String get statsGoalsAgainstLabel;

  /// No description provided for @statsTopScorersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Artilharia'**
  String get statsTopScorersTitle;

  /// No description provided for @statsTopAssistsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Assistências'**
  String get statsTopAssistsTitle;

  /// No description provided for @statsEmptyLeaderboardMessage.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum gol ou assistência registrado ainda.'**
  String get statsEmptyLeaderboardMessage;

  /// No description provided for @statsTopScorerInlineLabel.
  ///
  /// In pt, this message translates to:
  /// **'{name} · {goals} gols'**
  String statsTopScorerInlineLabel(String name, int goals);

  /// No description provided for @fcAccountStatsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas'**
  String get fcAccountStatsTitle;

  /// No description provided for @fcAccountStatsEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma partida registrada ainda.'**
  String get fcAccountStatsEmptyMessage;

  /// No description provided for @rivalsSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Division Rivals'**
  String get rivalsSectionTitle;

  /// No description provided for @rivalsDetailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Division Rivals'**
  String get rivalsDetailTitle;

  /// No description provided for @rivalsNoDivisionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Divisão ainda não informada'**
  String get rivalsNoDivisionLabel;

  /// No description provided for @rivalsAllTimeNote.
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas de todas as partidas registradas (ainda sem separação por season/semana).'**
  String get rivalsAllTimeNote;

  /// No description provided for @playerProfileSportSummaryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resumo esportivo'**
  String get playerProfileSportSummaryTitle;

  /// No description provided for @playerProfileRivalsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Division Rivals'**
  String get playerProfileRivalsLabel;

  /// No description provided for @playerProfileNoStatsMessage.
  ///
  /// In pt, this message translates to:
  /// **'Ainda sem partidas detalhadas.'**
  String get playerProfileNoStatsMessage;

  /// No description provided for @squadChemistryDetailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Química da escalação'**
  String get squadChemistryDetailTitle;

  /// No description provided for @squadChemistryPlayerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Química do jogador'**
  String get squadChemistryPlayerTitle;

  /// No description provided for @squadChemistrySourceClub.
  ///
  /// In pt, this message translates to:
  /// **'Clube'**
  String get squadChemistrySourceClub;

  /// No description provided for @squadChemistrySourceLeague.
  ///
  /// In pt, this message translates to:
  /// **'Liga'**
  String get squadChemistrySourceLeague;

  /// No description provided for @squadChemistrySourceNation.
  ///
  /// In pt, this message translates to:
  /// **'Nação'**
  String get squadChemistrySourceNation;

  /// No description provided for @squadChemistrySourceManager.
  ///
  /// In pt, this message translates to:
  /// **'Técnico'**
  String get squadChemistrySourceManager;

  /// No description provided for @squadChemistryNoSources.
  ///
  /// In pt, this message translates to:
  /// **'Este jogador não compartilha clube, liga nem nação com nenhum outro titular.'**
  String get squadChemistryNoSources;

  /// No description provided for @squadChemistryOutOfPositionExplain.
  ///
  /// In pt, this message translates to:
  /// **'Fora de posição: não pontua e não conta para a química dos companheiros.'**
  String get squadChemistryOutOfPositionExplain;

  /// No description provided for @squadChemistryCappedNote.
  ///
  /// In pt, this message translates to:
  /// **'Já está no máximo de 3.'**
  String get squadChemistryCappedNote;

  /// No description provided for @squadChemistryRuleNote.
  ///
  /// In pt, this message translates to:
  /// **'Regra {version}.'**
  String squadChemistryRuleNote(String version);

  /// No description provided for @squadChemistryFullPlayers.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Nenhum jogador com química cheia} =1{1 jogador com química cheia} other{{count} jogadores com química cheia}}'**
  String squadChemistryFullPlayers(int count);

  /// No description provided for @squadChemistryLowPlayers.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Nenhum jogador com química zero} =1{1 jogador com química zero} other{{count} jogadores com química zero}}'**
  String squadChemistryLowPlayers(int count);

  /// No description provided for @squadChemistryOutOfPositionCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Ninguém fora de posição} =1{1 jogador fora de posição} other{{count} jogadores fora de posição}}'**
  String squadChemistryOutOfPositionCount(int count);

  /// No description provided for @squadChemistryEmptySlotsNote.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 posição vazia} other{{count} posições vazias}}'**
  String squadChemistryEmptySlotsNote(int count);

  /// No description provided for @squadPrimaryLineupTitle.
  ///
  /// In pt, this message translates to:
  /// **'Escalação Principal'**
  String get squadPrimaryLineupTitle;

  /// No description provided for @squadPrimaryLineupEditAction.
  ///
  /// In pt, this message translates to:
  /// **'Editar escalação'**
  String get squadPrimaryLineupEditAction;

  /// No description provided for @squadPrimaryLineupCreateAction.
  ///
  /// In pt, this message translates to:
  /// **'Montar escalação'**
  String get squadPrimaryLineupCreateAction;

  /// No description provided for @squadPrimaryLineupEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não montou uma escalação para este elenco.'**
  String get squadPrimaryLineupEmpty;

  /// No description provided for @squadOtherLineupsAction.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Ver outra escalação} other{Ver outras {count} escalações}}'**
  String squadOtherLineupsAction(int count);

  /// No description provided for @teamSportsSummaryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resumo'**
  String get teamSportsSummaryTitle;

  /// No description provided for @teamSportsMatches.
  ///
  /// In pt, this message translates to:
  /// **'Partidas'**
  String get teamSportsMatches;

  /// No description provided for @teamSportsWins.
  ///
  /// In pt, this message translates to:
  /// **'Vitórias'**
  String get teamSportsWins;

  /// No description provided for @teamSportsLosses.
  ///
  /// In pt, this message translates to:
  /// **'Derrotas'**
  String get teamSportsLosses;

  /// No description provided for @teamSportsWinRate.
  ///
  /// In pt, this message translates to:
  /// **'Aproveitamento'**
  String get teamSportsWinRate;

  /// No description provided for @teamSportsGoalsFor.
  ///
  /// In pt, this message translates to:
  /// **'Gols'**
  String get teamSportsGoalsFor;

  /// No description provided for @teamSportsGoalsAgainst.
  ///
  /// In pt, this message translates to:
  /// **'Sofridos'**
  String get teamSportsGoalsAgainst;

  /// No description provided for @teamSportsGoalDifference.
  ///
  /// In pt, this message translates to:
  /// **'Saldo'**
  String get teamSportsGoalDifference;

  /// No description provided for @teamSportsRankingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ranking'**
  String get teamSportsRankingTitle;

  /// No description provided for @teamSportsScorersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Artilharia'**
  String get teamSportsScorersTitle;

  /// No description provided for @teamSportsAssistsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Assistências'**
  String get teamSportsAssistsTitle;

  /// No description provided for @teamSportsWeekendLeagueTitle.
  ///
  /// In pt, this message translates to:
  /// **'Weekend League'**
  String get teamSportsWeekendLeagueTitle;

  /// No description provided for @teamSportsRivalsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Division Rivals'**
  String get teamSportsRivalsTitle;

  /// No description provided for @teamSportsActivityTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atividade recente'**
  String get teamSportsActivityTitle;

  /// No description provided for @teamSportsSeeAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver tudo'**
  String get teamSportsSeeAll;

  /// No description provided for @teamSportsSmallSample.
  ///
  /// In pt, this message translates to:
  /// **'Amostra pequena'**
  String get teamSportsSmallSample;

  /// No description provided for @teamSportsNoMatchesYet.
  ///
  /// In pt, this message translates to:
  /// **'Este Time ainda não registrou partidas.'**
  String get teamSportsNoMatchesYet;

  /// No description provided for @teamSportsNoMatchesMember.
  ///
  /// In pt, this message translates to:
  /// **'Sem partidas'**
  String get teamSportsNoMatchesMember;

  /// No description provided for @teamSportsNoScorersYet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum gol registrado ainda.'**
  String get teamSportsNoScorersYet;

  /// No description provided for @teamSportsNoAssistsYet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma assistência registrada ainda.'**
  String get teamSportsNoAssistsYet;

  /// No description provided for @teamSportsNoActivityYet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma partida concluída ainda.'**
  String get teamSportsNoActivityYet;

  /// No description provided for @teamSportsManualRecord.
  ///
  /// In pt, this message translates to:
  /// **'Manual'**
  String get teamSportsManualRecord;

  /// No description provided for @teamSportsNoDivision.
  ///
  /// In pt, this message translates to:
  /// **'Sem divisão'**
  String get teamSportsNoDivision;

  /// No description provided for @teamSportsActivityWin.
  ///
  /// In pt, this message translates to:
  /// **'venceu'**
  String get teamSportsActivityWin;

  /// No description provided for @teamSportsActivityLoss.
  ///
  /// In pt, this message translates to:
  /// **'perdeu'**
  String get teamSportsActivityLoss;

  /// No description provided for @teamSportsAccountsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 Conta} other{{count} Contas}}'**
  String teamSportsAccountsCount(int count);

  /// No description provided for @teamSportsMembersCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 membro} other{{count} membros}}'**
  String teamSportsMembersCount(int count);

  /// No description provided for @teamSportsMatchesCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 partida registrada} other{{count} partidas registradas}}'**
  String teamSportsMatchesCount(int count);

  /// No description provided for @teamSportsRecordLine.
  ///
  /// In pt, this message translates to:
  /// **'{matches}J · {wins}V · {losses}D'**
  String teamSportsRecordLine(int matches, int wins, int losses);

  /// No description provided for @teamSportsMinSampleHint.
  ///
  /// In pt, this message translates to:
  /// **'Ranqueado a partir de {count} partidas.'**
  String teamSportsMinSampleHint(int count);

  /// No description provided for @teamSportsGoalsShort.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 gol} other{{count} gols}}'**
  String teamSportsGoalsShort(int count);

  /// No description provided for @teamSportsAssistsShort.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 assistência} other{{count} assistências}}'**
  String teamSportsAssistsShort(int count);

  /// No description provided for @profileSharingRow.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhamento'**
  String get profileSharingRow;

  /// No description provided for @publicProfileSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade'**
  String get publicProfileSectionTitle;

  /// No description provided for @publicProfileMasterSwitchLabel.
  ///
  /// In pt, this message translates to:
  /// **'Perfil público'**
  String get publicProfileMasterSwitchLabel;

  /// No description provided for @publicProfileMasterSwitchHint.
  ///
  /// In pt, this message translates to:
  /// **'Deixe seu perfil visível por um link público, sem precisar de conta no app.'**
  String get publicProfileMasterSwitchHint;

  /// No description provided for @publicProfileStatusActive.
  ///
  /// In pt, this message translates to:
  /// **'Perfil público: Ativo'**
  String get publicProfileStatusActive;

  /// No description provided for @publicProfileStatusInactive.
  ///
  /// In pt, this message translates to:
  /// **'Perfil público: Inativo'**
  String get publicProfileStatusInactive;

  /// No description provided for @publicProfileSlugLabel.
  ///
  /// In pt, this message translates to:
  /// **'Endereço do seu perfil'**
  String get publicProfileSlugLabel;

  /// No description provided for @publicProfileSlugHint.
  ///
  /// In pt, this message translates to:
  /// **'3 a 24 letras minúsculas, números ou _'**
  String get publicProfileSlugHint;

  /// No description provided for @publicProfileSlugAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Disponível'**
  String get publicProfileSlugAvailable;

  /// No description provided for @publicProfileSlugUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Este endereço já está em uso'**
  String get publicProfileSlugUnavailable;

  /// No description provided for @publicProfileSlugChecking.
  ///
  /// In pt, this message translates to:
  /// **'Verificando…'**
  String get publicProfileSlugChecking;

  /// No description provided for @publicProfileSlugInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Endereço inválido'**
  String get publicProfileSlugInvalid;

  /// No description provided for @publicProfileAccountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Conta pública'**
  String get publicProfileAccountLabel;

  /// No description provided for @publicProfileAccountEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conta selecionada'**
  String get publicProfileAccountEmpty;

  /// No description provided for @publicProfileToggleSquad.
  ///
  /// In pt, this message translates to:
  /// **'Escalação Principal'**
  String get publicProfileToggleSquad;

  /// No description provided for @publicProfileToggleWeekendLeague.
  ///
  /// In pt, this message translates to:
  /// **'Weekend League'**
  String get publicProfileToggleWeekendLeague;

  /// No description provided for @publicProfileToggleRivals.
  ///
  /// In pt, this message translates to:
  /// **'Division Rivals'**
  String get publicProfileToggleRivals;

  /// No description provided for @publicProfileToggleStats.
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas gerais'**
  String get publicProfileToggleStats;

  /// No description provided for @publicProfileCopyLinkAction.
  ///
  /// In pt, this message translates to:
  /// **'Copiar link'**
  String get publicProfileCopyLinkAction;

  /// No description provided for @publicProfileLinkCopied.
  ///
  /// In pt, this message translates to:
  /// **'Link copiado'**
  String get publicProfileLinkCopied;

  /// No description provided for @publicProfileShareAction.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar'**
  String get publicProfileShareAction;

  /// No description provided for @publicProfileShareImageAction.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar imagem'**
  String get publicProfileShareImageAction;

  /// No description provided for @publicProfileShareImageError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível compartilhar a imagem neste dispositivo.'**
  String get publicProfileShareImageError;

  /// No description provided for @publicProfileSaveAction.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get publicProfileSaveAction;

  /// No description provided for @publicProfileSaved.
  ///
  /// In pt, this message translates to:
  /// **'Configurações salvas'**
  String get publicProfileSaved;

  /// No description provided for @publicProfilePreviewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pré-visualização'**
  String get publicProfilePreviewTitle;

  /// No description provided for @publicProfilePageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get publicProfilePageTitle;

  /// No description provided for @publicProfileNotFoundTitle.
  ///
  /// In pt, this message translates to:
  /// **'Perfil não encontrado'**
  String get publicProfileNotFoundTitle;

  /// No description provided for @publicProfileNotFoundMessage.
  ///
  /// In pt, this message translates to:
  /// **'Este link não existe ou não está mais disponível.'**
  String get publicProfileNotFoundMessage;

  /// No description provided for @publicProfileShareAccountCta.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar esta Conta'**
  String get publicProfileShareAccountCta;

  /// No description provided for @publicProfileShareSquadCta.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar escalação'**
  String get publicProfileShareSquadCta;

  /// No description provided for @publicProfileEnableFirstMessage.
  ///
  /// In pt, this message translates to:
  /// **'Ative o perfil público para compartilhar sua escalação.'**
  String get publicProfileEnableFirstMessage;

  /// No description provided for @publicProfileGoToSettingsAction.
  ///
  /// In pt, this message translates to:
  /// **'Ir para Compartilhamento'**
  String get publicProfileGoToSettingsAction;

  /// No description provided for @publicProfileEditSharingCta.
  ///
  /// In pt, this message translates to:
  /// **'Editar compartilhamento'**
  String get publicProfileEditSharingCta;

  /// No description provided for @publicProfileNoAccountsHint.
  ///
  /// In pt, this message translates to:
  /// **'Crie um Elenco antes de compartilhar.'**
  String get publicProfileNoAccountsHint;

  /// No description provided for @errorPublicProfileInvalidSlug.
  ///
  /// In pt, this message translates to:
  /// **'Endereço inválido. Use 3-24 letras minúsculas, números ou _.'**
  String get errorPublicProfileInvalidSlug;

  /// No description provided for @errorPublicProfileReservedSlug.
  ///
  /// In pt, this message translates to:
  /// **'Este endereço é reservado, escolha outro.'**
  String get errorPublicProfileReservedSlug;

  /// No description provided for @errorPublicProfileSlugTaken.
  ///
  /// In pt, this message translates to:
  /// **'Este endereço já está em uso.'**
  String get errorPublicProfileSlugTaken;

  /// No description provided for @errorPublicProfileSlugRequired.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um endereço antes de ativar o perfil público.'**
  String get errorPublicProfileSlugRequired;

  /// No description provided for @validationPublicProfileSlugRequired.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um endereço para o perfil.'**
  String get validationPublicProfileSlugRequired;

  /// No description provided for @validationPublicProfileSlugTooShort.
  ///
  /// In pt, this message translates to:
  /// **'O endereço precisa ter pelo menos {min} caracteres.'**
  String validationPublicProfileSlugTooShort(int min);

  /// No description provided for @validationPublicProfileSlugTooLong.
  ///
  /// In pt, this message translates to:
  /// **'O endereço pode ter no máximo {max} caracteres.'**
  String validationPublicProfileSlugTooLong(int max);

  /// No description provided for @validationPublicProfileSlugInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Use só letras minúsculas, números ou _.'**
  String get validationPublicProfileSlugInvalid;

  /// No description provided for @errorSoleOwnerBlocksAccountDeletion.
  ///
  /// In pt, this message translates to:
  /// **'Você é dono único de um time com outros integrantes. Remova os outros integrantes ou aguarde suporte a transferência de posse antes de excluir sua conta.'**
  String get errorSoleOwnerBlocksAccountDeletion;

  /// No description provided for @profileLegalTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sobre e legal'**
  String get profileLegalTitle;

  /// No description provided for @aboutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sobre'**
  String get aboutTitle;

  /// No description provided for @aboutDescription.
  ///
  /// In pt, this message translates to:
  /// **'FIFA Queue organiza a fila de busca de partida, elencos e estatísticas do seu time de EA SPORTS FC.'**
  String get aboutDescription;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Política de Privacidade'**
  String get privacyPolicyTitle;

  /// No description provided for @termsOfUseTitle.
  ///
  /// In pt, this message translates to:
  /// **'Termos de Uso'**
  String get termsOfUseTitle;

  /// No description provided for @legalUpdatedAt.
  ///
  /// In pt, this message translates to:
  /// **'Atualizado em {date}'**
  String legalUpdatedAt(String date);

  /// No description provided for @deleteAccountRow.
  ///
  /// In pt, this message translates to:
  /// **'Excluir minha conta'**
  String get deleteAccountRow;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir conta'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarningTitle.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação é permanente'**
  String get deleteAccountWarningTitle;

  /// No description provided for @deleteAccountWarningMessage.
  ///
  /// In pt, this message translates to:
  /// **'Ao excluir sua conta, você perde acesso a tudo o que está listado abaixo. Não é possível desfazer ou recuperar depois.'**
  String get deleteAccountWarningMessage;

  /// No description provided for @deleteAccountConsequenceFcAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Todos os seus elencos (Contas EA FC) e a divisão de Rivals registrada'**
  String get deleteAccountConsequenceFcAccounts;

  /// No description provided for @deleteAccountConsequenceSquads.
  ///
  /// In pt, this message translates to:
  /// **'Suas escalações (Squad Builder)'**
  String get deleteAccountConsequenceSquads;

  /// No description provided for @deleteAccountConsequenceHistory.
  ///
  /// In pt, this message translates to:
  /// **'Sua participação nos times de que você faz parte'**
  String get deleteAccountConsequenceHistory;

  /// No description provided for @deleteAccountConsequenceStats.
  ///
  /// In pt, this message translates to:
  /// **'Seu histórico e estatísticas pessoais de partidas'**
  String get deleteAccountConsequenceStats;

  /// No description provided for @deleteAccountConsequencePreferences.
  ///
  /// In pt, this message translates to:
  /// **'Suas preferências de notificação e dispositivos registrados'**
  String get deleteAccountConsequencePreferences;

  /// No description provided for @deleteAccountConsequencePublicProfile.
  ///
  /// In pt, this message translates to:
  /// **'Seu perfil público, se estiver ativado'**
  String get deleteAccountConsequencePublicProfile;

  /// No description provided for @deleteAccountTypeToConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Para confirmar, digite {word} no campo abaixo.'**
  String deleteAccountTypeToConfirm(String word);

  /// No description provided for @deleteAccountConfirmWord.
  ///
  /// In pt, this message translates to:
  /// **'EXCLUIR'**
  String get deleteAccountConfirmWord;

  /// No description provided for @deleteAccountAction.
  ///
  /// In pt, this message translates to:
  /// **'Excluir minha conta permanentemente'**
  String get deleteAccountAction;

  /// No description provided for @homeFcAccountEyebrow.
  ///
  /// In pt, this message translates to:
  /// **'CONTA FC ATIVA'**
  String get homeFcAccountEyebrow;

  /// No description provided for @homeFcAccountSwitchAction.
  ///
  /// In pt, this message translates to:
  /// **'Trocar'**
  String get homeFcAccountSwitchAction;

  /// No description provided for @homeFcAccountNoTeams.
  ///
  /// In pt, this message translates to:
  /// **'Ainda sem time'**
  String get homeFcAccountNoTeams;

  /// No description provided for @homeFcAccountTeamCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Em 1 time} other{Em {count} times}}'**
  String homeFcAccountTeamCount(int count);

  /// No description provided for @homeNoTeamTitle.
  ///
  /// In pt, this message translates to:
  /// **'Entre em um time'**
  String get homeNoTeamTitle;

  /// No description provided for @homeNoTeamMessage.
  ///
  /// In pt, this message translates to:
  /// **'Buscar partida exige um time. Rivals e Weekend League você já pode usar.'**
  String get homeNoTeamMessage;

  /// No description provided for @pendingMatchSkipAction.
  ///
  /// In pt, this message translates to:
  /// **'Não informar esta partida'**
  String get pendingMatchSkipAction;

  /// No description provided for @pendingMatchSkipConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não informar o resultado?'**
  String get pendingMatchSkipConfirmTitle;

  /// No description provided for @pendingMatchSkipConfirmMessage.
  ///
  /// In pt, this message translates to:
  /// **'A partida sai daqui sem contar como vitória nem derrota. Você pode buscar outra normalmente.'**
  String get pendingMatchSkipConfirmMessage;

  /// No description provided for @historyResultNotInformed.
  ///
  /// In pt, this message translates to:
  /// **'Resultado não informado'**
  String get historyResultNotInformed;

  /// No description provided for @weekendLeagueWeekPickerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar semana'**
  String get weekendLeagueWeekPickerTitle;

  /// No description provided for @weekendLeagueChangeWeekAction.
  ///
  /// In pt, this message translates to:
  /// **'Trocar'**
  String get weekendLeagueChangeWeekAction;

  /// No description provided for @weekendLeagueCurrentWeekBadge.
  ///
  /// In pt, this message translates to:
  /// **'Em andamento'**
  String get weekendLeagueCurrentWeekBadge;

  /// No description provided for @rivalsSetDivisionAction.
  ///
  /// In pt, this message translates to:
  /// **'Informar'**
  String get rivalsSetDivisionAction;

  /// No description provided for @controlNoTeamTitle.
  ///
  /// In pt, this message translates to:
  /// **'Você precisa de um time'**
  String get controlNoTeamTitle;

  /// No description provided for @controlNoTeamMessage.
  ///
  /// In pt, this message translates to:
  /// **'A fila é do time. Entre em um ou crie o seu para começar a buscar.'**
  String get controlNoTeamMessage;

  /// No description provided for @controlNoTeamAction.
  ///
  /// In pt, this message translates to:
  /// **'Ver times'**
  String get controlNoTeamAction;

  /// No description provided for @statsEmptyScorersMessage.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum gol registrado ainda.'**
  String get statsEmptyScorersMessage;

  /// No description provided for @statsEmptyAssistsMessage.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma assistência registrada ainda.'**
  String get statsEmptyAssistsMessage;

  /// No description provided for @pendingMatchesCardTitle.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 partida sem resultado} other{{count} partidas sem resultado}}'**
  String pendingMatchesCardTitle(int count);

  /// No description provided for @pendingMatchesCardLatest.
  ///
  /// In pt, this message translates to:
  /// **'Mais recente: {mode} · {date} às {time}'**
  String pendingMatchesCardLatest(String mode, String date, String time);

  /// No description provided for @pendingMatchesOpenListAction.
  ///
  /// In pt, this message translates to:
  /// **'Ver partidas'**
  String get pendingMatchesOpenListAction;

  /// No description provided for @pendingMatchesDismissAllAction.
  ///
  /// In pt, this message translates to:
  /// **'Não informar'**
  String get pendingMatchesDismissAllAction;

  /// No description provided for @pendingMatchesDismissAllTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não informar nenhuma?'**
  String get pendingMatchesDismissAllTitle;

  /// No description provided for @pendingMatchesDismissAllMessage.
  ///
  /// In pt, this message translates to:
  /// **'Todas saem da lista sem contar como vitória nem derrota.'**
  String get pendingMatchesDismissAllMessage;

  /// No description provided for @pendingMatchesSheetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Partidas sem resultado'**
  String get pendingMatchesSheetTitle;

  /// No description provided for @pendingMatchesSheetMessage.
  ///
  /// In pt, this message translates to:
  /// **'Informe o que quiser. Deixar em branco não bloqueia nada.'**
  String get pendingMatchesSheetMessage;

  /// No description provided for @pendingMatchesSkipOneAction.
  ///
  /// In pt, this message translates to:
  /// **'Não informar'**
  String get pendingMatchesSkipOneAction;

  /// No description provided for @pendingMatchesAllClear.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma partida pendente.'**
  String get pendingMatchesAllClear;

  /// No description provided for @errorWeekendLeagueLimit.
  ///
  /// In pt, this message translates to:
  /// **'A Weekend League tem 15 partidas: vitórias e derrotas somadas não podem passar disso.'**
  String get errorWeekendLeagueLimit;

  /// No description provided for @squadNoneSelectedHint.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um squad para esta busca'**
  String get squadNoneSelectedHint;
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
