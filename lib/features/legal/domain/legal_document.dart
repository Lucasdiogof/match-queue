/// Conteúdo de Privacidade/Termos vive como texto Dart puro, por locale --
/// não como chave de l10n (ARB), porque é prosa longa que muda pouco e não
/// precisa de plural/ICU. As poucas strings de navegação/rótulo ao redor
/// (título da página, botão) continuam no ARB normal.
class LegalSection {
  const LegalSection({required this.title, required this.body});

  final String title;
  final String body;
}

class LegalDocument {
  const LegalDocument({
    required this.updatedAt,
    required this.sections,
    required this.nonAffiliationDisclaimer,
  });

  final String updatedAt;
  final List<LegalSection> sections;
  final String nonAffiliationDisclaimer;
}
