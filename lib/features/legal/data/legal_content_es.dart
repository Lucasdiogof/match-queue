import 'package:fifa_queue/features/legal/data/legal_content_pt.dart'
    show kResponsibleParty, kSupportEmail;
import 'package:fifa_queue/features/legal/domain/legal_document.dart';

const String _nonAffiliationEs =
    'FIFA Queue es una aplicación independiente, hecha por fanáticos, y no '
    'está afiliada, respaldada ni patrocinada por EA SPORTS, Electronic '
    'Arts, FIFA ni ninguna de sus filiales. Todas las marcas, nombres e '
    'imágenes de terceros mencionados pertenecen a sus respectivos dueños '
    'y se usan solo para identificar de qué trata la aplicación.';

const LegalDocument kPrivacyPolicyEs = LegalDocument(
  updatedAt: '2026-09-08',
  nonAffiliationDisclaimer: _nonAffiliationEs,
  sections: <LegalSection>[
    LegalSection(
      title: '1. Responsable de la aplicación',
      body:
          'FIFA Queue es operado por $kResponsibleParty. '
          'Puedes enviar preguntas sobre esta Política a '
          '$kSupportEmail.',
    ),
    LegalSection(
      title: '2. Qué datos recopilamos',
      body:
          'Solo recopilamos lo necesario para que la app funcione:\n\n'
          '• Datos de cuenta: correo electrónico y contraseña '
          '(almacenada de forma segura por el proveedor de autenticación, '
          'nunca en texto plano).\n'
          '• Perfil: tu nombre visible y, si eliges subir una, una foto '
          'de avatar.\n'
          '• Identificadores internos: un ID único generado para tu '
          'cuenta y para cada Equipo/Cuenta que crees o a la que te '
          'unas.\n'
          '• Cuentas de EA FC: los nombres que le das a tus cuentas, '
          'división de Rivals y el registro de Weekend League que tú '
          'mismo ingreses.\n'
          '• Equipos: nombre, etiqueta e historial de actividad de los '
          'equipos a los que perteneces.\n'
          '• Datos de partidas: búsquedas de partida, colas, resultados '
          'y estadísticas (goles, asistencias) que tú o tu equipo '
          'registren.\n'
          '• Token de notificación push (Firebase Cloud Messaging), si '
          'permites notificaciones.\n'
          '• Perfil público: solo si activas esta opción en la '
          'configuración, un enlace público muestra tu nombre, tu '
          'alineación principal y estadísticas resumidas.',
    ),
    LegalSection(
      title: '3. Proveedores que usamos',
      body:
          'Usamos Supabase (base de datos, autenticación y alojamiento de '
          'API) y Firebase (notificaciones push y reporte de errores). '
          'Estos proveedores procesan datos en nuestro nombre, siguiendo '
          'sus propias políticas de seguridad, y no pueden usar tus datos '
          'para fines propios.',
    ),
    LegalSection(
      title: '4. Para qué usamos tus datos',
      body:
          'Usamos los datos recopilados exclusivamente para: autenticar '
          'tu cuenta; organizar la cola de búsqueda de partida de tu '
          'equipo; mostrar tu historial y estadísticas; enviar '
          'notificaciones sobre tu turno en la cola o eventos del equipo '
          '(si lo permites); y, si activas el perfil público, mostrarlo '
          'en el enlace que compartas. No vendemos tus datos ni los '
          'usamos para publicidad.',
    ),
    LegalSection(
      title: '5. Almacenamiento y seguridad',
      body:
          'Los datos se almacenan en servidores de Supabase, protegidos '
          'por Row Level Security: cada usuario solo puede leer/editar lo '
          'que es suyo o lo que su equipo comparte con él. Las '
          'contraseñas nunca se almacenan en texto plano. La comunicación '
          'entre la app y el servidor siempre se realiza por HTTPS.',
    ),
    LegalSection(
      title: '6. Retención',
      body:
          'Conservamos tus datos mientras tu cuenta exista. El historial '
          'de partidas de tu equipo se conserva incluso después de que '
          'elimines tu cuenta, pero de forma anónima (sin tu nombre '
          'asociado) para no borrar el historial compartido de los demás '
          'miembros del equipo.',
    ),
    LegalSection(
      title: '7. Eliminación de cuenta',
      body:
          'Puedes eliminar tu cuenta en cualquier momento en Perfil → '
          'Eliminar mi cuenta. La eliminación borra tu perfil, cuentas de '
          'EA FC, alineaciones, membresías de equipo, dispositivos '
          'registrados, preferencias de notificación y perfil público. Si '
          'eres el único integrante de un equipo que creaste, se elimina '
          'todo el equipo; si hay otros integrantes, la eliminación solo '
          'se permite una vez que dejes de ser el único dueño. Esta '
          'acción es permanente y no se puede deshacer.',
    ),
    LegalSection(
      title: '8. Compartición de datos',
      body:
          'No compartimos tus datos con terceros con fines de marketing. '
          'Solo compartimos datos con los proveedores de infraestructura '
          'mencionados en la sección 3, en la medida necesaria para que '
          'la app funcione, y cuando la ley lo exija.',
    ),
    LegalSection(
      title: '9. Tus derechos',
      body:
          'Puedes, en cualquier momento: acceder y editar tu nombre '
          'visible y avatar desde la propia app; activar o desactivar tu '
          'perfil público; y eliminar tu cuenta y los datos asociados a '
          'ella. Para cualquier otra solicitud sobre tus datos, '
          'contáctanos en $kSupportEmail.',
    ),
    LegalSection(
      title: '10. Menores de edad',
      body:
          'FIFA Queue no está dirigido a menores de 13 años y no '
          'recopila datos de niños de forma intencional. Si eres '
          'responsable de un menor y crees que nos proporcionó datos '
          'personales, contáctanos para que podamos eliminarlos.',
    ),
    LegalSection(
      title: '11. Cambios en esta política',
      body:
          'Podemos actualizar esta Política de vez en cuando. Los '
          'cambios relevantes se comunicarán dentro de la app. La fecha '
          'en la parte superior de esta página siempre indica la versión '
          'más reciente.',
    ),
    LegalSection(title: '12. Marca y afiliación', body: _nonAffiliationEs),
  ],
);

const LegalDocument kTermsOfUseEs = LegalDocument(
  updatedAt: '2026-09-08',
  nonAffiliationDisclaimer: _nonAffiliationEs,
  sections: <LegalSection>[
    LegalSection(
      title: '1. Aceptación de los términos',
      body:
          'Al crear una cuenta o usar FIFA Queue, aceptas estos Términos '
          'de Uso y nuestra Política de Privacidad. Si no estás de '
          'acuerdo, no uses la aplicación.',
    ),
    LegalSection(
      title: '2. Sobre la app',
      body:
          'FIFA Queue ayuda a grupos de jugadores de EA SPORTS FC / Clubs '
          'a organizar quién busca partida en cada momento, además de '
          'registrar resultados, cuentas y estadísticas del equipo.',
    ),
    LegalSection(
      title: '3. Tu cuenta',
      body:
          'Eres responsable de mantener la confidencialidad de tu '
          'contraseña y de toda actividad realizada en tu cuenta. Debes '
          'proporcionar información verdadera al registrarte.',
    ),
    LegalSection(
      title: '4. Conducta del usuario',
      body:
          'Aceptas no usar la app para acosar a otros usuarios, publicar '
          'contenido ofensivo, intentar acceder a cuentas de terceros, o '
          'interferir con el funcionamiento normal del servicio.',
    ),
    LegalSection(
      title: '5. Matchmaking y cola',
      body:
          'La cola de búsqueda de partida se organiza automáticamente '
          'según el orden de llegada. FIFA Queue no participa, no '
          'interfiere y no se responsabiliza por el resultado de las '
          'partidas jugadas fuera de la aplicación.',
    ),
    LegalSection(
      title: '6. Contenido que ingresas',
      body:
          'Eres responsable de los nombres de cuenta, resultados y demás '
          'información que ingreses en la app. Nos reservamos el derecho '
          'de eliminar contenido claramente ofensivo o que viole estos '
          'Términos.',
    ),
    LegalSection(
      title: '7. Contenido de terceros',
      body:
          'Nombres de jugadores, clubes, ligas y otras referencias a EA '
          'SPORTS FC mostradas en la app se usan solo con fines '
          'informativos/organizativos y pertenecen a sus respectivos '
          'dueños, según se detalla en la sección de marca a '
          'continuación.',
    ),
    LegalSection(
      title: '8. Disponibilidad del servicio',
      body:
          'Hacemos lo posible por mantener la app disponible, pero no '
          'garantizamos una operación ininterrumpida o libre de errores. '
          'Mantenimientos, actualizaciones o fallos de terceros '
          '(Supabase, Firebase, tiendas de aplicaciones) pueden causar '
          'indisponibilidad temporal.',
    ),
    LegalSection(
      title: '9. Suspensión y cierre',
      body:
          'Podemos suspender o cerrar el acceso de una cuenta que viole '
          'estos Términos. Puedes cerrar tu cuenta en cualquier momento '
          'mediante la función de eliminación de cuenta descrita en la '
          'Política de Privacidad.',
    ),
    LegalSection(
      title: '10. Propiedad intelectual',
      body:
          'El código, diseño y la marca "FIFA Queue" pertenecen al '
          'desarrollador de la app. Las marcas de terceros (EA SPORTS, '
          'FIFA, Ultimate Team y similares) pertenecen a sus respectivos '
          'dueños, según la sección de marca a continuación.',
    ),
    LegalSection(
      title: '11. Limitación de responsabilidad',
      body:
          'La app se proporciona "tal cual". En la máxima medida '
          'permitida por la ley, no somos responsables de daños '
          'indirectos derivados del uso o la imposibilidad de uso de la '
          'aplicación.',
    ),
    LegalSection(
      title: '12. Cambios en estos Términos',
      body:
          'Podemos actualizar estos Términos periódicamente. El uso '
          'continuado de la app después de una actualización significa '
          'que aceptas los nuevos Términos.',
    ),
    LegalSection(
      title: '13. Contacto',
      body: 'Preguntas sobre estos Términos: $kSupportEmail.',
    ),
    LegalSection(title: '14. Marca y afiliación', body: _nonAffiliationEs),
  ],
);
