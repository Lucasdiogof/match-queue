import 'package:fifa_queue/features/account/domain/entities/account.dart';

abstract interface class AccountRepository {
  Future<Account?> fetchMyProfile();

  Future<Account> ensureMyProfile({required String fallbackDisplayName});

  Future<Account> updateDisplayName(String displayName);

  /// Escrita pura de `profiles.locale`, usada só para o worker de push saber
  /// em que idioma redigir a notificação. Nunca é lida de volta pelo app: a
  /// fonte da verdade do idioma na UI é a preferência local (LocaleCubit).
  Future<void> updateLocale(String localeTag);

  /// Heartbeat de atividade recente -- escrita espaçada, nunca a cada
  /// segundo. Nunca lida de volta pela UI: quem consome last_active_at é
  /// get_team_player_statuses, do lado dos outros membros.
  Future<void> touchActivity();
}
