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
  String get actionEdit => 'Editar';

  @override
  String get navSearch => 'Jugar';

  @override
  String get navTeam => 'Equipo';

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
  String get homeTitle => 'Buscar partido';

  @override
  String get homeSubtitle => 'Coordina quién está buscando ahora.';

  @override
  String get teamTitle => 'Mi equipo';

  @override
  String get teamSubtitle => 'Jugadores, roles e invitaciones.';

  @override
  String get historyTitle => 'Historial';

  @override
  String get historySubtitle =>
      'Búsquedas, partidos encontrados y expiraciones.';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileSubtitle => 'Cuenta, apariencia e idioma.';

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
  String get authEmailHint => 'tu@ejemplo.com';

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
  String get teamCreateCta => 'Crear equipo';

  @override
  String get teamHaveInviteCode => 'Tengo un código de invitación';

  @override
  String get teamCreateTitle => 'Crea tu equipo';

  @override
  String get teamCreateSubtitle =>
      'Podrás ajustar colores, logo y duración de la búsqueda después.';

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
  String get teamRoleAdmin => 'Admin';

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
  String get teamStatusInMatch => 'En partida';

  @override
  String get teamStatusSearching => 'Buscando';

  @override
  String get teamStatusQueued => 'En la cola';

  @override
  String teamStatusQueuedWithPosition(int position) {
    return 'En la cola · #$position';
  }

  @override
  String get teamStatusOffline => 'Offline';

  @override
  String get teamStatusActiveNow => 'Activo ahora';

  @override
  String teamStatusActiveMinutesAgo(int minutes) {
    return 'Hace $minutes min';
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
      'En cuanto empiece la partida, toca partida encontrada.';

  @override
  String matchmakingSearchingOtherTitle(String name) {
    return '$name está buscando partida';
  }

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
  String get matchmakingCancelConfirmTitle => '¿Cancelar búsqueda?';

  @override
  String get matchmakingCancelConfirmMessage =>
      'Vas a perder tu lugar en la búsqueda actual.';

  @override
  String get matchmakingYourTurnTitle => '¡Tu turno de buscar!';

  @override
  String get matchmakingReconnecting => 'Reconectando…';

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
  String get activityScopeGames => 'Partidas';

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
  String get activityDetailFcAccount => 'Elenco';

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
  String get gameModeWeekendLeague => 'Weekend League';

  @override
  String get gameModeDivisionRivals => 'Division Rivals';

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
    return 'Weekend League #$number';
  }

  @override
  String weekendLeagueWindow(String start, String end) {
    return '$start – $end';
  }

  @override
  String get weekendLeagueActiveBadge => 'En curso';

  @override
  String get errorFcAccountNotFound => 'Elenco no encontrado.';

  @override
  String get errorFcAccountNotLinkedToTeam =>
      'Este elenco no está vinculado a este equipo.';

  @override
  String get errorFcAccountInvalidName =>
      'Indica un nombre de 2 a 40 caracteres.';

  @override
  String get errorFcAccountInvalidDivision => 'División inválida.';

  @override
  String get validationFcAccountNameRequired =>
      'Indica un nombre para el elenco.';

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
      'Crea o selecciona un elenco para buscar partida.';

  @override
  String fcAccountLinkCta(String accountName, String teamName) {
    return 'Vincular $accountName a $teamName';
  }

  @override
  String get fcAccountsPageTitle => 'Mis Elencos';

  @override
  String get fcAccountsPageSubtitle => 'Tus cuentas de Ultimate Team';

  @override
  String get fcAccountsEmptyTitle => 'Todavía no tienes un elenco';

  @override
  String get fcAccountsEmptyMessage =>
      'Crea un elenco para vincularlo a equipos y empezar a buscar partidas.';

  @override
  String get fcAccountCreateAction => 'Crear elenco';

  @override
  String get fcAccountCreateTitle => 'Nuevo elenco';

  @override
  String get fcAccountCreateSubtitle => 'Dale un nombre a este elenco.';

  @override
  String get fcAccountNameLabel => 'Nombre del elenco';

  @override
  String get fcAccountNameHint => 'Ej.: Elenco principal';

  @override
  String get fcAccountRenameTitle => 'Renombrar elenco';

  @override
  String get fcAccountRenameAction => 'Renombrar';

  @override
  String get fcAccountArchiveAction => 'Archivar elenco';

  @override
  String get fcAccountArchiveConfirmTitle => '¿Archivar elenco?';

  @override
  String get fcAccountArchiveConfirmMessage =>
      'El elenco deja de aparecer en la lista, pero se conserva su historial.';

  @override
  String get fcAccountSwitchTitle => 'Cambiar de elenco';

  @override
  String get fcAccountSwitchCreateAction => '+ Crear nuevo elenco';

  @override
  String get fcAccountLinkedTeamsTitle => 'Equipos vinculados';

  @override
  String get fcAccountLinkedTeamsEmpty =>
      'Este elenco todavía no está vinculado a ningún equipo.';

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
  String get fcAccountWeekendLeagueClearAction =>
      'Usar resultado de las partidas';

  @override
  String get fcAccountWeekendLeagueSheetTitle => 'Informar resultado';

  @override
  String get fcAccountWeekendLeagueWinsLabel => 'Victorias';

  @override
  String get fcAccountWeekendLeagueLossesLabel => 'Derrotas';

  @override
  String get fcAccountOnboardingTitle => 'Crea tu primer elenco';

  @override
  String get fcAccountOnboardingMessage =>
      'Un elenco representa una cuenta de Ultimate Team. Crea uno para vincularlo a tus equipos y empezar a buscar partidas.';

  @override
  String get fcAccountOnboardingCreateAction => 'Crear elenco';

  @override
  String pendingMatchElencoLabel(String name) {
    return 'Elenco: $name';
  }

  @override
  String historyElencoLabel(String name) {
    return 'Elenco: $name';
  }

  @override
  String get profileFcAccountsRow => 'Elencos';

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
  String get squadsSectionTitle => 'Squads';

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
  String get squadNoneSelected => 'Sin equipo';

  @override
  String get squadDevCatalogNotice =>
      'Cartas de desarrollo. El catálogo real llega en la próxima etapa.';

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
  String get actionMore => 'Más';
}
