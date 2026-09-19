import 'dart:async';

/// Aviso global de "a sessao deixou de valer". O [SupabaseErrorMapper] e o
/// unico ponto por onde todo erro do Supabase passa, entao ele dispara isto
/// quando classifica algo como sessao expirada; o AuthCubit escuta e tenta
/// renovar a sessao ou leva o usuario pro login -- sem cada tela precisar
/// tratar esse caso por conta propria.
class SessionExpiredSignal {
  final StreamController<void> _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
