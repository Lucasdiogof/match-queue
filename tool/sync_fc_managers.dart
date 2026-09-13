// Importer SERVER-SIDE do catalogo CANDIDATO de managers do FC 27 Ultimate
// Team. Mesma familia de tool/sync_fc_cards.dart: script standalone, nunca
// chamado pelo app Flutter, exige a service role key.
//
// NUNCA acessa rede externa nenhuma alem do proprio Supabase -- so le o
// arquivo local tool/data/fc27_managers_candidates.json, ja construido por
// tool/data/build_manager_candidates.py a partir de duas listas cruas
// (tool/data/fc27_managers_fifplay_raw.txt, fc27_managers_fifauteam_raw.txt)
// que alguem colou a mao de onde quis. O importer em si e cego a fonte.
//
// POR QUE "CANDIDATO" E NAO "CONFIRMADO"
// Nenhuma das duas fontes tem hoje uma lista fechada de managers do FC 27
// Ultimate Team: uma ainda mostra o catalogo do FC 26 (tag
// UT_LEGACY_CANDIDATE), a outra e so a expectativa do FC 27 pra Career+UT
// (tag FC27_EXPECTED_CANDIDATE). Toda linha desta importacao entra com
// status=CANDIDATE e is_selectable=true -- disponivel pra escolher agora,
// mas marcada como nao confirmada. Uma reconciliacao futura (novo arquivo
// de candidatos, mesmo processo) e quem promove CANDIDATE -> CONFIRMED ou
// CANDIDATE -> REMOVED; este script nunca faz essa promocao sozinho.
//
// IDEMPOTENCIA
// Nenhuma das fontes expoe um id proprio por manager (seriam paginas de
// lista, nao uma API com id estavel) -- inventar um id da EA ou fazer
// brute-force pra descobrir um e o tipo de dado fabricado que este projeto
// evita. A chave de deduplicacao e (provider, name_key, nation_id), coberta
// por um indice UNIQUE parcial (ver migration
// 20261013100500_fc_managers_candidate_catalog.sql). Rodar o mesmo arquivo
// duas vezes faz upsert, nunca duplica; rodar um arquivo NOVO daqui a um mes
// atualiza source_tags/status das linhas que baterem pela mesma chave.
//
// O QUE ELE NAO FAZ (de proposito, nesta rodada)
//   - Nao importa nenhuma imagem (image_url fica NULL pra toda linha nova).
//     Card art e portrait sao decisao de uma etapa futura, e ainda vao
//     precisar de campos separados -- nao ha por que resolver isso agora.
//   - Nao toca nos 24 managers provider=LOCAL (ficticios, dev/teste): a
//     migration ja marcou is_selectable=false neles, sem apagar nada.
//   - Nao promove nenhuma linha existente pra CONFIRMED sozinho.
//
// USO
//   dart run tool/sync_fc_managers.dart [--dry-run]
//     [--file=tool/data/fc27_managers_candidates.json]
//
// Variaveis de ambiente obrigatorias (mesmas de sync_fc_cards.dart):
//   SUPABASE_URL, SUPABASE_SECRET_KEY (ou SUPABASE_SERVICE_ROLE_KEY)

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const String _provider = 'FC27_UT_CANDIDATE';

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final fileArg = args.firstWhere(
    (a) => a.startsWith('--file='),
    orElse: () => '--file=tool/data/fc27_managers_candidates.json',
  );
  final filePath = fileArg.substring('--file='.length);

  final file = File(filePath);
  if (!file.existsSync()) {
    stderr.writeln('Arquivo nao encontrado: $filePath');
    exitCode = 1;
    return;
  }

  final candidates = (jsonDecode(await file.readAsString()) as List<dynamic>)
      .cast<Map<String, dynamic>>();

  stdout.writeln('Candidatos no arquivo: ${candidates.length}');

  final supabaseUrl = Platform.environment['SUPABASE_URL'];
  final secretKey =
      Platform.environment['SUPABASE_SECRET_KEY'] ??
      Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];

  if (!dryRun && (supabaseUrl == null || secretKey == null)) {
    stderr.writeln(
      'SUPABASE_URL e SUPABASE_SECRET_KEY (ou SUPABASE_SERVICE_ROLE_KEY) '
      'precisam estar no ambiente pra rodar de verdade. Use --dry-run pra '
      'so validar o arquivo sem credencial nenhuma.',
    );
    exitCode = 1;
    return;
  }

  final httpClient = http.Client();
  final headers = <String, String>{'Content-Type': 'application/json'};
  if (secretKey != null) {
    headers['apikey'] = secretKey;
    headers['Authorization'] = 'Bearer $secretKey';
  }

  Map<String, String> nationIdByName = <String, String>{};
  if (!dryRun) {
    final response = await httpClient.get(
      Uri.parse('$supabaseUrl/rest/v1/fc_nations?select=id,name'),
      headers: headers,
    );
    if (response.statusCode >= 300) {
      stderr.writeln(
        'Falha ao buscar fc_nations: ${response.statusCode} ${response.body}',
      );
      exitCode = 1;
      return;
    }
    final rows = (jsonDecode(response.body) as List<dynamic>)
        .cast<Map<String, dynamic>>();
    nationIdByName = <String, String>{
      for (final row in rows) '${row['name']}': '${row['id']}',
    };
    stdout.writeln('Nacoes carregadas do banco: ${nationIdByName.length}');
  }

  var skippedNoNation = 0;
  final rowsToUpsert = <Map<String, dynamic>>[];
  for (final candidate in candidates) {
    final name = candidate['name'] as String;
    final nationName = candidate['nation'] as String?;
    final sourceTags = (candidate['source_tags'] as List<dynamic>)
        .cast<String>();

    String? nationId;
    if (nationName != null) {
      nationId = dryRun ? 'dry-run' : nationIdByName[nationName];
      if (nationId == null) {
        stderr.writeln(
          'Aviso: nacao "$nationName" (manager "$name") nao encontrada em '
          'fc_nations -- pulando esta linha (nunca inventa nacao nova).',
        );
        skippedNoNation++;
        continue;
      }
    } else {
      stderr.writeln(
        'Aviso: manager "$name" sem nacao resolvida no arquivo de '
        'candidatos -- pulando (nunca importa sem nacao pra nao quebrar a '
        'chave de deduplicacao).',
      );
      skippedNoNation++;
      continue;
    }

    rowsToUpsert.add(<String, dynamic>{
      'provider': _provider,
      'name': name,
      'nation_id': dryRun ? null : nationId,
      'status': 'CANDIDATE',
      'is_selectable': true,
      'source_tags': sourceTags,
    });
  }

  stdout.writeln('Linhas prontas para upsert: ${rowsToUpsert.length}');
  stdout.writeln('Puladas por nacao nao resolvida: $skippedNoNation');

  if (dryRun) {
    stdout.writeln('--dry-run: nada foi escrito no banco.');
    return;
  }

  const batchSize = 200;
  var upserted = 0;
  for (var i = 0; i < rowsToUpsert.length; i += batchSize) {
    final batch = rowsToUpsert.sublist(
      i,
      (i + batchSize).clamp(0, rowsToUpsert.length),
    );
    final response = await httpClient.post(
      Uri.parse(
        '$supabaseUrl/rest/v1/fc_managers'
        '?on_conflict=provider,name_key,nation_id',
      ),
      headers: <String, String>{
        ...headers,
        'Prefer': 'resolution=merge-duplicates,return=minimal',
      },
      body: jsonEncode(batch),
    );
    if (response.statusCode >= 300) {
      stderr.writeln(
        'Falha ao upsertar lote (${batch.length} linhas): '
        '${response.statusCode} ${response.body}',
      );
      exitCode = 1;
      continue;
    }
    upserted += batch.length;
    stdout.writeln('Upsertadas $upserted/${rowsToUpsert.length}...');
  }

  httpClient.close();
  stdout.writeln('Concluido. Total upsertado: $upserted.');
}
