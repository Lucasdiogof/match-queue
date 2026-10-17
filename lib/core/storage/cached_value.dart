import 'package:equatable/equatable.dart';

/// Valor lido de um cache local junto com o momento em que foi gravado, para
/// a tela poder dizer "Ultima atualizacao" sem adivinhar.
class CachedValue<T> extends Equatable {
  const CachedValue(this.value, this.savedAt);

  final T value;
  final DateTime savedAt;

  @override
  List<Object?> get props => <Object?>[value, savedAt];
}
