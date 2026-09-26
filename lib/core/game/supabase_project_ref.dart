/// Extrai o ref (subdomínio) de uma URL Supabase padrão
/// `https://<ref>.supabase.co`. Retorna `null` se a URL não seguir esse
/// formato (vazia, malformada, ou um domínio customizado) -- nesse caso o
/// guard que usa isso simplesmente não valida em vez de acusar um falso
/// positivo.
String? supabaseProjectRefFrom(String supabaseUrl) {
  if (supabaseUrl.isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(supabaseUrl);
  if (uri == null || uri.host.isEmpty) {
    return null;
  }
  final labels = uri.host.split('.');
  if (labels.length < 3 || !uri.host.endsWith('.supabase.co')) {
    return null;
  }
  return labels.first;
}
