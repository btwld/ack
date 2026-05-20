import 'dart:convert';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;
import 'package:test/test.dart';

import 'support/firebase_ai_response_json_schema_cases.dart';

void main() {
  final fixtures = _FirebaseAiResponseJsonSchemaFixtures.load();

  group('Firebase AI responseJsonSchema fixtures', () {
    test('manifest tracks every generated case and feature', () {
      final cases = firebaseAiResponseJsonSchemaCases();

      expect(fixtures.fixtureCount, cases.length);
      expect(fixtures.ids, cases.map((schemaCase) => schemaCase.id).toList());
      for (final schemaCase in cases) {
        final fixture = fixtures.byId(schemaCase.id);
        expect(fixture.name, schemaCase.name);
        expect(fixture.source, schemaCase.source);
        expect(fixture.features, schemaCase.features);
      }

      final expectedFeatureCoverage = <String, List<String>>{};
      for (final schemaCase in cases) {
        for (final feature in schemaCase.features) {
          expectedFeatureCoverage
              .putIfAbsent(feature, () => <String>[])
              .add(schemaCase.id);
        }
      }
      for (final ids in expectedFeatureCoverage.values) {
        ids.sort();
      }

      expect(fixtures.featureCoverage, expectedFeatureCoverage);
    });

    for (final schemaCase in firebaseAiResponseJsonSchemaCases()) {
      test('${schemaCase.source} ${schemaCase.name}', () {
        final fixture = fixtures.byId(schemaCase.id);
        final jsonSchema = schemaCase.buildJsonSchema();

        expect(jsonSchema, fixture.jsonSchema);
        expect(jsonSchema, schemaCase.buildCanonicalJsonSchema());
        _expectFirebaseGenerationConfigSerializes(jsonSchema);
      });
    }
  });
}

void _expectFirebaseGenerationConfigSerializes(
  Map<String, Object?> jsonSchema,
) {
  _expectJsonValue(jsonSchema);
  expect(() => jsonEncode(jsonSchema), returnsNormally);

  final configJson = firebase_ai.GenerationConfig(
    responseMimeType: 'application/json',
    responseJsonSchema: jsonSchema,
  ).toJson();

  expect(configJson['responseMimeType'], 'application/json');
  expect(configJson['responseJsonSchema'], jsonSchema);
}

void _expectJsonValue(Object? value, [String path = r'$']) {
  if (value == null || value is String || value is num || value is bool) {
    return;
  }

  if (value is List<dynamic>) {
    for (var index = 0; index < value.length; index += 1) {
      _expectJsonValue(value[index], '$path[$index]');
    }
    return;
  }

  if (value is Map<dynamic, dynamic>) {
    for (final entry in value.entries) {
      expect(entry.key, isA<String>(), reason: '$path keys must be strings');
      _expectJsonValue(entry.value, '$path.${entry.key}');
    }
    return;
  }

  fail('Expected $path to be JSON-compatible, got ${value.runtimeType}.');
}

final class _FirebaseAiResponseJsonSchemaFixtures {
  const _FirebaseAiResponseJsonSchemaFixtures({
    required this.ids,
    required this.fixtureCount,
    required this.featureCoverage,
    required Map<String, _FirebaseAiResponseJsonSchemaFixture> fixtures,
  }) : _fixtures = fixtures;

  final List<String> ids;
  final int fixtureCount;
  final Map<String, List<String>> featureCoverage;
  final Map<String, _FirebaseAiResponseJsonSchemaFixture> _fixtures;

  _FirebaseAiResponseJsonSchemaFixture byId(String id) {
    final fixture = _fixtures[id];
    if (fixture == null) {
      fail(
        'Missing fixture for $id. Run '
        'dart run tool/generate_firebase_ai_response_json_schema_fixtures.dart '
        'from packages/ack_firebase_ai.',
      );
    }
    return fixture;
  }

  static _FirebaseAiResponseJsonSchemaFixtures load() {
    final packageRoot = _findPackageRoot();
    final fixtureDir = Directory(
      '${packageRoot.path}/test/fixtures/firebase_ai_response_json_schema',
    );
    final manifestFile = File('${fixtureDir.path}/manifest.json');
    if (!manifestFile.existsSync()) {
      fail(
        'Missing Firebase AI responseJsonSchema fixture manifest. Run '
        'dart run tool/generate_firebase_ai_response_json_schema_fixtures.dart '
        'from packages/ack_firebase_ai.',
      );
    }

    final manifestJson = _decodeJsonObject(manifestFile);
    final manifestFixtures = _jsonList(manifestJson['fixtures'], 'fixtures');
    final fixtures = <String, _FirebaseAiResponseJsonSchemaFixture>{};
    final ids = <String>[];

    for (final entry in manifestFixtures) {
      final manifestFixture = _jsonObject(entry, 'fixtures[]');
      final id = _jsonString(manifestFixture['id'], 'fixtures[].id');
      final fixtureName = _jsonString(
        manifestFixture['fixture'],
        'fixtures[].fixture',
      );
      final fixtureFile = File('${fixtureDir.path}/$fixtureName');

      ids.add(id);
      fixtures[id] = _FirebaseAiResponseJsonSchemaFixture(
        id: id,
        name: _jsonString(manifestFixture['name'], 'fixtures[].name'),
        source: _jsonString(manifestFixture['source'], 'fixtures[].source'),
        features: _jsonStringList(
          manifestFixture['features'],
          'fixtures[].features',
        ),
        jsonSchema: _decodeJsonObject(fixtureFile),
      );
    }

    return _FirebaseAiResponseJsonSchemaFixtures(
      ids: ids,
      fixtureCount: _jsonInt(manifestJson['fixtureCount'], 'fixtureCount'),
      featureCoverage: _featureCoverageFromManifest(manifestJson),
      fixtures: fixtures,
    );
  }
}

final class _FirebaseAiResponseJsonSchemaFixture {
  const _FirebaseAiResponseJsonSchemaFixture({
    required this.id,
    required this.name,
    required this.source,
    required this.features,
    required this.jsonSchema,
  });

  final String id;
  final String name;
  final String source;
  final List<String> features;
  final Map<String, Object?> jsonSchema;
}

Directory _findPackageRoot() {
  var current = Directory.current.absolute;
  while (true) {
    final pubspec = File('${current.path}/pubspec.yaml');
    if (pubspec.existsSync() &&
        pubspec.readAsStringSync().contains('name: ack_firebase_ai')) {
      return current;
    }

    final nested = Directory('${current.path}/packages/ack_firebase_ai');
    final nestedPubspec = File('${nested.path}/pubspec.yaml');
    if (nestedPubspec.existsSync() &&
        nestedPubspec.readAsStringSync().contains('name: ack_firebase_ai')) {
      return nested;
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      fail(
        'Could not find packages/ack_firebase_ai from ${Directory.current}.',
      );
    }
    current = parent;
  }
}

Map<String, List<String>> _featureCoverageFromManifest(
  Map<String, Object?> manifestJson,
) {
  final featureCoverage = _jsonObject(
    manifestJson['featureCoverage'],
    'featureCoverage',
  );
  return {
    for (final entry in featureCoverage.entries)
      entry.key: _jsonStringList(entry.value, 'featureCoverage.${entry.key}'),
  };
}

Map<String, Object?> _decodeJsonObject(File file) {
  if (!file.existsSync()) {
    fail('Missing fixture file: ${file.path}');
  }
  return _jsonObject(jsonDecode(file.readAsStringSync()), file.path);
}

Map<String, Object?> _jsonObject(Object? value, String path) {
  if (value is Map<String, Object?>) return value;
  if (value is Map<dynamic, dynamic>) {
    return value.cast<String, Object?>();
  }
  fail('Expected $path to be a JSON object, got ${value.runtimeType}.');
}

List<Object?> _jsonList(Object? value, String path) {
  if (value is List<Object?>) return value;
  if (value is List<dynamic>) return value.cast<Object?>();
  fail('Expected $path to be a JSON array, got ${value.runtimeType}.');
}

String _jsonString(Object? value, String path) {
  if (value is String) return value;
  fail('Expected $path to be a string, got ${value.runtimeType}.');
}

int _jsonInt(Object? value, String path) {
  if (value is int) return value;
  fail('Expected $path to be an integer, got ${value.runtimeType}.');
}

List<String> _jsonStringList(Object? value, String path) {
  return [for (final item in _jsonList(value, path)) _jsonString(item, path)];
}
