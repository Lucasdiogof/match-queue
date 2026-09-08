/// Helpers de parsing tolerantes compartilhados pelos modelos do histórico.
/// Números vindos do PostgREST podem chegar como `num` ou `String`; datas
/// como ISO string. Nada aqui deve estourar por um campo ausente.
DateTime parseDate(Object? value, {DateTime? fallback}) {
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed.toUtc();
    }
  }
  return fallback ?? DateTime.now().toUtc();
}

String? parseString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

int parseInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.round() ?? 0;
  }
  return 0;
}

double? parseNullableDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

int? parseNullableInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.round();
  }
  return null;
}
