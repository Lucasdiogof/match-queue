import 'package:fifa_queue/features/notifications/domain/repositories/notification_inbox_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Badge global (item 93/39): mora no app, nao na tela da Central, para o
/// sino poder mostrar a contagem sem recarregar a lista inteira. So guarda
/// um numero -- a lista de verdade e responsabilidade do
/// [NotificationInboxCubit].
class NotificationUnreadCubit extends Cubit<int> {
  NotificationUnreadCubit(this._repository) : super(0);

  final NotificationInboxRepository _repository;

  Future<void> refresh() async {
    try {
      final count = await _repository.fetchUnreadCount();
      if (!isClosed) {
        emit(count);
      }
    } on Object {
      // Badge e conveniencia: uma falha aqui nunca deve quebrar nada mais.
    }
  }

  /// Decremento otimista (item 82): a tela de detalhe/tap ja sabe que
  /// aquele item foi marcado como lido antes do backend confirmar.
  void decrementBy(int amount) {
    if (amount <= 0 || isClosed) {
      return;
    }
    emit((state - amount).clamp(0, 1 << 30));
  }

  void clear() {
    if (!isClosed) {
      emit(0);
    }
  }
}
