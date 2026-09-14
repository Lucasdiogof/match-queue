// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'FIFA Queue';

  @override
  String get appTagline => 'Uno a la vez en la fila.';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionRetry => 'Intentar de nuevo';

  @override
  String get actionClose => 'Cerrar';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionCopy => 'Copiar';

  @override
  String get actionShare => 'Compartir';

  @override
  String get actionBack => 'Volver';

  @override
  String get actionNotNow => 'Ahora no';

  @override
  String get actionSignOut => 'Salir';

  @override
  String get profileSignOutConfirmTitle => '¿Cerrar sesión?';

  @override
  String get profileSignOutConfirmMessage =>
      'Puedes volver a entrar cuando quieras con tu correo y contraseña.';

  @override
  String get actionEdit => 'Editar';

  @override
  String get navCentral => 'Central';

  @override
  String get navControl => 'Jugar';

  @override
  String get navTeam => 'Equipos';

  @override
  String get navHistory => 'Historial';

  @override
  String get navProfile => 'Perfil';

  @override
  String get comingSoonTitle => 'En construcción';

  @override
  String get comingSoonMessage =>
      'Esta área se construirá en las próximas etapas del proyecto.';

  @override
  String get comingSoonNextStage => 'Etapa 3';

  @override
  String get startEyebrow => 'FIFA QUEUE';

  @override
  String get startTitle => 'Resumen';

  @override
  String get startSubtitle => 'Tu equipo y tu semana en un solo lugar.';

  @override
  String get startShortcutsTitle => 'Accesos rápidos';

  @override
  String get controlDiscoverCardsTitle => 'Explorar cartas';

  @override
  String get controlDiscoverCardsSubtitle =>
      'Jugadores destacados del catálogo completo.';

  @override
  String get controlDiscoverClubsTitle => 'Clubes';

  @override
  String get controlDiscoverClubsSubtitle =>
      'Explora los clubes del catálogo FC27.';

  @override
  String get controlEmptyTitle => '¿Listo para entrar a la cancha?';

  @override
  String get controlEmptyMessage =>
      'Elige una cuenta y un modo para empezar a buscar partido.';

  @override
  String get teamTitle => 'Mi equipo';

  @override
  String get teamSubtitle => 'Jugadores, roles e invitaciones.';

  @override
  String get teamsListSubtitle => 'Tus equipos y su estado operacional.';

  @override
  String get teamsMineTab => 'Mis Equipos';

  @override
  String get teamsExploreTab => 'Explorar';

  @override
  String get teamsExploreEmptyTitle => 'Todavía no hay equipos públicos';

  @override
  String get teamsExploreEmptyMessage =>
      'Los equipos públicos aparecen aquí cuando existan.';

  @override
  String get teamVisibilitySectionTitle => 'Visibilidad';

  @override
  String get teamVisibilityPublic => 'Público';

  @override
  String get teamVisibilityPrivate => 'Privado';

  @override
  String get teamVisibilityPublicHint =>
      'Aparece en Explorar y tiene página pública.';

  @override
  String get teamVisibilityPrivateHint =>
      'No aparece en Explorar ni en búsquedas públicas.';

  @override
  String get teamPublicPageMembersTitle => 'Miembros';

  @override
  String get teamPublicPageRecordTitle => 'Récord';

  @override
  String teamPublicPageRecordLine(int wins, int losses) {
    return '$wins victorias • $losses derrotas';
  }

  @override
  String get teamPublicPageNotFoundTitle => 'Equipo no encontrado';

  @override
  String get teamPublicPageNotFoundMessage =>
      'Este equipo no existe o no está disponible públicamente.';

  @override
  String get authSignIn => 'Entrar';

  @override
  String get authSignUp => 'Crear cuenta';

  @override
  String get authForgotPassword => 'Olvidé mi contraseña';

  @override
  String get authEmail => 'Correo electrónico';

  @override
  String get authPassword => 'Contraseña';

  @override
  String get authRevealPassword => 'Mostrar contraseña';

  @override
  String get authHidePassword => 'Ocultar contraseña';

  @override
  String authSignedInAs(String email) {
    return 'Conectado como $email';
  }

  @override
  String get profilePreferencesTitle => 'Preferencias';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get languageSystem => 'Idioma del dispositivo';

  @override
  String get languagePortuguese => 'Portugués (Brasil)';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageSpanish => 'Español';

  @override
  String get inviteJoinTeam => 'Entrar al equipo';

  @override
  String get inviteOpenTeam => 'Abrir equipo';

  @override
  String get inviteJoinMessage => 'Te invitaron a entrar en este equipo.';

  @override
  String get inviteAlreadyMemberMessage => 'Ya formas parte de este equipo.';

  @override
  String get inviteSignInToAccept => 'Entrar para aceptar';

  @override
  String get inviteCreateAccount => 'Crear cuenta';

  @override
  String get inviteInvalidTitle => 'Invitación no encontrada';

  @override
  String get inviteRevokedTitle => 'Este enlace ya no está activo';

  @override
  String get inviteExpiredTitle => 'Este enlace ha expirado';

  @override
  String get inviteExhaustedTitle => 'Este enlace alcanzó su límite de usos';

  @override
  String get inviteEnterCodeMessage =>
      'Pega o escribe el código que recibiste.';

  @override
  String get inviteCodeFieldLabel => 'Código de invitación';

  @override
  String get inviteCodeFieldInvalid => 'Código inválido.';

  @override
  String get inviteSectionTitle => 'Invitar jugadores';

  @override
  String get inviteSectionSubtitle =>
      'Comparte este enlace con quien quieras agregar al equipo.';

  @override
  String get inviteLinkCopied => 'Enlace copiado.';

  @override
  String get inviteShareSubject => 'Invitación al equipo en FIFA Queue';

  @override
  String inviteShareMessage(String url) {
    return 'Entra a mi equipo en FIFA Queue: $url';
  }

  @override
  String inviteShareMessageCodeOnly(String code) {
    return 'Entra a mi equipo en FIFA Queue con el código: $code';
  }

  @override
  String get inviteManageTitle => 'Gestionar enlace';

  @override
  String get inviteCreateLinkAction => 'Crear enlace de invitación';

  @override
  String get inviteUnavailableMessage =>
      'El enlace de invitación de este equipo aún no está disponible.';

  @override
  String get inviteRotateAction => 'Generar nuevo enlace';

  @override
  String get inviteRotateConfirmTitle => '¿Generar un nuevo enlace?';

  @override
  String get inviteRotateConfirmMessage =>
      'El enlace actual dejará de funcionar de inmediato.';

  @override
  String get inviteRevokeAction => 'Desactivar enlace';

  @override
  String get inviteRevokeConfirmTitle => '¿Desactivar enlace?';

  @override
  String get inviteRevokeConfirmMessage =>
      'Nadie podrá entrar al equipo usando el enlace actual.';

  @override
  String queuePositionLabel(int position) {
    final intl.NumberFormat positionNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String positionString = positionNumberFormat.format(position);

    return '#$positionString en la fila';
  }

  @override
  String get errorNetwork =>
      'Sin conexión. Revisa tu internet e intenta de nuevo.';

  @override
  String get errorTimeout => 'La operación tardó demasiado. Intenta de nuevo.';

  @override
  String get errorServer =>
      'Algo falló en el servidor. Intenta de nuevo en unos instantes.';

  @override
  String get errorPermission => 'No tienes permiso para hacer esto.';

  @override
  String get errorNotFound => 'No encontramos lo que buscabas.';

  @override
  String get errorConflict =>
      'Esta acción entra en conflicto con el estado actual. Actualiza e intenta de nuevo.';

  @override
  String get errorUnexpected => 'Error inesperado. Intenta de nuevo.';

  @override
  String errorConfiguration(String keys) {
    return 'Falta configuración: $keys';
  }

  @override
  String get errorInvalidCredentials => 'Correo o contraseña incorrectos.';

  @override
  String get errorEmailAlreadyRegistered => 'Este correo ya está registrado.';

  @override
  String get errorWeakPassword => 'Elige una contraseña más fuerte.';

  @override
  String get errorUserNotFound => 'Cuenta no encontrada.';

  @override
  String get errorSessionExpired => 'Tu sesión expiró. Entra de nuevo.';

  @override
  String get errorEmailConfirmationRequired =>
      'Enviamos un enlace de confirmación a tu correo. Confírmalo para entrar.';

  @override
  String get errorAuthUnknown => 'No fue posible completar la autenticación.';

  @override
  String get startupErrorTitle => 'No se pudo iniciar FIFA Queue';

  @override
  String startupErrorMessage(String keys) {
    return 'Faltan variables de entorno obligatorias: $keys';
  }

  @override
  String environmentBadge(String environment) {
    return 'Entorno: $environment';
  }

  @override
  String get notFoundTitle => 'Página no encontrada';

  @override
  String get notFoundMessage =>
      'La dirección abierta no existe en esta aplicación.';

  @override
  String get notFoundAction => 'Ir al inicio';

  @override
  String get loginTitle => 'Entra en tu cuenta';

  @override
  String get loginNoAccount => '¿Todavía no tienes una cuenta?';

  @override
  String get signUpTitle => 'Crea tu cuenta';

  @override
  String get signUpSubtitle => 'Elige cómo te va a llamar tu equipo.';

  @override
  String get signUpHaveAccount => '¿Ya tienes una cuenta?';

  @override
  String get authDisplayName => 'Nombre o apodo';

  @override
  String get authDisplayNameHint => 'Lucas, ratowrld, Panda...';

  @override
  String get authEmailHint => 'email@ejemplo.com';

  @override
  String get authConfirmPassword => 'Confirmar contraseña';

  @override
  String authPasswordHelper(int count) {
    return 'Mínimo de $count caracteres';
  }

  @override
  String get forgotPasswordTitle => 'Recuperar acceso';

  @override
  String get forgotPasswordMessage =>
      'Escribe el correo de tu cuenta y te enviaremos el enlace para crear una contraseña nueva.';

  @override
  String get forgotPasswordAction => 'Enviar instrucciones';

  @override
  String get forgotPasswordSentTitle => 'Revisa tu correo';

  @override
  String get forgotPasswordSentMessage =>
      'Si hay una cuenta asociada a este correo, recibirás las instrucciones para restablecer la contraseña.';

  @override
  String get forgotPasswordBackToLogin => 'Volver al inicio de sesión';

  @override
  String get forgotPasswordResend => 'Reenviar';

  @override
  String get forgotPasswordNotReceived => '¿No recibiste el correo?';

  @override
  String get forgotPasswordResending => 'Reenviando...';

  @override
  String get forgotPasswordResendSuccess => 'Correo reenviado.';

  @override
  String get resetPasswordTitle => 'Definir contraseña nueva';

  @override
  String get resetPasswordMessage =>
      'Elige una contraseña nueva para volver a usar FIFA Queue.';

  @override
  String get resetPasswordNewPassword => 'Contraseña nueva';

  @override
  String get resetPasswordAction => 'Guardar contraseña nueva';

  @override
  String get resetPasswordSuccess =>
      'Contraseña actualizada. Bienvenido de vuelta.';

  @override
  String get resetPasswordInvalidTitle => 'Enlace caducado o inválido';

  @override
  String get resetPasswordInvalidMessage =>
      'Pide un enlace de recuperación nuevo para definir tu contraseña.';

  @override
  String get validationEmailRequired => 'Escribe tu correo.';

  @override
  String get validationEmailInvalid => 'Escribe un correo válido.';

  @override
  String get validationPasswordRequired => 'Escribe tu contraseña.';

  @override
  String validationPasswordTooShort(int count) {
    return 'La contraseña necesita al menos $count caracteres.';
  }

  @override
  String get validationPasswordConfirmationRequired =>
      'Confirma tu contraseña.';

  @override
  String get validationPasswordConfirmationMismatch =>
      'Las contraseñas no coinciden.';

  @override
  String get validationDisplayNameRequired => 'Escribe un nombre o apodo.';

  @override
  String validationDisplayNameTooShort(int count) {
    return 'Usa al menos $count caracteres.';
  }

  @override
  String validationDisplayNameTooLong(int count) {
    return 'Usa como máximo $count caracteres.';
  }

  @override
  String get errorTooManyRequests =>
      'Demasiados intentos. Espera un momento e intenta de nuevo.';

  @override
  String get errorSignUpFailed => 'No fue posible crear tu cuenta.';

  @override
  String homeGreeting(String name) {
    return 'Hola, $name';
  }

  @override
  String get homeSearchPlaceholderTitle =>
      'La búsqueda coordinada llega en la Etapa 3';

  @override
  String get homeSearchPlaceholderMessage =>
      'Primero creamos equipos y miembros. Después de eso, solo un jugador del equipo busca partido a la vez.';

  @override
  String get profileAccountSection => 'Cuenta';

  @override
  String get profileDisplayNameLabel => 'Nombre o apodo';

  @override
  String get profileEmailLabel => 'Correo electrónico';

  @override
  String get profileEditName => 'Editar nombre';

  @override
  String get profileEditNameTitle => '¿Cómo te llamamos?';

  @override
  String profileDisplayNameCounter(int count, int max) {
    return '$count/$max';
  }

  @override
  String get profileSaved => 'Nombre actualizado.';

  @override
  String get profileLoadErrorTitle => 'No fue posible cargar tu perfil';

  @override
  String profileMemberSince(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMM(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'En FIFA Queue desde $dateString';
  }

  @override
  String get teamNoTeamTitle => 'Todavía no formas parte de un equipo';

  @override
  String get teamNoTeamMessage =>
      'Crea tu equipo o únete con un código de invitación para empezar.';

  @override
  String get historyNoTeamMessage =>
      'Sin equipo no hay historial que mostrar. Crea el tuyo o únete con un código de invitación para empezar a registrar búsquedas y partidos.';

  @override
  String get teamCreateCta => 'Crear equipo';

  @override
  String get teamHaveInviteCode => 'Tengo un código de invitación';

  @override
  String get teamCreateTitle => 'Crea tu equipo';

  @override
  String get teamCreateSubtitle =>
      'Podrás ajustar colores, logo y duración de la búsqueda después.';

  @override
  String get teamCreateFcAccountsSectionTitle =>
      '¿Qué Cuentas FC forman parte de este equipo?';

  @override
  String get teamNameLabel => 'Nombre del equipo';

  @override
  String get teamNameHint => 'Falcons FC';

  @override
  String get teamTagLabel => 'Tag (opcional)';

  @override
  String get teamTagHint => 'FLC';

  @override
  String get teamTagHelper => '2 a 6 letras o números';

  @override
  String get teamCreateAction => 'Crear equipo';

  @override
  String get teamCreateAnother => 'Crear otro equipo';

  @override
  String get teamMembersTitle => 'Miembros';

  @override
  String get teamsListEmptyMessage =>
      'Todavía no formas parte de ningún equipo.';

  @override
  String get teamDetailPlayersTitle => 'Jugadores';

  @override
  String get playerProfileTitle => 'Perfil del jugador';

  @override
  String get playerProfileAccountLabel => 'Cuenta';

  @override
  String get playerProfileNoAccountMessage =>
      'Este jugador no tiene una cuenta vinculada a este equipo.';

  @override
  String get playerProfileSquadLabel => 'Escuadra principal';

  @override
  String get playerProfileSquadNoneMessage =>
      'Todavía no hay una escuadra armada.';

  @override
  String playerProfileCompletenessLabel(int count, int total) {
    return '$count/$total titulares';
  }

  @override
  String get playerProfileSelectAccountTitle =>
      'Este jugador tiene más de una cuenta en este equipo';

  @override
  String get playerProfileWeekendLeagueEmptyMessage =>
      'No hay eventos de Champions registrados.';

  @override
  String playerProfileWeekendLeagueRecordLabel(int wins, int losses) {
    return '${wins}G–${losses}P';
  }

  @override
  String teamMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadores',
      one: '1 jugador',
      zero: 'Ningún jugador',
    );
    return '$_temp0';
  }

  @override
  String get teamRoleOwner => 'Dueño';

  @override
  String get teamRoleManager => 'Gerente';

  @override
  String get teamRolePlayer => 'Jugador';

  @override
  String get teamYou => 'Tú';

  @override
  String get teamManageAction => 'Ajustes del equipo';

  @override
  String get teamEditTitle => 'Editar equipo';

  @override
  String get teamSwitchTitle => 'Tus equipos';

  @override
  String get teamSwitchAction => 'Cambiar de equipo';

  @override
  String teamActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activos',
      one: '1 activo',
      zero: '0 activos',
    );
    return '$_temp0';
  }

  @override
  String get teamSettingsInfoTitle => 'Información';

  @override
  String get teamSearchDurationLabel => 'Duración de búsqueda predeterminada';

  @override
  String get teamSearchDurationHelper =>
      'Tiempo que cada jugador permanece al frente de la cola.';

  @override
  String get teamSearchDurationReadOnlyHelper =>
      'Solo el dueño o un admin puede cambiar esto.';

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
  String get teamLoadErrorTitle => 'No fue posible cargar tus equipos';

  @override
  String get teamMembersErrorTitle => 'No fue posible cargar los miembros';

  @override
  String get validationTeamNameRequired => 'Ingresa el nombre del equipo.';

  @override
  String validationTeamNameTooShort(int count) {
    return 'Usa al menos $count caracteres.';
  }

  @override
  String validationTeamNameTooLong(int count) {
    return 'Usa como máximo $count caracteres.';
  }

  @override
  String validationTeamTagTooShort(int count) {
    return 'La tag necesita al menos $count caracteres.';
  }

  @override
  String validationTeamTagTooLong(int count) {
    return 'La tag puede tener como máximo $count caracteres.';
  }

  @override
  String get validationTeamTagInvalid => 'Usa solo letras y números.';

  @override
  String get errorTeamNameInvalid => 'Elige un nombre de equipo válido.';

  @override
  String get errorTeamTagInvalid => 'Elige una tag válida.';

  @override
  String get errorTeamSearchDurationInvalid =>
      'Elige una duración de búsqueda válida.';

  @override
  String get errorTeamNotFound => 'Equipo no encontrado.';

  @override
  String get errorAlreadyTeamMember => 'Ya formas parte de este equipo.';

  @override
  String get errorDuplicateTeamRequest => 'Ya existe una solicitud pendiente.';

  @override
  String get errorTeamRequestNotFound => 'Esta solicitud ya no existe.';

  @override
  String get errorTeamPermissionDenied =>
      'No tienes permiso para gestionar este equipo.';

  @override
  String get errorTeamProfileMissing =>
      'Completa tu perfil antes de crear un equipo.';

  @override
  String get errorInviteNotFound => 'Invitación no encontrada.';

  @override
  String get errorInviteNotActive => 'Esta invitación ya no es válida.';

  @override
  String get errorInviteExpired => 'Esta invitación ha expirado.';

  @override
  String get errorInviteExhausted =>
      'Esta invitación alcanzó su límite de usos.';

  @override
  String get errorInviteGenerationFailed =>
      'No fue posible generar el enlace de invitación. Inténtalo de nuevo.';

  @override
  String get errorInvitePermissionDenied =>
      'No tienes permiso para gestionar la invitación de este equipo.';

  @override
  String get errorMatchmakingNoActiveSearch =>
      'No hay ninguna búsqueda activa en este momento.';

  @override
  String get errorMatchmakingNotCurrentSearcher =>
      'Ya no eres quien está buscando partida.';

  @override
  String get errorMatchmakingAlreadyInOtherState =>
      'Ya estás en otro estado de la cola.';

  @override
  String get errorMatchmakingTeamInactive =>
      'Este equipo está inactivo en este momento.';

  @override
  String get errorMatchmakingNotInQueue =>
      'No estás en la fila de este equipo.';

  @override
  String get errorMatchmakingNoActiveSearchToPrioritize =>
      'Nadie está buscando partida por este equipo ahora.';

  @override
  String get errorGameCooldown => 'Espera un momento antes de buscar de nuevo.';

  @override
  String get errorGameMatchNotFound => 'Partida no encontrada.';

  @override
  String get errorGameMatchAlreadyFinished => 'Esta partida ya fue finalizada.';

  @override
  String get errorGameInvalidMode => 'Modo de juego inválido.';

  @override
  String get errorGameInvalidResult =>
      'Indica un resultado o un marcador sin empate.';

  @override
  String get matchmakingIdleTitle => 'Nadie está buscando partida';

  @override
  String get matchmakingIdleMessage =>
      'Toca buscar partida para empezar. Todo el equipo lo ve en cuanto alguien entra en la cola.';

  @override
  String get matchmakingSearchAction => 'Buscar partida';

  @override
  String get matchmakingJoinQueueAction => 'Entrar en la cola';

  @override
  String get matchmakingCancelAction => 'Cancelar';

  @override
  String get matchmakingLeaveQueueAction => 'Salir de la cola';

  @override
  String get matchmakingMatchFoundAction => 'La encontré';

  @override
  String get matchmakingSearchingSelfTitle => 'Buscando partida';

  @override
  String get matchmakingSearchingSelfMessage =>
      'Cuando entres en el partido, marca que lo encontraste.';

  @override
  String get matchmakingSearchingOtherTitle => 'Alguien está buscando partida';

  @override
  String matchmakingQueuePositionLabel(int position) {
    return 'Posición $position en la cola';
  }

  @override
  String get matchmakingQueueSectionTitle => 'Cola de espera';

  @override
  String get matchmakingQueueEmptyMessage => 'Nadie en la cola.';

  @override
  String get matchmakingYouBadge => 'Tú';

  @override
  String get matchmakingYourTurnTitle => '¡Tu turno de buscar!';

  @override
  String get matchmakingBottomSheetTitle => 'Búsqueda en curso';

  @override
  String matchmakingBottomSheetMessage(String teamName) {
    return 'Alguien está buscando partida por el Equipo $teamName.';
  }

  @override
  String matchmakingPlayerLabel(int position) {
    return 'Jugador $position';
  }

  @override
  String matchmakingCooldownLabel(int seconds) {
    return 'Espera ${seconds}s';
  }

  @override
  String get matchmakingRequestPriorityAction => 'Solicitar prioridad';

  @override
  String get matchmakingPriorityRequestedConfirmation => 'Prioridad solicitada';

  @override
  String matchmakingSearchingElsewhereMessage(String teamName) {
    return 'Estás buscando partida por el Equipo $teamName.';
  }

  @override
  String get matchmakingNotLinkedMessage =>
      'Vincula esta Cuenta FC a este equipo para poder buscar partida.';

  @override
  String get matchmakingLinkAccountAction => 'Vincular cuenta al equipo';

  @override
  String get notificationsSectionTitle => 'Notificaciones';

  @override
  String get notificationsToggleYourTurn => 'Tu turno de buscar';

  @override
  String get notificationsToggleYourTurnHint =>
      'Cuando llegue tu turno en la cola del equipo.';

  @override
  String get notificationsToggleExpiring => 'Quedan 30 segundos';

  @override
  String get notificationsToggleExpiringHint =>
      'Un aviso antes de que tu búsqueda expire.';

  @override
  String get notificationsToggleExpired => 'Tiempo de búsqueda terminado';

  @override
  String get notificationsToggleExpiredHint =>
      'Cuando tu búsqueda termina sin partido.';

  @override
  String get notificationsEnableCta => 'Activar notificaciones';

  @override
  String get notificationsPermissionDeniedHint =>
      'Las notificaciones están bloqueadas. Actívalas en los ajustes del sistema.';

  @override
  String get notificationsUnsupportedHint =>
      'Este dispositivo aún no recibe notificaciones push.';

  @override
  String get notificationsEnableTitle => 'No te pierdas tu turno';

  @override
  String get notificationsEnableMessage =>
      'Activa las notificaciones para saber al instante cuándo es tu turno de buscar partido, incluso con la app cerrada.';

  @override
  String get notificationsChannelQueueAlertsName => 'Alertas de la cola';

  @override
  String get notificationsChannelQueueAlertsDescription =>
      'Avisos sobre tu turno de buscar y el progreso de tu búsqueda.';

  @override
  String get notificationsChannelAppUpdatesName => 'Actualizaciones del equipo';

  @override
  String get notificationsChannelAppUpdatesDescription =>
      'Nuevos miembros, ranking, Champions y Rivals.';

  @override
  String get notificationsCategoryMatchmaking => 'Matchmaking';

  @override
  String get notificationsCategoryMatchmakingHint =>
      'Tu turno, avisos de expiración de la búsqueda.';

  @override
  String get notificationsCategoryTeams => 'Equipos';

  @override
  String get notificationsCategoryTeamsHint => 'Nuevos miembros en el equipo.';

  @override
  String get notificationsCategoryWeekendLeague => 'Champions';

  @override
  String get notificationsCategoryWeekendLeagueHint =>
      'Cuando termina el Champions.';

  @override
  String get notificationsCategoryRivals => 'Rivals';

  @override
  String get notificationsCategoryRivalsHint =>
      'Una cuenta del equipo cambia de división.';

  @override
  String get notificationsCategoryRankings => 'Rankings';

  @override
  String get notificationsCategoryRankingsHint =>
      'Nuevo líder, goleador o asistidor del equipo.';

  @override
  String get notificationsInboxTitle => 'Notificaciones';

  @override
  String get notificationsInboxMarkAllRead => 'Marcar todo como leído';

  @override
  String get notificationsInboxEmptyTitle => 'Todavía no tienes notificaciones';

  @override
  String get notificationsInboxEmptyMessage =>
      'Aquí aparecen los avisos del equipo, del ranking y de tus búsquedas.';

  @override
  String get notificationsInboxErrorMessage =>
      'No pudimos cargar tus notificaciones.';

  @override
  String get notificationsInboxRetry => 'Intentar de nuevo';

  @override
  String get notificationsGroupToday => 'Hoy';

  @override
  String get notificationsGroupYesterday => 'Ayer';

  @override
  String get notificationsGroupEarlier => 'Anteriores';

  @override
  String notificationTeamMemberJoined(String displayName, String teamName) {
    return '$displayName se unió a $teamName.';
  }

  @override
  String notificationTeamLeaderChanged(String leaderDisplayName) {
    return '$leaderDisplayName asumió el liderato del ranking del equipo.';
  }

  @override
  String get notificationYouAreTeamLeader =>
      '¡Asumiste el liderato del ranking del equipo!';

  @override
  String notificationTeamTopScorerChanged(
    String playerName,
    String displayName,
  ) {
    return '$playerName ($displayName) es el nuevo goleador del equipo.';
  }

  @override
  String notificationTeamTopAssistChanged(
    String playerName,
    String displayName,
  ) {
    return '$playerName ($displayName) ahora lidera las asistencias del equipo.';
  }

  @override
  String notificationWeekendLeagueFinished(
    String displayName,
    int wins,
    int losses,
  ) {
    return '$displayName terminó el Champions $wins-$losses.';
  }

  @override
  String notificationRivalsDivisionChanged(
    String displayName,
    String division,
  ) {
    return '$displayName llegó a $division en Rivals.';
  }

  @override
  String notificationTeamJoinRequestReceived(
    String requesterDisplayName,
    String teamName,
  ) {
    return '$requesterDisplayName pidió entrar en $teamName.';
  }

  @override
  String notificationTeamJoinRequestApproved(String teamName) {
    return 'Tu solicitud para entrar en $teamName fue aprobada.';
  }

  @override
  String notificationTeamJoinRequestRejected(String teamName) {
    return 'Tu solicitud para entrar en $teamName fue rechazada.';
  }

  @override
  String notificationTeamInvitationReceived(String teamName) {
    return 'Recibiste una invitación para entrar en $teamName.';
  }

  @override
  String notificationTeamInvitationAccepted(
    String displayName,
    String teamName,
  ) {
    return '$displayName aceptó tu invitación para $teamName.';
  }

  @override
  String get historyTabMatches => 'Partidos';

  @override
  String get historyTabStats => 'Estadísticas';

  @override
  String get historyPeriodAll => 'Siempre';

  @override
  String get historyPeriod7 => '7 días';

  @override
  String get historyPeriod30 => '30 días';

  @override
  String get historyPeriod90 => '90 días';

  @override
  String get historyStatusAll => 'Todas';

  @override
  String get historyStatusMatchFound => 'Encontradas';

  @override
  String get historyStatusCancelled => 'Canceladas';

  @override
  String get historyStatusExpired => 'Expiradas';

  @override
  String get historyStatusMatchFoundLabel => 'Partido encontrado';

  @override
  String get historyStatusCancelledLabel => 'Cancelada';

  @override
  String get historyStatusExpiredLabel => 'Expirada';

  @override
  String get historyEmptyTitle => 'Aún no hay búsquedas';

  @override
  String get historyEmptyMessage =>
      'Las búsquedas de partido del equipo aparecen aquí cuando terminan.';

  @override
  String get activityScopeAll => 'Todo';

  @override
  String get activityScopeGames => 'Juegos';

  @override
  String get activityScopeSearches => 'Búsquedas';

  @override
  String get activityNoResult => 'Resultado no informado';

  @override
  String get activityDetailMode => 'Modo';

  @override
  String get activityDetailDuration => 'Duración';

  @override
  String get activityDetailScore => 'Marcador';

  @override
  String get activityDetailResult => 'Resultado';

  @override
  String get activityDetailStatus => 'Estado';

  @override
  String get activityDetailFcAccount => 'Cuenta';

  @override
  String get historyLoadErrorTitle => 'No fue posible cargar el historial';

  @override
  String get historyLoadMore => 'Cargar más';

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
  String get statsTotalSearches => 'Búsquedas';

  @override
  String get statsMatchFound => 'Encontradas';

  @override
  String get statsCancelled => 'Canceladas';

  @override
  String get statsExpired => 'Expiradas';

  @override
  String get statsSuccessRate => 'Tasa de éxito';

  @override
  String get statsAvgDuration => 'Duración media';

  @override
  String get statsPlayersTitle => 'Por jugador';

  @override
  String get statsEmptyTitle => 'Sin datos en el período';

  @override
  String get statsEmptyMessage =>
      'Cuando el equipo busque partidos, las estadísticas aparecen aquí.';

  @override
  String get statsLoadErrorTitle => 'No fue posible cargar las estadísticas';

  @override
  String statsPlayerSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count búsquedas',
      one: '1 búsqueda',
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
  String get pendingMatchTitle => 'Tienes una partida sin resultado';

  @override
  String get pendingMatchWinAction => 'Victoria';

  @override
  String get pendingMatchLossAction => 'Derrota';

  @override
  String get pendingMatchAddScoreAction => 'Añadir marcador';

  @override
  String get finishMatchSheetTitle => 'Resultado de la partida';

  @override
  String get finishMatchSheetMessage => 'Indica el marcador de tu partida.';

  @override
  String get finishMatchGoalsForLabel => 'Tus goles';

  @override
  String get finishMatchGoalsAgainstLabel => 'Goles del rival';

  @override
  String get finishMatchGoalsRequired => 'Indica un número válido.';

  @override
  String get finishMatchDrawError =>
      'Un empate no es un resultado final válido.';

  @override
  String get finishMatchSubmitAction => 'Guardar resultado';

  @override
  String weekendLeagueBadge(int number) {
    return 'Champions #$number';
  }

  @override
  String weekendLeagueWindow(String start, String end) {
    return '$start – $end';
  }

  @override
  String get weekendLeagueActiveBadge => 'En curso';

  @override
  String get errorFcAccountNotFound => 'Cuenta no encontrada.';

  @override
  String get errorFcAccountNotLinkedToTeam =>
      'Esta cuenta no está vinculada a este equipo.';

  @override
  String get errorFcAccountInvalidName =>
      'Indica un nombre de 2 a 40 caracteres.';

  @override
  String get errorFcAccountInvalidDivision => 'División inválida.';

  @override
  String get errorFcAccountNotLinkedToAnyTeam =>
      'Esta cuenta no está vinculada a ningún equipo.';

  @override
  String get validationFcAccountNameRequired =>
      'Indica un nombre para la cuenta.';

  @override
  String validationFcAccountNameTooShort(int min) {
    return 'El nombre debe tener al menos $min caracteres.';
  }

  @override
  String validationFcAccountNameTooLong(int max) {
    return 'El nombre puede tener como máximo $max caracteres.';
  }

  @override
  String get fcAccountRequiredToSearch =>
      'Crea o selecciona una cuenta para buscar partida.';

  @override
  String fcAccountLinkCta(String accountName, String teamName) {
    return 'Vincular $accountName a $teamName';
  }

  @override
  String get fcAccountsPageTitle => 'Mis Cuentas';

  @override
  String get fcAccountsPageSubtitle => 'Tus cuentas de Ultimate Team';

  @override
  String get fcAccountsEmptyTitle => 'Todavía no tienes una cuenta';

  @override
  String get fcAccountsEmptyMessage =>
      'Crea una cuenta para vincularla a equipos y empezar a buscar partidas.';

  @override
  String get fcAccountCreateAction => 'Crear cuenta';

  @override
  String get fcAccountCreateTitle => 'Nueva cuenta';

  @override
  String get fcAccountCreateSubtitle => 'Dale un nombre a esta cuenta.';

  @override
  String get fcAccountNameLabel => 'Nombre de la cuenta';

  @override
  String get fcAccountNameHint => 'Ej.: Cuenta principal';

  @override
  String get fcAccountRenameTitle => 'Renombrar cuenta';

  @override
  String get fcAccountRenameAction => 'Renombrar';

  @override
  String get fcAccountArchiveAction => 'Archivar cuenta';

  @override
  String get fcAccountArchiveConfirmTitle => '¿Archivar cuenta?';

  @override
  String get fcAccountArchiveConfirmMessage =>
      'La cuenta deja de aparecer en la lista, pero se conserva su historial.';

  @override
  String get fcAccountSwitchTitle => 'Cambiar de cuenta';

  @override
  String get fcAccountSwitchCreateAction => '+ Crear nueva cuenta';

  @override
  String get fcAccountLinkedTeamsTitle => 'Equipos vinculados';

  @override
  String get fcAccountLinkedTeamsEmpty =>
      'Esta cuenta todavía no está vinculada a ningún equipo.';

  @override
  String get fcAccountLinkTeamAction => 'Vincular';

  @override
  String get fcAccountUnlinkTeamAction => 'Desvincular';

  @override
  String get fcAccountSettingsTitle => 'Configuración';

  @override
  String get fcAccountDivisionTitle => 'División de Rivals';

  @override
  String get fcAccountDivisionPickerTitle => 'Seleccionar división';

  @override
  String get fcAccountDivisionNone => 'Sin división definida';

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
  String get fcAccountWeekendLeagueClearAction =>
      'Usar resultado de las partidas';

  @override
  String get fcAccountWeekendLeagueSheetTitle => 'Informar resultado';

  @override
  String get fcAccountWeekendLeagueWinsLabel => 'Victorias';

  @override
  String get fcAccountWeekendLeagueLossesLabel => 'Derrotas';

  @override
  String get fcAccountOnboardingTitle => 'Añade tu primera cuenta';

  @override
  String get fcAccountOnboardingMessage =>
      'Registra la cuenta que juegas o gestionas para participar en equipos, buscar partidos y seguir tu progreso.';

  @override
  String get fcAccountOnboardingCreateAction => 'Añadir cuenta';

  @override
  String pendingMatchElencoLabel(String name) {
    return 'Cuenta: $name';
  }

  @override
  String historyElencoLabel(String name) {
    return 'Cuenta: $name';
  }

  @override
  String get profileFcAccountsRow => 'Cuentas';

  @override
  String get rivalsDivisionDiv10 => 'División 10';

  @override
  String get rivalsDivisionDiv9 => 'División 9';

  @override
  String get rivalsDivisionDiv8 => 'División 8';

  @override
  String get rivalsDivisionDiv7 => 'División 7';

  @override
  String get rivalsDivisionDiv6 => 'División 6';

  @override
  String get rivalsDivisionDiv5 => 'División 5';

  @override
  String get rivalsDivisionDiv4 => 'División 4';

  @override
  String get rivalsDivisionDiv3 => 'División 3';

  @override
  String get rivalsDivisionDiv2 => 'División 2';

  @override
  String get rivalsDivisionDiv1 => 'División 1';

  @override
  String get rivalsDivisionElite => 'Elite';

  @override
  String get squadsSectionTitle => 'Plantillas';

  @override
  String get squadBuilderSaved => 'Guardado';

  @override
  String get squadBuilderSaving => 'Guardando…';

  @override
  String get squadsEmptyTitle => 'Ningun equipo configurado';

  @override
  String get squadsEmptyMessage =>
      'Crea un equipo para armar tu alineación. Puedes buscar partida incluso sin uno.';

  @override
  String get squadCreateAction => 'Crear equipo';

  @override
  String get squadCreateTitle => 'Nuevo equipo';

  @override
  String get squadCreateSubtitle =>
      'Ponle un nombre y elige la formación inicial.';

  @override
  String get squadNameLabel => 'Nombre del equipo';

  @override
  String get squadNameHint => 'Ej.: Principal';

  @override
  String get squadFormationLabel => 'Formación';

  @override
  String get squadRenameTitle => 'Renombrar equipo';

  @override
  String get squadRenameAction => 'Renombrar';

  @override
  String get squadSetDefaultAction => 'Definir como predeterminado';

  @override
  String get squadDefaultBadge => 'Predeterminado';

  @override
  String get squadArchiveAction => 'Archivar equipo';

  @override
  String get squadArchiveConfirmTitle => '¿Archivar equipo?';

  @override
  String get squadArchiveConfirmMessage =>
      'Sale de la lista, pero se mantiene el historial de partidas jugadas con él.';

  @override
  String get squadBenchTitle => 'Banquillo';

  @override
  String get squadManagerTitle => 'Entrenador';

  @override
  String get squadManagerAddAction => 'Añadir entrenador';

  @override
  String get squadManagerRemoveAction => 'Quitar entrenador';

  @override
  String get squadManagerNationLabel => 'País';

  @override
  String get squadManagerLeagueLabel => 'Liga';

  @override
  String get squadManagerPickNationFirst =>
      'Elige un país para ver los entrenadores.';

  @override
  String get squadManagerNoneTitle => 'Sin entrenador';

  @override
  String get squadFormationPickerTitle => 'Elegir formación';

  @override
  String get squadPlayerPickerTitle => 'Buscar jugador';

  @override
  String get squadPlayerSearchHint => 'Buscar jugador...';

  @override
  String get squadPlayerPickerEmpty => 'No se encontraron cartas.';

  @override
  String get squadSlotChangeAction => 'Cambiar jugador';

  @override
  String get squadSlotMoveAction => 'Mover';

  @override
  String get squadSlotRemoveAction => 'Quitar';

  @override
  String get squadMoveHint => 'Toca otro espacio para intercambiar.';

  @override
  String get squadIncompleteLabel => 'Equipo incompleto';

  @override
  String get squadLabel => 'Equipo';

  @override
  String get playAccountLabel => 'Cuenta';

  @override
  String get playSquadEmpty => 'Ninguna plantilla creada';

  @override
  String get playSquadBuildAction => 'Crear plantilla';

  @override
  String get playSquadEditAction => 'Editar plantilla';

  @override
  String get squadNoneSelected => 'Sin equipo';

  @override
  String get squadFilterLeagueLabel => 'Liga';

  @override
  String get squadFilterNationLabel => 'Nación';

  @override
  String get squadFilterClearAction => 'Limpiar filtros';

  @override
  String get errorSquadNotFound => 'Equipo no encontrado.';

  @override
  String get errorSquadNameInvalid => 'Elige un nombre de 1 a 40 caracteres.';

  @override
  String get errorSquadFormationInvalid => 'Esa formación no está disponible.';

  @override
  String get errorSquadSlotInvalid =>
      'Ese espacio no existe en esta formación.';

  @override
  String get errorSquadCardPosition => 'Ese jugador no juega en esa posición.';

  @override
  String get errorSquadInUse =>
      'Este equipo se está usando en una búsqueda activa.';

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
  String get squadClearAction => 'Vaciar alineación';

  @override
  String get squadClearConfirmTitle => '¿Vaciar alineación?';

  @override
  String get squadClearConfirmMessage =>
      'Esto elimina a todos los jugadores de titulares, banco y reservas. El plantilla en sí no se elimina.';

  @override
  String get squadFormationChangeConfirmTitle => '¿Cambiar formación?';

  @override
  String get squadFormationChangeConfirmMessage =>
      'Tus jugadores se reposicionarán automáticamente. Nadie es eliminado, pero alguien puede quedar fuera de posición.';

  @override
  String get squadFilterCompatibleLabel => 'Compatibles';

  @override
  String get squadPositionBadgePrimary => 'Primaria';

  @override
  String get squadPositionBadgeAlternative => 'Alternativa';

  @override
  String get squadPositionBadgeOutOfPosition => 'Fuera de posición';

  @override
  String get squadCardDetailAction => 'Ver detalles';

  @override
  String get squadCardDetailRatingLabel => 'Rating';

  @override
  String get squadCardDetailPositionLabel => 'Posición';

  @override
  String get squadCardDetailAltPositionsLabel => 'Posiciones alternativas';

  @override
  String get squadCardDetailStatsTitle => 'Atributos';

  @override
  String get squadCardDetailGkStatsTitle => 'Atributos de portero';

  @override
  String get squadCardDetailWeakFootLabel => 'Pie malo';

  @override
  String get squadCardDetailSkillMovesLabel => 'Habilidades';

  @override
  String get squadCardDetailPreferredFootLabel => 'Pie preferido';

  @override
  String get squadCardDetailPreferredFootLeft => 'Izquierdo';

  @override
  String get squadCardDetailPreferredFootRight => 'Derecho';

  @override
  String get squadCardDetailPlaystylesPlusTitle => 'PlayStyles+';

  @override
  String get squadCardDetailPlaystylesTitle => 'Playstyles';

  @override
  String get squadCardDetailRolesTitle => 'Roles';

  @override
  String get squadCardDetailClubLabel => 'Club';

  @override
  String get squadCardDetailLeagueLabel => 'Liga';

  @override
  String get squadCardDetailNationLabel => 'Nación';

  @override
  String get squadCardDetailOtherVersionsTitle => 'Otras versiones';

  @override
  String get squadCardDetailOtherVersionsComingSoon =>
      'Próximamente: comparar todas las versiones de este jugador.';

  @override
  String get actionMore => 'Más';

  @override
  String get errorGameInvalidStatsPayload =>
      'No se pudieron guardar esos goles/asistencias.';

  @override
  String get errorGamePlayerNotInSquad =>
      'Ese jugador no formó parte de este partido.';

  @override
  String get errorGameNoSquadSnapshot =>
      'Este partido no tiene alineación registrada.';

  @override
  String get errorGameMatchNotFinished =>
      'Termina el partido antes de editar el resultado.';

  @override
  String get pendingMatchDetailsPromptTitle => '¿Agregar detalles del partido?';

  @override
  String get pendingMatchDetailsPromptMessage =>
      'Puedes registrar goles y asistencias por jugador ahora o después, desde el Historial.';

  @override
  String get pendingMatchDetailsPromptAddAction => 'Agregar ahora';

  @override
  String get pendingMatchDetailsPromptSkipAction => 'Ahora no';

  @override
  String get matchDetailsTitle => 'Detalle del partido';

  @override
  String get matchDetailsResultLabel => 'Resultado';

  @override
  String get matchDetailsScoreLabel => 'Marcador';

  @override
  String get matchDetailsNoResultMessage => 'Sin resultado registrado.';

  @override
  String get matchDetailsEditResultAction => 'Editar resultado';

  @override
  String get matchDetailsAddDetailsAction => 'Agregar goles y asistencias';

  @override
  String get matchDetailsEditDetailsAction => 'Editar goles y asistencias';

  @override
  String get matchDetailsSquadSectionTitle => 'Alineación';

  @override
  String get matchDetailsPlayerStatsTitle => 'Goles y asistencias';

  @override
  String get matchDetailsPlayerStatsEmptyMessage =>
      'No hay goles ni asistencias registrados en este partido.';

  @override
  String get editMatchResultSheetTitle => 'Editar resultado';

  @override
  String get editMatchResultSheetMessage =>
      'Puedes corregir el marcador en cualquier momento, incluso después de terminado el partido.';

  @override
  String get editMatchResultSubmitAction => 'Guardar resultado';

  @override
  String get playerStatsEditorTitle => 'Goles y asistencias';

  @override
  String get playerStatsEditorStartingLabel => 'Titulares';

  @override
  String get playerStatsEditorBenchLabel => 'Suplentes';

  @override
  String get playerStatsEditorSaveAction => 'Guardar detalles';

  @override
  String get statsGoalsLabel => 'Goles';

  @override
  String get statsAssistsLabel => 'Asistencias';

  @override
  String get statsWinsLabel => 'Victorias';

  @override
  String get statsLossesLabel => 'Derrotas';

  @override
  String get recordAddWinTooltip => 'Agregar victoria';

  @override
  String get recordAddLossTooltip => 'Agregar derrota';

  @override
  String get recordRemoveWinTooltip => 'Quitar victoria';

  @override
  String get recordRemoveLossTooltip => 'Quitar derrota';

  @override
  String get statsEmptyLeaderboardMessage =>
      'Todavía no hay goles ni asistencias registrados.';

  @override
  String get rivalsSectionTitle => 'Rivals';

  @override
  String get rivalsDetailTitle => 'Rivals';

  @override
  String get rivalsNoDivisionLabel => 'División todavía no informada';

  @override
  String get rivalsAllTimeNote =>
      'Contador manual, todavía sin separación por temporada/semana.';

  @override
  String get playerProfileSportSummaryTitle => 'Resumen deportivo';

  @override
  String get playerProfileRivalsLabel => 'Rivals';

  @override
  String get playerProfileNoStatsMessage =>
      'Todavía no hay partidos detallados.';

  @override
  String get squadChemistryDetailTitle => 'Química de la alineación';

  @override
  String get squadChemistryPlayerTitle => 'Química del jugador';

  @override
  String get squadChemistrySourceClub => 'Club';

  @override
  String get squadChemistrySourceLeague => 'Liga';

  @override
  String get squadChemistrySourceNation => 'Nación';

  @override
  String get squadChemistrySourceManager => 'Entrenador';

  @override
  String get squadChemistryNoSources =>
      'Este jugador no comparte club, liga ni nación con ningún otro titular.';

  @override
  String get squadChemistryOutOfPositionExplain =>
      'Fuera de posición: no puntúa ni cuenta para la química de sus compañeros.';

  @override
  String get squadChemistryCappedNote => 'Ya está en el máximo de 3.';

  @override
  String squadChemistryRuleNote(String version) {
    return 'Regla $version.';
  }

  @override
  String squadChemistryFullPlayers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadores con química completa',
      one: '1 jugador con química completa',
      zero: 'Ningún jugador con química completa',
    );
    return '$_temp0';
  }

  @override
  String squadChemistryLowPlayers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadores con química cero',
      one: '1 jugador con química cero',
      zero: 'Ningún jugador con química cero',
    );
    return '$_temp0';
  }

  @override
  String squadChemistryOutOfPositionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadores fuera de posición',
      one: '1 jugador fuera de posición',
      zero: 'Nadie fuera de posición',
    );
    return '$_temp0';
  }

  @override
  String squadChemistryEmptySlotsNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posiciones vacías',
      one: '1 posición vacía',
    );
    return '$_temp0';
  }

  @override
  String get squadPrimaryLineupTitle => 'Alineación principal';

  @override
  String get squadPrimaryLineupEditAction => 'Editar alineación';

  @override
  String get squadPrimaryLineupCreateAction => 'Armar alineación';

  @override
  String get squadPrimaryLineupEmpty =>
      'Aún no has armado una alineación para esta Cuenta.';

  @override
  String squadOtherLineupsAction(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ver otras $count alineaciones',
      one: 'Ver otra alineación',
    );
    return '$_temp0';
  }

  @override
  String get teamSportsSummaryTitle => 'Resumen';

  @override
  String get teamSportsMatches => 'Partidos';

  @override
  String get teamSportsWins => 'Victorias';

  @override
  String get teamSportsLosses => 'Derrotas';

  @override
  String get teamSportsWinRate => 'Rendimiento';

  @override
  String get teamSportsGoalsFor => 'Goles';

  @override
  String get teamSportsGoalsAgainst => 'Recibidos';

  @override
  String get teamSportsGoalDifference => 'Diferencia';

  @override
  String get teamSportsWeekendLeagueTitle => 'Champions';

  @override
  String get teamSportsRivalsTitle => 'Rivals';

  @override
  String get teamSportsActivityTitle => 'Actividad reciente';

  @override
  String get teamSportsNoMatchesYet =>
      'Este equipo aún no ha registrado partidos.';

  @override
  String get teamSportsNoActivityYet => 'Aún no hay partidos terminados.';

  @override
  String get teamSportsManualRecord => 'Manual';

  @override
  String get teamSportsNoDivision => 'Sin división';

  @override
  String get teamSportsActivityWin => 'ganó';

  @override
  String get teamSportsActivityLoss => 'perdió';

  @override
  String teamSportsMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros',
      one: '1 miembro',
    );
    return '$_temp0';
  }

  @override
  String teamSportsMatchesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partidos registrados',
      one: '1 partido registrado',
    );
    return '$_temp0';
  }

  @override
  String teamSportsGoalsShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count goles',
      one: '1 gol',
    );
    return '$_temp0';
  }

  @override
  String teamSportsAssistsShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count asistencias',
      one: '1 asistencia',
    );
    return '$_temp0';
  }

  @override
  String get profileSharingRow => 'Compartir';

  @override
  String get publicProfileSectionTitle => 'Privacidad';

  @override
  String get publicProfileMasterSwitchLabel => 'Perfil público';

  @override
  String get publicProfileMasterSwitchHint =>
      'Haz tu perfil visible mediante un enlace público, sin necesitar cuenta en la app.';

  @override
  String get publicProfileStatusActive => 'Perfil público: Activo';

  @override
  String get publicProfileStatusInactive => 'Perfil público: Inactivo';

  @override
  String get publicProfileSlugLabel => 'Dirección de tu perfil';

  @override
  String get publicProfileSlugHint => '3 a 24 letras minúsculas, números o _';

  @override
  String get publicProfileSlugAvailable => 'Disponible';

  @override
  String get publicProfileSlugUnavailable => 'Esta dirección ya está en uso';

  @override
  String get publicProfileSlugChecking => 'Comprobando…';

  @override
  String get publicProfileSlugInvalid => 'Dirección inválida';

  @override
  String get publicProfileAccountLabel => 'Cuenta pública';

  @override
  String get publicProfileAccountEmpty => 'Ninguna cuenta seleccionada';

  @override
  String get publicProfileToggleSquad => 'Alineación Principal';

  @override
  String get publicProfileToggleWeekendLeague => 'Champions';

  @override
  String get publicProfileToggleRivals => 'Rivals';

  @override
  String get publicProfileToggleStats => 'Estadísticas generales';

  @override
  String get publicProfileCopyLinkAction => 'Copiar enlace';

  @override
  String get publicProfileLinkCopied => 'Enlace copiado';

  @override
  String get publicProfileShareAction => 'Compartir';

  @override
  String get publicProfileShareImageAction => 'Compartir imagen';

  @override
  String get publicProfileShareImageError =>
      'No se pudo compartir la imagen en este dispositivo.';

  @override
  String get publicProfileSaveAction => 'Guardar';

  @override
  String get publicProfileSaved => 'Configuración guardada';

  @override
  String get publicProfilePreviewTitle => 'Vista previa';

  @override
  String get publicProfilePageTitle => 'Perfil';

  @override
  String get publicProfileNotFoundTitle => 'Perfil no encontrado';

  @override
  String get publicProfileNotFoundMessage =>
      'Este enlace no existe o ya no está disponible.';

  @override
  String get publicProfileShareSquadCta => 'Compartir alineación';

  @override
  String get publicProfileEnableFirstMessage =>
      'Activa tu perfil público para compartir tu alineación.';

  @override
  String get publicProfileGoToSettingsAction => 'Ir a Compartir';

  @override
  String get publicProfileEditSharingCta => 'Editar compartir';

  @override
  String get publicProfileNoAccountsHint =>
      'Crea una Cuenta antes de compartir.';

  @override
  String get errorPublicProfileInvalidSlug =>
      'Dirección inválida. Usa 3-24 letras minúsculas, números o _.';

  @override
  String get errorPublicProfileReservedSlug =>
      'Esta dirección está reservada, elige otra.';

  @override
  String get errorPublicProfileSlugTaken => 'Esta dirección ya está en uso.';

  @override
  String get errorPublicProfileSlugRequired =>
      'Elige una dirección antes de activar tu perfil público.';

  @override
  String get validationPublicProfileSlugRequired =>
      'Elige una dirección para tu perfil.';

  @override
  String validationPublicProfileSlugTooShort(int min) {
    return 'La dirección necesita al menos $min caracteres.';
  }

  @override
  String validationPublicProfileSlugTooLong(int max) {
    return 'La dirección puede tener como máximo $max caracteres.';
  }

  @override
  String get validationPublicProfileSlugInvalid =>
      'Usa solo letras minúsculas, números o _.';

  @override
  String get errorSoleOwnerBlocksAccountDeletion =>
      'Eres el único dueño de un equipo con otros integrantes. Elimina a los demás integrantes o espera el soporte de transferencia de propiedad antes de eliminar tu cuenta.';

  @override
  String get profileLegalTitle => 'Acerca de y legal';

  @override
  String get aboutTitle => 'Acerca de';

  @override
  String get aboutDescription =>
      'FIFA Queue organiza la cola de búsqueda de partida, las cuentas y las estadísticas de tu equipo de EA SPORTS FC.';

  @override
  String get privacyPolicyTitle => 'Política de Privacidad';

  @override
  String get termsOfUseTitle => 'Términos de Uso';

  @override
  String legalUpdatedAt(String date) {
    return 'Actualizado el $date';
  }

  @override
  String get deleteAccountRow => 'Eliminar mi cuenta';

  @override
  String get deleteAccountTitle => 'Eliminar cuenta';

  @override
  String get deleteAccountWarningTitle => 'Esta acción es permanente';

  @override
  String get deleteAccountWarningMessage =>
      'Al eliminar tu cuenta, pierdes acceso a todo lo que se indica abajo. No se puede deshacer ni recuperar después.';

  @override
  String get deleteAccountConsequenceFcAccounts =>
      'Todas tus Cuentas y la división de Rivals registrada';

  @override
  String get deleteAccountConsequenceSquads => 'Tus alineaciones (Plantilla)';

  @override
  String get deleteAccountConsequenceHistory =>
      'Tu membresía en los equipos a los que perteneces';

  @override
  String get deleteAccountConsequenceStats =>
      'Tu historial y estadísticas personales de partidas';

  @override
  String get deleteAccountConsequencePreferences =>
      'Tus preferencias de notificación y dispositivos registrados';

  @override
  String get deleteAccountConsequencePublicProfile =>
      'Tu perfil público, si está activado';

  @override
  String deleteAccountTypeToConfirm(String word) {
    return 'Para confirmar, escribe $word en el campo de abajo.';
  }

  @override
  String get deleteAccountConfirmWord => 'ELIMINAR';

  @override
  String get deleteAccountAction => 'Eliminar mi cuenta permanentemente';

  @override
  String get homeFcAccountEyebrow => 'CUENTA FC ACTIVA';

  @override
  String get homeFcAccountSwitchAction => 'Cambiar';

  @override
  String get homeFcAccountNoTeams => 'Todavía sin equipo';

  @override
  String homeFcAccountTeamCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'En $count equipos',
      one: 'En 1 equipo',
    );
    return '$_temp0';
  }

  @override
  String get homeNoTeamTitle => 'Entra en un equipo';

  @override
  String get homeNoTeamMessage =>
      'Buscar partido requiere un equipo. Rivals y Champions ya puedes usarlos.';

  @override
  String get pendingMatchSkipAction => 'No informar este partido';

  @override
  String get pendingMatchSkipConfirmTitle => '¿No informar el resultado?';

  @override
  String get pendingMatchSkipConfirmMessage =>
      'El partido sale de aquí sin contar como victoria ni derrota. Puedes buscar otro con normalidad.';

  @override
  String get historyResultNotInformed => 'Resultado no informado';

  @override
  String get weekendLeagueWeekPickerTitle => 'Seleccionar semana';

  @override
  String get weekendLeagueChangeWeekAction => 'Cambiar';

  @override
  String get weekendLeagueCurrentWeekBadge => 'En curso';

  @override
  String get rivalsSetDivisionAction => 'Informar';

  @override
  String get controlNoTeamTitle => 'Necesitas un equipo';

  @override
  String get controlNoTeamMessage =>
      'La fila es del equipo. Entra en uno o crea el tuyo para empezar a buscar.';

  @override
  String get controlNoTeamAction => 'Ver equipos';

  @override
  String get controlAccountNotLinkedMessage =>
      'Crea o vincula esta cuenta a algún equipo para poder buscar partidas.';

  @override
  String get controlGoToTeamsAction => 'Ir a Equipos';

  @override
  String get navRequests => 'Solicitudes';

  @override
  String get requestsPageTitle => 'Solicitudes';

  @override
  String get requestsSegmentRequests => 'Pedidos';

  @override
  String get requestsSegmentInvites => 'Invitaciones';

  @override
  String get requestsEmptyRequestsTitle => 'Ningún pedido pendiente';

  @override
  String get requestsEmptyRequestsMessage =>
      'Los pedidos de ingreso a los equipos que administras aparecen aquí.';

  @override
  String get requestsEmptyInvitesTitle => 'Ninguna invitación pendiente';

  @override
  String get requestsEmptyInvitesMessage =>
      'Las invitaciones que recibas de otros equipos aparecen aquí.';

  @override
  String requestsMemberCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros',
      one: '1 miembro',
    );
    return '$_temp0';
  }

  @override
  String requestsJoinRequestWantsToJoin(String account) {
    return 'Quiere entrar con $account';
  }

  @override
  String get requestsApproveAction => 'Aprobar';

  @override
  String get requestsRejectAction => 'Rechazar';

  @override
  String get requestsAcceptAction => 'Aceptar';

  @override
  String get requestsDeclineAction => 'Rechazar';

  @override
  String get requestsApprovedMessage => 'Pedido aprobado.';

  @override
  String get requestsRejectedMessage => 'Pedido rechazado.';

  @override
  String get requestsInvitationAcceptedMessage => 'Invitación aceptada.';

  @override
  String get requestsInvitationRejectedMessage => 'Invitación rechazada.';

  @override
  String get requestsLoadErrorTitle => 'No se pudieron cargar las solicitudes';

  @override
  String get teamPublicRequestToJoinAction => 'Pedir para entrar';

  @override
  String get teamPublicRequestSentAction => 'Solicitud enviada';

  @override
  String get teamPublicRequestCancelAction => 'Cancelar solicitud';

  @override
  String get teamPublicChooseAccountTitle => '¿Qué cuenta quieres vincular?';

  @override
  String get teamPublicRequestSentMessage =>
      'Solicitud enviada. El dueño del equipo la va a revisar.';

  @override
  String get teamPublicRequestCancelledMessage => 'Solicitud cancelada.';

  @override
  String get teamDetailInviteAction => 'Invitar jugador';

  @override
  String get teamInviteSheetTitle => 'Invitar jugador';

  @override
  String get teamInviteSlugFieldLabel => 'Enlace del perfil (@usuario)';

  @override
  String get teamInviteSlugFieldHint =>
      'Pide a la persona que comparta el enlace de su perfil público';

  @override
  String get teamInviteSendAction => 'Enviar invitación';

  @override
  String get teamInviteNotFoundMessage =>
      'Ningún perfil público encontrado con ese enlace.';

  @override
  String get teamInviteSentMessage => 'Invitación enviada.';

  @override
  String get teamPendingRequestsSectionTitle => 'Pedidos pendientes';

  @override
  String get teamSentInvitationsSectionTitle => 'Invitaciones pendientes';

  @override
  String get teamInviteRevokeAction => 'Cancelar invitación';

  @override
  String get teamMemberPromoteAction => 'Hacer gerente';

  @override
  String get teamMemberDemoteAction => 'Quitar de la gerencia';

  @override
  String get teamMemberRemoveAction => 'Quitar del equipo';

  @override
  String teamMemberRemoveConfirmTitle(String name) {
    return '¿Quitar a $name del equipo?';
  }

  @override
  String get teamMemberRemoveConfirmMessage =>
      'Esta persona deja de formar parte del equipo. Su historial se conserva.';

  @override
  String get teamMemberRemovedMessage => 'Jugador quitado del equipo.';

  @override
  String get teamMemberRoleUpdatedMessage => 'Cargo actualizado.';

  @override
  String get teamLogoChangeAction => 'Cambiar logo';

  @override
  String get teamLogoAddAction => 'Añadir logo';

  @override
  String get teamLogoRemoveAction => 'Quitar logo';

  @override
  String get teamLogoRemoveConfirmTitle => '¿Quitar la logo del equipo?';

  @override
  String get teamLogoRemoveConfirmMessage =>
      'El equipo vuelve a mostrar las iniciales en vez de la logo.';

  @override
  String pendingMatchesCardTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partidos sin resultado',
      one: '1 partido sin resultado',
    );
    return '$_temp0';
  }

  @override
  String pendingMatchesCardLatest(String mode, String date, String time) {
    return 'Más reciente: $mode · $date a las $time';
  }

  @override
  String get pendingMatchesOpenListAction => 'Ver partidos';

  @override
  String get pendingMatchesDismissAllAction => 'No informar';

  @override
  String get pendingMatchesDismissAllTitle => '¿No informar ninguno?';

  @override
  String get pendingMatchesDismissAllMessage =>
      'Todos salen de la lista sin contar como victoria ni derrota.';

  @override
  String get pendingMatchesSheetTitle => 'Partidos sin resultado';

  @override
  String get pendingMatchesSheetMessage =>
      'Informa los que quieras. Dejarlos en blanco no bloquea nada.';

  @override
  String get pendingMatchesSkipOneAction => 'No informar';

  @override
  String get pendingMatchesAllClear => 'Ningún partido pendiente.';

  @override
  String get errorWeekendLeagueLimit =>
      'Champions tiene 15 partidos: victorias y derrotas juntas no pueden superarlo.';

  @override
  String get squadNoneSelectedHint => 'Elige una plantilla para esta búsqueda';

  @override
  String get catalogCardsTitle => 'Jugadores';

  @override
  String get catalogCardsSearchLabel => 'Buscar carta';

  @override
  String get catalogCardsSearchHint => 'Nombre del jugador';

  @override
  String get catalogCardsEmptyTitle => 'Ninguna carta encontrada';

  @override
  String get catalogCardsEmptyMessage =>
      'Ajusta la búsqueda o los filtros para ver otras cartas.';

  @override
  String get catalogClubsTitle => 'Clubes';

  @override
  String get catalogClubsSearchLabel => 'Buscar club';

  @override
  String get catalogClubsSearchHint => 'Nombre del club';

  @override
  String get catalogClubsEmptyTitle => 'Ningún club encontrado';

  @override
  String get catalogClubsEmptyMessage =>
      'Ajusta la búsqueda o los filtros para ver otros clubes.';

  @override
  String get catalogClubAverageLabel => 'Media';

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
  String get catalogGenderWomen => 'Femenino';

  @override
  String get catalogPositionGroupGoalkeeper => 'Portero';

  @override
  String get catalogPositionGroupDefender => 'Defensor';

  @override
  String get catalogPositionGroupMidfielder => 'Centrocampista';

  @override
  String get catalogPositionGroupForward => 'Delantero';

  @override
  String get filterAll => 'Todas';

  @override
  String get startShortcutPlayHint =>
      'Elige la cuenta y el modo, y entra en la fila.';

  @override
  String get startCatalogTitle => 'Catálogo';

  @override
  String get startCatalogCardsHint => 'Explora las cartas del juego.';

  @override
  String get startCatalogClubsHint => 'Clubes por media de overall.';

  @override
  String get catalogClubsFilterAll => 'Todos';

  @override
  String get centralSectionCatalog => 'Catálogo';

  @override
  String get centralSectionMechanics => 'Mecánicas';

  @override
  String get centralSectionControls => 'Controles';

  @override
  String get catalogManagersEntryLabel => 'Managers';

  @override
  String get catalogConsumablesEntryLabel => 'Consumibles';

  @override
  String get mechanicsPlaystylesLabel => 'PlayStyles';

  @override
  String get mechanicsPlaystylesHint => 'Habilidades especiales de cada carta.';

  @override
  String get mechanicsChemistryLabel => 'Chemistry';

  @override
  String get mechanicsChemistryHint => 'Cómo funciona la química del equipo.';

  @override
  String get mechanicsChemistryStylesLabel => 'Chemistry Styles';

  @override
  String get mechanicsChemistryStylesHint => 'Estilos que refuerzan atributos.';

  @override
  String get mechanicsEvolutionsLabel => 'Evolutions';

  @override
  String get mechanicsEvolutionsHint =>
      'Cómo evolucionan los jugadores en Ultimate Team.';

  @override
  String mechanicsPlaystylesCardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartas',
      one: '1 carta',
      zero: 'Ninguna carta',
    );
    return '$_temp0';
  }

  @override
  String get mechanicsPlaystyleEffectLabel => 'Efecto';

  @override
  String get mechanicsPlaystylePlusEffectLabel => 'Efecto Plus';

  @override
  String get playstyleCategoryFinishing => 'Finalización';

  @override
  String get playstyleCategoryPassing => 'Pase';

  @override
  String get playstyleCategoryDefending => 'Defensa';

  @override
  String get playstyleCategoryBallControl => 'Control de balón';

  @override
  String get playstyleCategoryPhysical => 'Físico';

  @override
  String get playstyleCategoryGoalkeeper => 'Portero';

  @override
  String get playstyleEffectFinesseShot =>
      'Mejora la curva, precisión y velocidad de ejecución del tiro con efecto.';

  @override
  String get playstylePlusEffectFinesseShot =>
      'Refuerza aún más la curva, precisión y ejecución del tiro con efecto.';

  @override
  String get playstyleEffectChipShot =>
      'Vaselinas más rápidas y precisas sobre el portero adelantado.';

  @override
  String get playstylePlusEffectChipShot =>
      'Vaselina todavía más rápida y precisa.';

  @override
  String get playstyleEffectPowerShot =>
      'Aumenta la fuerza y velocidad del balón en el tiro potente.';

  @override
  String get playstylePlusEffectPowerShot =>
      'Tiro potente más fuerte, con trayectoria más baja y controlada.';

  @override
  String get playstyleEffectDeadBall =>
      'Tiros libres y córners con más velocidad, curva y precisión, y vista previa de trayectoria extendida.';

  @override
  String get playstylePlusEffectDeadBall =>
      'Balón parado con velocidad, curva y precisión excepcionales, vista previa de trayectoria al máximo.';

  @override
  String get playstyleEffectPrecisionHeader =>
      'Mejora precisión y potencia del cabezazo controlado.';

  @override
  String get playstylePlusEffectPrecisionHeader =>
      'Ganancia de precisión y potencia aún mayor en el cabezazo.';

  @override
  String get playstyleEffectAcrobatic =>
      'Mejora la precisión de las voleas y libera animaciones acrobáticas extra.';

  @override
  String get playstylePlusEffectAcrobatic =>
      'Mayor precisión y acceso a remates acrobáticos más eficaces.';

  @override
  String get playstyleEffectLowDrivenShot =>
      'Mejora la precisión del tiro raso y fuerte.';

  @override
  String get playstylePlusEffectLowDrivenShot =>
      'Bono de precisión mayor en el tiro raso y fuerte.';

  @override
  String get playstyleEffectGamechanger =>
      'Tiros con efecto y de trivela (parte externa del pie) con más precisión.';

  @override
  String get playstylePlusEffectGamechanger =>
      'Tiros con efecto y trivela con precisión mucho mayor.';

  @override
  String get playstyleEffectIncisivePass =>
      'Mejora la precisión del pase en profundidad, la curva del pase con efecto y la velocidad del pase de precisión.';

  @override
  String get playstylePlusEffectIncisivePass =>
      'Refuerza aún más los tres, sin mejorar el primer toque de quien recibe.';

  @override
  String get playstyleEffectPingedPass =>
      'Los pases rasos viajan más rápido sin dificultar el primer toque de quien recibe.';

  @override
  String get playstylePlusEffectPingedPass =>
      'Pases rasos considerablemente más rápidos.';

  @override
  String get playstyleEffectLongBallPass =>
      'Balones largos más precisos, rápidos y difíciles de interceptar.';

  @override
  String get playstylePlusEffectLongBallPass =>
      'Refuerza aún más precisión, velocidad y eficacia de los balones largos.';

  @override
  String get playstyleEffectTikiTaka =>
      'Mejora pases cortos y de primera difíciles, con taconazos contextuales.';

  @override
  String get playstylePlusEffectTikiTaka =>
      'Bono de precisión mayor en los pases cortos y de primera.';

  @override
  String get playstyleEffectWhippedPass =>
      'Centros con más precisión, velocidad y curva.';

  @override
  String get playstylePlusEffectWhippedPass =>
      'Centros aún más fuertes, con centro raso de potencia excepcional.';

  @override
  String get playstyleEffectInventive =>
      'Pases con efecto y de trivela con más precisión.';

  @override
  String get playstylePlusEffectInventive =>
      'Pases con efecto y trivela con precisión mucho mayor.';

  @override
  String get playstyleEffectJockey =>
      'Mejora el movimiento al marcar de frente (contain) y la transición entre marcar y correr.';

  @override
  String get playstylePlusEffectJockey =>
      'Bono de marcaje mayor, aunque la diferencia con un defensor fuerte sin el estilo es menor en FC 27.';

  @override
  String get playstyleEffectBlock =>
      'Aumenta el alcance y la eficacia al bloquear tiros y pases.';

  @override
  String get playstylePlusEffectBlock =>
      'Alcance y eficacia de bloqueo aún mayores.';

  @override
  String get playstyleEffectIntercept =>
      'Mejora el alcance de intercepción y la chance de conservar el balón después de ella.';

  @override
  String get playstylePlusEffectIntercept =>
      'Refuerza aún más el alcance y la retención de balón tras la intercepción.';

  @override
  String get playstyleEffectAnticipate =>
      'Mejora el éxito de la entrada de pie y la chance de salir con el balón.';

  @override
  String get playstylePlusEffectAnticipate =>
      'Bono significativamente mayor en la entrada de pie y en la retención tras el robo.';

  @override
  String get playstyleEffectSlideTackle =>
      'Mejora la retención del balón cerca del jugador tras una entrada deslizante exitosa.';

  @override
  String get playstylePlusEffectSlideTackle =>
      'Cobertura de entrada deslizante y retención de balón aún mayores.';

  @override
  String get playstyleEffectAerialFortress =>
      'Permite saltos más altos y más presencia física en disputas aéreas defensivas.';

  @override
  String get playstylePlusEffectAerialFortress =>
      'Saltos aún más altos y presencia física aún mayor en las disputas aéreas.';

  @override
  String get playstyleEffectTechnical =>
      'Mejora la velocidad de la carrera controlada y el control en curvas más amplias.';

  @override
  String get playstylePlusEffectTechnical =>
      'Mayor bono de carrera controlada y control de regate.';

  @override
  String get playstyleEffectRapid =>
      'Mejora el regate a velocidad máxima y reduce errores en toques a alta velocidad.';

  @override
  String get playstylePlusEffectRapid => 'Mayor bono de regate en sprint.';

  @override
  String get playstyleEffectFirstTouch =>
      'Reduce el error de primer toque y acelera la transición al regate.';

  @override
  String get playstylePlusEffectFirstTouch =>
      'Reduce aún más el error de primer toque, transición al regate todavía más rápida.';

  @override
  String get playstyleEffectTrickster => 'Libera caños/floreos únicos.';

  @override
  String get playstylePlusEffectTrickster =>
      'Libera floreos extra y más agilidad al regatear de costado.';

  @override
  String get playstyleEffectPressProven =>
      'Mantiene el balón más cerca al trotar y mejora la protección contra rivales más fuertes.';

  @override
  String get playstylePlusEffectPressProven =>
      'Control excepcional al trotar y protección de balón mucho mejor.';

  @override
  String get playstyleEffectQuickStep =>
      'Mejora la aceleración en el sprint explosivo.';

  @override
  String get playstylePlusEffectQuickStep =>
      'Bono de aceleración mayor de lo normal, pero dependiente del atributo de Aceleración del jugador.';

  @override
  String get playstyleEffectRelentless =>
      'Reduce el cansancio durante el partido y mejora la recuperación de fuelle en el descanso.';

  @override
  String get playstylePlusEffectRelentless =>
      'Reduce mucho más el efecto del cansancio a largo plazo en los atributos.';

  @override
  String get playstyleEffectLongThrow =>
      'Aumenta fuerza y distancia del saque de banda.';

  @override
  String get playstylePlusEffectLongThrow =>
      'Saque de banda con aún más fuerza y distancia máxima.';

  @override
  String get playstyleEffectBruiser =>
      'Más fuerza en disputas físicas de entrada.';

  @override
  String get playstylePlusEffectBruiser =>
      'Ventaja de fuerza aún mayor en las disputas físicas.';

  @override
  String get playstyleEffectEnforcer =>
      'Mejora las disputas de hombro al regatear y hace la protección de balón más eficaz.';

  @override
  String get playstylePlusEffectEnforcer =>
      'Mejora mucho más las disputas de hombro y la protección de balón.';

  @override
  String get playstyleEffectFarThrow =>
      'Saques del portero con más velocidad y distancia.';

  @override
  String get playstylePlusEffectFarThrow =>
      'Saques con velocidad y distancia aún mayores.';

  @override
  String get playstyleEffectFootwork =>
      'Paradas con los pies más rápidas y con más alcance.';

  @override
  String get playstylePlusEffectFootwork =>
      'Paradas con los pies aún más rápidas y con más alcance.';

  @override
  String get playstyleEffectCrossClaimer =>
      'Sale a los centros con más ritmo, mejor lectura de trayectoria, y más alcance/fuerza en el puñetazo.';

  @override
  String get playstylePlusEffectCrossClaimer =>
      'Aún más ritmo, lectura y fuerza en el puñetazo en los centros.';

  @override
  String get playstyleEffectRushOut =>
      'Aumenta la velocidad de salida y reacción en situaciones de uno contra uno.';

  @override
  String get playstylePlusEffectRushOut =>
      'Velocidad de salida mucho mayor y reacciones más rápidas.';

  @override
  String get playstyleEffectFarReach =>
      'Mejora el alcance en paradas de estirada y libera animaciones de alcance extendido.';

  @override
  String get playstylePlusEffectFarReach =>
      'Alcance de estirada aún mayor y paradas de alcance extendido más fuertes.';

  @override
  String get playstyleEffectDeflector =>
      'Mejora la capacidad de despejar el balón a zonas más seguras, controlando el rechace.';

  @override
  String get playstylePlusEffectDeflector =>
      'Más control de despeje, pudiendo dirigir la parada a un lugar seguro o a un compañero.';

  @override
  String get mechanicsPlaystyleFilterAny => 'Todas';

  @override
  String get mechanicsPlaystyleFilterPlusOnly => 'Solo Plus';

  @override
  String get controlsDribblingLabel => 'Regates';

  @override
  String get controlsPassingLabel => 'Pases';

  @override
  String get controlsShootingLabel => 'Definición';

  @override
  String get controlsDefendingLabel => 'Defensa';

  @override
  String get controlsActionColumnLabel => 'Acción';

  @override
  String get controlsHeadingControls => 'Controles';

  @override
  String get controlsShootingAction1 => 'Tiro normal / volea / cabezazo';

  @override
  String get controlsShootingAction2 => 'Tiro raso y fuerte';

  @override
  String get controlsShootingPs2 => '◯, luego ◯ otra vez al cargar';

  @override
  String get controlsShootingXbox2 => 'B, luego B otra vez al cargar';

  @override
  String get controlsShootingAction3 => 'Vaselina';

  @override
  String get controlsShootingAction4 => 'Tiro con efecto';

  @override
  String get controlsShootingAction5 => 'Tiro con efecto raso';

  @override
  String get controlsShootingPs5 => 'R1 + ◯, luego ◯ otra vez';

  @override
  String get controlsShootingXbox5 => 'RB + B, luego B otra vez';

  @override
  String get controlsShootingAction6 => 'Tiro potente';

  @override
  String get controlsShootingAction7 => 'Tiro potente raso';

  @override
  String get controlsShootingPs7 => 'L1 + R1 + ◯, luego ◯ otra vez';

  @override
  String get controlsShootingXbox7 => 'LB + RB + B, luego B otra vez';

  @override
  String get controlsShootingAction8 => 'Tiro de estilo (trivela, chilena...)';

  @override
  String get controlsShootingAction9 => 'Amague de tiro';

  @override
  String get controlsShootingPs9 => '◯ luego ✕ + dirección';

  @override
  String get controlsShootingXbox9 => 'B luego A + dirección';

  @override
  String get controlsShootingAction10 => 'Cancelar tiro';

  @override
  String get controlsShootingPs10 => 'L2 + R2 durante la animación';

  @override
  String get controlsShootingXbox10 => 'LT + RT durante la animación';

  @override
  String get controlsShootingHeadingWhenToUse => 'Cuándo usar cada uno';

  @override
  String get controlsShootingBullet1 =>
      'Tiro normal: la opción más versátil, funciona bien en la mayoría de las situaciones dentro del área.';

  @override
  String get controlsShootingBullet2 =>
      'Tiro raso: bueno para tirar cruzado o al portero adelantado, raso a las esquinas.';

  @override
  String get controlsShootingBullet3 =>
      'Tiro con efecto: prioriza colocación y curva -- ideal cortando hacia dentro por la banda y apuntando a la escuadra más lejana.';

  @override
  String get controlsShootingBullet4 =>
      'Tiro potente: necesita más tiempo y espacio libre, mejor fuera del área que dentro de ella.';

  @override
  String get controlsShootingBullet5 =>
      'Vaselina: cuando el portero sale de la línea y sobra espacio por encima de él.';

  @override
  String get controlsShootingBullet6 =>
      'Tiro de estilo: más imprevisible, deja que la animación decida entre chilena, tijera u otro floreo según la posición del jugador.';

  @override
  String get controlsShootingBullet7 =>
      'Amague de tiro: engaña al portero o al defensor cambiando de dirección sin rematar de verdad.';

  @override
  String get controlsShootingHeadingPower => 'Potencia y puntería';

  @override
  String get controlsShootingPowerParagraph =>
      'Cuanto más tiempo mantengas pulsado el botón de tiro, más fuerza recibe el tiro. Cerca del gol, potencia baja o media suele funcionar mejor que el tiro a máxima potencia -- el exceso de fuerza es más difícil de controlar de cerca.';

  @override
  String get controlsPassingHeadingShort => 'Pase corto (raso)';

  @override
  String get controlsPassingAction1 => 'Pase raso';

  @override
  String get controlsPassingAction2 => 'Pase raso elevado';

  @override
  String get controlsPassingAction3 => 'Pase raso fuerte';

  @override
  String get controlsPassingAction4 => 'Pase con efecto';

  @override
  String get controlsPassingAction5 => 'Pase raso de precisión (con curva)';

  @override
  String get controlsPassingHeadingThrough =>
      'Pase en profundidad (through pass)';

  @override
  String get controlsPassingAction6 => 'Pase en profundidad';

  @override
  String get controlsPassingAction7 => 'Pase en profundidad elevado';

  @override
  String get controlsPassingAction8 => 'Pase en profundidad de precisión';

  @override
  String get controlsPassingAction9 => 'Pase en profundidad bombeado';

  @override
  String get controlsPassingAction10 => 'Pase en profundidad fuerte';

  @override
  String get controlsPassingAction11 => 'Pase en profundidad con efecto';

  @override
  String get controlsPassingHeadingCrossing => 'Balón largo y centro';

  @override
  String get controlsPassingAction12 => 'Balón largo / centro';

  @override
  String get controlsPassingAction13 => 'Centro raso';

  @override
  String get controlsPassingAction14 => 'Balón largo de precisión';

  @override
  String get controlsPassingAction15 => 'Balón largo fuerte';

  @override
  String get controlsPassingAction16 => 'Centro raso fuerte';

  @override
  String get controlsPassingAction17 => 'Balón muy alto';

  @override
  String get controlsPassingAction18 => 'Balón largo con efecto';

  @override
  String get controlsPassingHeadingOthers => 'Otros';

  @override
  String get controlsPassingAction19 => 'Toque y voy (Pass and Go)';

  @override
  String get controlsPassingAction20 => 'Amague de pase';

  @override
  String get controlsPassingPs20 => '□ luego ✕ + dirección';

  @override
  String get controlsPassingXbox20 => 'X luego A + dirección';

  @override
  String get controlsPassingHeadingIdeas => 'Ideas para aplicar';

  @override
  String get controlsPassingBullet1 =>
      'El pase raso mantiene la posesión en el mediocampo; el pase en profundidad sirve para jugadores que se desmarcan a la espalda de la defensa.';

  @override
  String get controlsPassingBullet2 =>
      'El balón largo cambia el juego rápido hacia el lado abierto del campo.';

  @override
  String get controlsPassingBullet3 =>
      'El pase fuerte (driven) sale más rápido bajo presión, pero con menos control que el de precisión.';

  @override
  String get controlsPassingBullet4 =>
      'Cuanto más tiempo mantengas pulsado el botón, más fuerza recibe el pase -- combinar el tipo correcto con la fuerza correcta importa tanto como elegir al compañero correcto.';

  @override
  String get controlsDefendingAction1 => 'Cambiar de jugador';

  @override
  String get controlsDefendingAction2 => 'Marcaje (contain / jockey)';

  @override
  String get controlsDefendingPs2 => 'Mantener L2';

  @override
  String get controlsDefendingXbox2 => 'Mantener LT';

  @override
  String get controlsDefendingAction3 => 'Marcaje en sprint';

  @override
  String get controlsDefendingPs3 => 'Mantener L2 + R2';

  @override
  String get controlsDefendingXbox3 => 'Mantener LT + RT';

  @override
  String get controlsDefendingAction4 => 'Entrada de pie';

  @override
  String get controlsDefendingAction5 => 'Entrada de pie fuerte';

  @override
  String get controlsDefendingAction6 => 'Entrada deslizante';

  @override
  String get controlsDefendingAction7 => 'Entrada deslizante fuerte';

  @override
  String get controlsDefendingAction8 => 'Pedir presión a un compañero';

  @override
  String get controlsDefendingPs8 => 'Mantener R1';

  @override
  String get controlsDefendingXbox8 => 'Mantener RB';

  @override
  String get controlsDefendingAction9 => 'Presión colectiva parcial';

  @override
  String get controlsDefendingPs9 => 'R1, luego mantener R1';

  @override
  String get controlsDefendingXbox9 => 'RB, luego mantener RB';

  @override
  String get controlsDefendingAction10 => 'Portero adelanta la línea';

  @override
  String get controlsDefendingPs10 => 'Mantener △';

  @override
  String get controlsDefendingXbox10 => 'Mantener Y';

  @override
  String get controlsDefendingHeadingTips => 'Consejos';

  @override
  String get controlsDefendingBullet1 =>
      'Marcaje (jockey) primero, entrada después: mantén al defensor de frente al atacante, reduce el espacio, e intenta el robo solo cuando el balón quede expuesto.';

  @override
  String get controlsDefendingBullet2 =>
      'La entrada deslizante es el último recurso -- fallarla deja libre al rival o puede acabar en falta, tarjeta o penalti.';

  @override
  String get controlsDefendingBullet3 =>
      'Cambia de jugador manualmente en vez de agarrar siempre al más cercano al balón: a veces cubrir la línea de pase más peligrosa importa más que presionar a quien ya está marcado.';

  @override
  String get controlsDefendingBullet4 =>
      'No adelantes al central sin necesidad -- eso abre espacio a la espalda de la defensa para un pase en profundidad.';

  @override
  String get controlsDefendingBullet5 =>
      'Contra un contraataque, la prioridad es retrasar el avance (retroceder protegiendo el medio) y solo entonces cerrar la jugada, dando tiempo a que los compañeros se recompongan.';

  @override
  String get controlsDefendingBullet6 =>
      'Al defender un centro, no mires solo al extremo -- cubre también a quien llega al segundo palo.';

  @override
  String get controlsDribblingIntroParagraph =>
      'Cada jugador tiene una nota de Skill Moves (1 a 5 estrellas) que define cuáles de estos movimientos puede hacer. Los comandos usan el stick derecho y son iguales en PlayStation y Xbox/PC.';

  @override
  String controlsDribblingStarWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'estrellas',
      one: 'estrella',
    );
    return '$_temp0';
  }

  @override
  String get controlsDribblingSkillName1 => 'Elástico simple hacia el lado';

  @override
  String get controlsDribblingSkillControl1 => 'Mantener L1+R1 + dirección';

  @override
  String get controlsDribblingSkillName2 => 'Sombrero (Flick Up)';

  @override
  String get controlsDribblingSkillControl2 => 'R3';

  @override
  String get controlsDribblingSkillName3 => 'Giro de cuerpo hacia adelante';

  @override
  String get controlsDribblingSkillControl3 =>
      'Mantener L1+R1 + izquierdo hacia abajo';

  @override
  String get controlsDribblingSkillName4 => 'Pedalada (Stepover) derecha';

  @override
  String get controlsDribblingSkillControl4 => 'Girar stick derecho ↑→';

  @override
  String get controlsDribblingSkillName5 => 'Pedalada (Stepover) izquierda';

  @override
  String get controlsDribblingSkillControl5 => 'Girar stick derecho ↑←';

  @override
  String get controlsDribblingSkillName6 => 'Corte de luz (Ball Roll) derecha';

  @override
  String get controlsDribblingSkillControl6 => 'Mantener stick derecho →';

  @override
  String get controlsDribblingSkillName7 =>
      'Corte de luz (Ball Roll) izquierda';

  @override
  String get controlsDribblingSkillControl7 => 'Mantener stick derecho ←';

  @override
  String get controlsDribblingSkillName8 => 'Jalada de balón (Drag Back)';

  @override
  String get controlsDribblingSkillControl8 =>
      'L2+R2 + flick stick izquierdo ↓';

  @override
  String get controlsDribblingSkillName9 => 'Ruleta derecha';

  @override
  String get controlsDribblingSkillControl9 => 'Girar stick derecho ↓ hasta ←';

  @override
  String get controlsDribblingSkillName10 => 'Ruleta izquierda';

  @override
  String get controlsDribblingSkillControl10 => 'Girar stick derecho ↓ hasta →';

  @override
  String get controlsDribblingSkillName11 => 'Amague y va hacia la derecha';

  @override
  String get controlsDribblingSkillControl11 => 'Girar stick derecho ←↓→';

  @override
  String get controlsDribblingSkillName12 => 'Amague y va hacia la izquierda';

  @override
  String get controlsDribblingSkillControl12 => 'Girar stick derecho →↓←';

  @override
  String get controlsDribblingSkillName13 => 'Corte de talón corriendo';

  @override
  String get controlsDribblingSkillControl13 =>
      'Mantener L2 + ■/○ luego X + izquierdo';

  @override
  String get controlsDribblingSkillName14 => 'Arcoíris simple';

  @override
  String get controlsDribblingSkillControl14 => 'Flick stick derecho ↓↑↑';

  @override
  String get controlsDribblingSkillName15 => 'Giro hacia la izquierda';

  @override
  String get controlsDribblingSkillControl15 =>
      'Mantener R2+R1 + girar stick derecho ↖';

  @override
  String get controlsDribblingSkillName16 => 'Giro hacia la derecha';

  @override
  String get controlsDribblingSkillControl16 =>
      'Mantener R2+R1 + girar stick derecho ↗';

  @override
  String get controlsDribblingSkillName17 => 'Amague de pase';

  @override
  String get controlsDribblingSkillControl17 => 'Mantener R2 + ■/○ luego X';

  @override
  String get controlsDribblingSkillName18 => 'Corte con corte de luz';

  @override
  String get controlsDribblingSkillControl18 =>
      'Mantener stick derecho ← + izquierdo →';

  @override
  String get controlsDribblingSkillName19 => 'Elástico';

  @override
  String get controlsDribblingSkillControl19 => 'Derecho → girar ↓←';

  @override
  String get controlsDribblingSkillName20 => 'Elástico invertido';

  @override
  String get controlsDribblingSkillControl20 => 'Derecho ← girar ↓→';

  @override
  String get controlsDribblingSkillName21 => 'Arcoíris avanzado';

  @override
  String get controlsDribblingSkillControl21 =>
      'Flick stick derecho ↓ mantener ↑↑';

  @override
  String get controlsDribblingSkillName22 =>
      'Sombrero (por encima del marcador)';

  @override
  String get controlsDribblingSkillControl22 => 'Flick stick derecho ↑↑↓';

  @override
  String get controlsDribblingSkillName23 => 'Rabona amague';

  @override
  String get controlsDribblingSkillControl23 =>
      'Mantener L2 + ■/○ luego X + izquierdo ↓';

  @override
  String get controlsDribblingHeadingOtherControls =>
      'Otros comandos de regate';

  @override
  String get controlsDribblingAction1 => 'Carrera controlada';

  @override
  String get controlsDribblingPs1 => 'Mantener R1 + dirección';

  @override
  String get controlsDribblingXbox1 => 'Mantener RB + dirección';

  @override
  String get controlsDribblingAction2 => 'Proteger el balón';

  @override
  String get controlsDribblingPs2 => 'Mantener L2';

  @override
  String get controlsDribblingXbox2 => 'Mantener LT';

  @override
  String get controlsDribblingAction3 => 'Toque de esfuerzo';

  @override
  String get controlsDribblingPs3 => 'R1 + flick stick derecho';

  @override
  String get controlsDribblingXbox3 => 'RB + flick stick derecho';

  @override
  String get controlsDribblingAction4 => 'Amague de tiro';

  @override
  String get controlsDribblingPs4 => '◯ luego ✕ + dirección';

  @override
  String get controlsDribblingXbox4 => 'B luego A + dirección';

  @override
  String get controlsDribblingHeadingIdeas => 'Ideas para aplicar';

  @override
  String get controlsDribblingBullet1 =>
      'Un buen regate reacciona al movimiento del defensor -- floreo sin motivo suele facilitar perder el balón.';

  @override
  String get controlsDribblingBullet2 =>
      'Cambia de velocidad en vez de correr siempre a tope: normal cerca del defensor, carrera controlada para acercarte, sprint solo cuando el espacio ya está abierto.';

  @override
  String get controlsDribblingBullet3 =>
      'Crea espacio primero, acelera después: cambia de dirección o haz un regate simple, espera a que el marcador se comprometa, solo entonces acelera hacia el espacio libre.';

  @override
  String get managersBlockedTitle => 'Todavía sin dato real';

  @override
  String get managersBlockedMessage =>
      'Hoy solo existen registros de prueba (nombres ficticios usados en el selector de técnico del Plantilla). Necesitamos una fuente real de managers de FC 27 antes de mostrar esto como catálogo.';

  @override
  String get consumablesBlockedTitle => 'Todavía sin dato real';

  @override
  String get consumablesBlockedMessage =>
      'Chemistry Styles ya tiene su propia sección en Mecánicas. Los demás consumibles no existen hoy en nuestro catálogo.';

  @override
  String get errorSquadEditConflict =>
      'Esta plantilla se modificó en otro dispositivo. Recarga la versión más reciente antes de continuar.';

  @override
  String get errorSquadDuplicatedPlayer =>
      'El mismo jugador no puede ocupar dos posiciones.';

  @override
  String get errorSquadInvalidLineup => 'No se pudo guardar esta alineación.';

  @override
  String get squadSaveAction => 'Guardar';

  @override
  String get squadSavedFeedback => 'Plantilla guardada';

  @override
  String get squadDiscardTitle => '¿Descartar cambios?';

  @override
  String get squadDiscardMessage =>
      'Hay cambios sin guardar en esta plantilla.';

  @override
  String get squadDiscardKeep => 'Seguir editando';

  @override
  String get squadDiscardConfirm => 'Descartar';

  @override
  String get squadReloadAction => 'Recargar';

  @override
  String get squadChemistryUpdating => 'Recalculando…';

  @override
  String get squadChemistryUnavailable => 'No se pudo recalcular la química.';

  @override
  String get squadManagerLabel => 'Entrenador';

  @override
  String get squadManagerEmpty => 'Seleccionar entrenador';

  @override
  String get squadShareAction => 'Compartir plantilla';

  @override
  String get squadOverallLabel => 'Media';

  @override
  String get squadChemistryLabel => 'Química';

  @override
  String squadFormationDroppedPlayers(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count jugadores salieron de la alineación: no tienen posición compatible en la nueva formación ($names).',
      one:
          '1 jugador salió de la alineación: no tiene posición compatible en la nueva formación ($names).',
    );
    return '$_temp0';
  }
}
