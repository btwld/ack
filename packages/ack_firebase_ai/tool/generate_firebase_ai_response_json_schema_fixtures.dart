import 'dart:convert';
import 'dart:io';

import '../test/support/firebase_ai_response_json_schema_cases.dart';

const _fixtureDirectory = 'test/fixtures/firebase_ai_response_json_schema';
const _manifestPath = '$_fixtureDirectory/manifest.json';
const _generatorCommand =
    'dart run tool/generate_firebase_ai_response_json_schema_fixtures.dart';

Future<void> main() async {
  final fixtureDir = Directory(_fixtureDirectory);
  if (!fixtureDir.existsSync()) {
    fixtureDir.createSync(recursive: true);
  }

  _deleteStaleFixtures(fixtureDir);

  final cases = firebaseAiResponseJsonSchemaCases();
  final featureCoverage = <String, List<String>>{};
  final manifestFixtures = <Map<String, Object?>>[];

  for (final schemaCase in cases) {
    final fixtureName = '${schemaCase.id}.json';
    final fixturePath = '$_fixtureDirectory/$fixtureName';
    File(
      fixturePath,
    ).writeAsStringSync('${_prettyJson(schemaCase.buildJsonSchema())}\n');

    manifestFixtures.add({
      'id': schemaCase.id,
      'name': schemaCase.name,
      'source': schemaCase.source,
      'features': schemaCase.features,
      'fixture': fixtureName,
    });

    for (final feature in schemaCase.features) {
      featureCoverage.putIfAbsent(feature, () => <String>[]).add(schemaCase.id);
    }
  }

  final manifest = {
    'description':
        'Golden fixtures for ACK to Firebase AI responseJsonSchema conversion.',
    'generatedBy': _generatorCommand,
    'fixtureCount': cases.length,
    'featureCoverage': {
      for (final feature in featureCoverage.keys.toList()..sort())
        feature: featureCoverage[feature]!..sort(),
    },
    'fixtures': manifestFixtures,
  };

  File(_manifestPath).writeAsStringSync('${_prettyJson(manifest)}\n');

  stdout.writeln(
    'Wrote ${cases.length} Firebase AI responseJsonSchema fixtures to '
    '$_fixtureDirectory.',
  );
}

void _deleteStaleFixtures(Directory fixtureDir) {
  for (final entry in fixtureDir.listSync()) {
    if (entry is File && entry.path.endsWith('.json')) {
      entry.deleteSync();
    }
  }
}

String _prettyJson(Object? value) {
  return const JsonEncoder.withIndent('  ').convert(value);
}
