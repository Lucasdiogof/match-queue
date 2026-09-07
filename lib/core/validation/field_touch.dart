/// Controla quando o erro de UM campo deve aparecer: campo vazio nunca
/// mostra erro antes do submit (mesmo ja tendo sido editado e esvaziado de
/// novo); valor nao-vazio valida em tempo real assim que o usuario mexe
/// nele. `touched` so deve virar `true` num `onChanged` de verdade -- nunca
/// em atribuicao programatica de `controller.text` -- por isso e a propria
/// tela quem seta, nunca este objeto sozinho.
class FieldTouch {
  bool touched = false;

  String? errorFor(
    String value, {
    required bool submitted,
    String? Function(String value)? format,
    String? requiredMessage,
  }) {
    if (value.trim().isEmpty) {
      return submitted ? requiredMessage : null;
    }
    if (!touched && !submitted) {
      return null;
    }
    return format?.call(value);
  }
}
