/// Janela de tempo dos filtros de histórico e estatísticas. O recorte é por
/// `finished_at >= from` (o `to` fica aberto para "de tal data até agora").
enum StatsPeriod {
  all,
  last7Days,
  last30Days;

  /// Início da janela relativo a [now], ou nulo para "todo o período".
  DateTime? from(DateTime now) => switch (this) {
    StatsPeriod.all => null,
    StatsPeriod.last7Days => now.subtract(const Duration(days: 7)),
    StatsPeriod.last30Days => now.subtract(const Duration(days: 30)),
  };
}
