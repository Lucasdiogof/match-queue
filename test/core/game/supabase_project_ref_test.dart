import 'package:fifa_queue/core/game/supabase_project_ref.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extrai o ref de uma URL Supabase padrão', () {
    expect(
      supabaseProjectRefFrom('https://lteujeclnhmurcewurkg.supabase.co'),
      'lteujeclnhmurcewurkg',
    );
  });

  test('URL vazia não quebra, retorna null', () {
    expect(supabaseProjectRefFrom(''), isNull);
  });

  test('URL sem o domínio supabase.co retorna null', () {
    expect(supabaseProjectRefFrom('https://example.com'), isNull);
  });

  test('URL malformada retorna null em vez de lançar', () {
    expect(supabaseProjectRefFrom('not a url'), isNull);
  });
}
