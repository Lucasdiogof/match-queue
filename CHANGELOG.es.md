# Changelog

Historial de funcionalidades de la app, de lo más reciente a lo más antiguo.
Las auditorías internas, los scripts de importación de datos y las sesiones
solo de validación no aparecen aquí — solo lo que cambia la experiencia de
usar la app.

## 2026-09-09

- **Squad Builder**: el catálogo real completo de cartas ya está en
  producción — 17.873 jugadores y cartas reales (fútbol masculino y
  femenino), reemplazando la pequeña muestra de desarrollo.

## 2026-09-08

- **Notificaciones**: nueva Central de Notificaciones (campana con contador
  de no leídas, bandeja con leído/no leído, paginación) además del push.
  Las preferencias ahora se agrupan por categoría (Matchmaking, Equipos,
  Weekend League, Rivals, Rankings) en vez de un interruptor por alerta.
- **Perfil**: perfil público opcional con enlace para compartir, mostrando
  tu alineación principal y estadísticas deportivas a quien tenga el enlace.
- **Equipo**: récord deportivo, ranking y tabla de goleadores/asistencias de
  todo el equipo, en un solo panel.
- **Partidos**: goles y asistencias por jugador, resultado editable (sin
  límite de tiempo), y una pantalla dedicada de detalles del partido.
- **Cuentas**: páginas de detalle de Weekend League y Rivals por cuenta, con
  anulación manual del récord cuando sea necesario.
- **Squad Builder**: overall y química calculados automáticamente, con
  arrastrar y soltar, banco de reservas, y explicación de por qué cada
  titular tiene la química que tiene.
- **Jugar**: tarjeta de partido pendiente, selector de modo de juego, y una
  línea de tiempo que combina el historial de búsqueda y de partidos.
- Renombrado "Elenco" a "Cuenta" en toda la app, para mayor claridad.
- Una búsqueda ahora cubre todos los equipos a los que la cuenta está
  vinculada, en vez de exigir una búsqueda separada por equipo.
- **Equipo**: dividido en lista de equipos y pantalla de detalle por equipo,
  con perfiles individuales de jugador.
- Las notificaciones push ahora usan tokens reales de dispositivo de
  Firebase.
- **Cuenta**: eliminación de cuenta, y páginas públicas de Política de
  Privacidad / Términos de Uso / Acerca de.
- Firma de release de producción de Android configurada.

## 2026-09-07

- Primera versión de la app: proyecto Flutter para Android, iOS y Web con
  el sistema de diseño y la marca de FIFA Queue.
- Autenticación real (crear cuenta, iniciar sesión, restablecer contraseña)
  vía Supabase.
- **Equipo**: crear un equipo, invitar a otras personas por enlace/código
  para compartir, cambiar entre equipos.
- **Buscar** (matchmaking): solo una persona busca a la vez en cada equipo,
  el resto espera en una fila que avanza sola y se actualiza en tiempo real
  — sin necesidad de actualizar manualmente.
