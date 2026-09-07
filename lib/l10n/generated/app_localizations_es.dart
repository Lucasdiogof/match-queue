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
  String get actionBack => 'Volver';

  @override
  String get actionNotNow => 'Ahora no';

  @override
  String get actionSignOut => 'Salir';

  @override
  String get navSearch => 'Buscar';

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
  String get inviteTitle => 'Te invitaron a';

  @override
  String get inviteJoinTeam => 'Entrar al equipo';

  @override
  String inviteCodeLabel(String code) {
    return 'Código de invitación: $code';
  }

  @override
  String get inviteSignInRequiredTitle => 'Entra para aceptar la invitación';

  @override
  String get inviteSignInRequiredMessage =>
      'Guardamos esta invitación. En cuanto entres, se retomará automáticamente.';

  @override
  String get invitePendingRestored => 'Invitación pendiente retomada.';

  @override
  String get inviteResolutionComingSoon =>
      'La entrada al equipo se implementará en la próxima etapa.';

  @override
  String invitePlayersCount(int count) {
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
  String inviteReceivedAt(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Invitación recibida el $dateString';
  }

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
  String get loginLocalModeBadge => 'Modo local';

  @override
  String get loginLocalModeMessage =>
      'No hay ningún proyecto de Supabase configurado. Las cuentas creadas aquí solo existen en este dispositivo.';

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
  String get teamInviteComingSoonTitle =>
      'Las invitaciones llegan en la próxima etapa';

  @override
  String get teamInviteComingSoonMessage =>
      'Unirse por enlace y código llegará pronto. Por ahora, crea un equipo para empezar.';

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
  String get teamInvitePlayers => 'Invitar jugadores';

  @override
  String get teamInvitePlayersHint => 'Disponible en la próxima etapa.';

  @override
  String get teamSwitchTitle => 'Tus equipos';

  @override
  String get teamSwitchAction => 'Cambiar de equipo';

  @override
  String get teamNoActiveSearchTitle => 'Sin búsqueda activa';

  @override
  String get teamNoActiveSearchMessage =>
      'La cola de partidos llega pronto. Aquí es donde el equipo coordinará quién busca ahora.';

  @override
  String get teamSearchDurationLabel => 'Duración de búsqueda predeterminada';

  @override
  String get teamSearchDurationHelper =>
      'Tiempo que cada jugador permanece al frente de la cola.';

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
}
