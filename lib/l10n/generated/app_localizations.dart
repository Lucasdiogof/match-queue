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

  /// No description provided for @comingSoonStage.
  ///
  /// In pt, this message translates to:
  /// **'Previsto para a {stage}'**
  String comingSoonStage(String stage);

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

  /// No description provided for @authWelcomeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Entre para coordenar seu time'**
  String get authWelcomeTitle;

  /// No description provided for @authWelcomeMessage.
  ///
  /// In pt, this message translates to:
  /// **'As telas de autenticação serão construídas na próxima etapa. A arquitetura de auth já está pronta.'**
  String get authWelcomeMessage;

  /// No description provided for @authLocalModeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Modo local de desenvolvimento'**
  String get authLocalModeTitle;

  /// No description provided for @authLocalModeMessage.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum projeto Supabase foi configurado. Você pode entrar com uma sessão local para navegar pela estrutura do app.'**
  String get authLocalModeMessage;

  /// No description provided for @authLocalModeAction.
  ///
  /// In pt, this message translates to:
  /// **'Entrar em modo local'**
  String get authLocalModeAction;

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
