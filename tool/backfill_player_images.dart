// Gera o SQL que preenche fc_player_cards.player_image_url a partir do
// arquivo baixado por tool/fetch_ea_ratings.dart.
//
// POR QUE SO ESSA COLUNA
//   card_image_url aponta pra arte de ITEM do Ultimate Team
//   (FC27/components/items/...), que a EA nao publica pra todo mundo -- 24%
//   do nosso catalogo fica sem ela, e pedir a URL direto responde 403. O
//   retrato (avatarUrl) existe pros 17.873. O app ja resolve isso sozinho:
//   PlayerCardFace usa `cardImageUrl ?? playerImageUrl`, entao preencher o
//   retrato faz as cartas sem arte de item voltarem a mostrar algo, sem
//   alterar em nada as que ja tem.
//
//   Nao mexe em rating, clube, liga nem stats de proposito: conferi contra a
//   API e eles ja batem com o que temos (o Barcola aparece no PSG/84 nos
//   dois lados). Divergencia de clube vem da arte de item, que e outro banco
//   da EA -- nao se conserta por aqui.
//
// SO GERA TEXTO. Nao conecta em banco nenhum; quem aplica e quem roda o SQL.
//
//   dart run tool/backfill_player_images.dart \
//       --in=tool/data/ea_ratings.json --out=tool/data/backfill.sql
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final options = <String, String>{};
  for (final arg in args) {
    if (!arg.startsWith('--')) continue;
    final i = arg.indexOf('=');
    if (i > 0) options[arg.substring(2, i)] = arg.substring(i + 1);
  }
  final input = options['in'] ?? 'tool/data/ea_ratings.json';
  final output = options['out'] ?? 'tool/data/backfill_player_images.sql';

  final raw = jsonDecode(File(input).readAsStringSync()) as Map<String, dynamic>;
  final items = (raw['items'] as List<dynamic>).whereType<Map<String, dynamic>>();

  final rows = <String>[];
  var semAvatar = 0;
  for (final item in items) {
    final id = item['id'];
    final avatar = item['avatarUrl'];
    if (id == null || avatar is! String || avatar.isEmpty) {
      semAvatar++;
      continue;
    }
    rows.add("('${_esc('$id')}','${_esc(avatar)}')");
  }

  final buffer = StringBuffer()
    ..writeln('-- Backfill de fc_player_cards.player_image_url.')
    ..writeln('-- Gerado por tool/backfill_player_images.dart a partir de')
    ..writeln('-- $input (fonte: ${raw['source']}, baixado em ${raw['fetched_at']}).')
    ..writeln('--')
    ..writeln('-- Uma transacao so: ou entra tudo, ou nada.')
    ..writeln('begin;')
    ..writeln()
    ..writeln('create temp table ea_portraits (')
    ..writeln('    ea_id text primary key,')
    ..writeln('    avatar_url text not null')
    ..writeln(') on commit drop;')
    ..writeln()
    ..writeln('insert into ea_portraits (ea_id, avatar_url) values');

  for (var i = 0; i < rows.length; i++) {
    buffer.writeln('${rows[i]}${i == rows.length - 1 ? ';' : ','}');
  }

  buffer
    ..writeln()
    ..writeln('-- O id da EA e o prefixo do nosso provider_card_id')
    ..writeln("-- (ex.: '264652:BASE' -> 264652).")
    ..writeln('update public.fc_player_cards as c')
    ..writeln('set player_image_url = p.avatar_url,')
    ..writeln('    updated_at = now()')
    ..writeln('from ea_portraits as p')
    ..writeln("where split_part(c.provider_card_id, ':', 1) = p.ea_id")
    ..writeln('  and c.player_image_url is distinct from p.avatar_url;')
    ..writeln()
    ..writeln('commit;');

  File(output)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(buffer.toString());

  stdout.writeln('escrito: $output');
  stdout.writeln('  linhas com retrato: ${rows.length}');
  if (semAvatar > 0) {
    stdout.writeln('  itens sem avatarUrl (ignorados): $semAvatar');
  }
}

String _esc(String value) => value.replaceAll("'", "''");
