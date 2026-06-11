import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'support/firebase_ai_native_schema_cases.dart';
import 'support/firebase_ai_response_json_schema_cases.dart';

void main() {
  group('Firebase AI native schema fixtures', () {
    for (final family in FirebaseAiNativeSchemaFixtureFamily.values) {
      group(family.fixtureDirectoryName, () {
        final fixtures = _FirebaseAiNativeSchemaFixtures.load(family);

        test('manifest tracks every case and feature', () {
          final cases = firebaseAiNativeSchemaCases(family);
          final sourceCases = firebaseAiResponseJsonSchemaCases();

          expect(fixtures.sourcePackage, 'firebase_ai');
          // `sourceVersion` is recorded as provenance only; the per-case tests
          // below compare live firebase_ai output to the golden fixtures, which
          // is the real staleness guard. Asserting the exact resolved version
          // only produces false CI failures on benign firebase_ai patch bumps.
          expect(fixtures.sourceClass, family.sourceClass);
          expect(fixtures.fixtureCount, cases.length);
          expect(fixtures.ids, sourceCases.map((schemaCase) => schemaCase.id));

          for (final schemaCase in cases) {
            final fixture = fixtures.byId(schemaCase.id);
            expect(fixture.name, schemaCase.name);
            expect(fixture.source, schemaCase.source);
            expect(fixture.features, schemaCase.features);
            expect(fixture.status, schemaCase.status);
            expect(fixture.comparison, schemaCase.comparison);

            if (schemaCase.isGenerated) {
              expect(fixture.fixture, '${schemaCase.id}.json');
              expect(fixture.unsupportedReason, isNull);
            } else {
              expect(fixture.fixture, isNull);
              expect(fixture.unsupportedReason, schemaCase.unsupportedReason);
            }
          }

          expect(fixtures.featureCoverage, _expectedFeatureCoverage(cases));
        });

        for (final schemaCase in firebaseAiNativeSchemaCases(family)) {
          test('${schemaCase.source} ${schemaCase.name}', () {
            final fixture = fixtures.byId(schemaCase.id);

            if (schemaCase.isGenerated) {
              final nativeSchema = schemaCase.buildJsonSchema();
              expect(fixture.jsonSchema, nativeSchema);
              _expectJsonValue(nativeSchema);
              expect(() => jsonEncode(nativeSchema), returnsNormally);
            } else {
              expect(fixture.jsonSchema, isNull);
              final fixtureFile = File(
                '${fixtures.fixtureDirectory.path}/${schemaCase.id}.json',
              );
              expect(fixtureFile.existsSync(), isFalse);
            }
          });
        }
      });
    }
  });
}

Map<String, List<String>> _expectedFeatureCoverage(
  List<FirebaseAiNativeSchemaCase> cases,
) {
  final expected = <String, List<String>>{};
  for (final schemaCase in cases) {
    for (final feature in schemaCase.features) {
      expected.putIfAbsent(feature, () => <String>[]).add(schemaCase.id);
    }
  }
  for (final ids in expected.values) {
    ids.sort();
  }
  return expected;
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

final class _FirebaseAiNativeSchemaFixtures {
  const _FirebaseAiNativeSchemaFixtures({
    required this.sourcePackage,
    required this.sourceVersion,
    required this.sourceClass,
    required this.ids,
    required this.fixtureCount,
    required this.featureCoverage,
    required this.fixtureDirectory,
    required Map<String, _FirebaseAiNativeSchemaFixture> fixtures,
  }) : _fixtures = fixtures;

  final String sourcePackage;
  final String sourceVersion;
  final String sourceClass;
  final List<String> ids;
  final int fixtureCount;
  final Map<String, List<String>> featureCoverage;
  final Directory fixtureDirectory;
  final Map<String, _FirebaseAiNativeSchemaFixture> _fixtures;

  _FirebaseAiNativeSchemaFixture byId(String id) {
    final fixture = _fixtures[id];
    if (fixture == null) {
      fail('Missing native Firebase AI fixture metadata for $id.');
    }
    return fixture;
  }

  static _FirebaseAiNativeSchemaFixtures load(
    FirebaseAiNativeSchemaFixtureFamily family,
  ) {
    final packageRoot = _findPackageRoot();
    final fixtureDir = Directory(
      '${packageRoot.path}/test/fixtures/${family.fixtureDirectoryName}',
    );
    final manifestFile = File('${fixtureDir.path}/manifest.json');
    if (!manifestFile.existsSync()) {
      fail(
        'Missing Firebase AI native fixture manifest. Run '
        'dart run tool/generate_firebase_ai_response_json_schema_fixtures.dart '
        'from packages/ack_firebase_ai.',
      );
    }

    final manifestJson = _decodeJsonObject(manifestFile);
    final manifestFixtures = _jsonList(manifestJson['fixtures'], 'fixtures');
    final fixtures = <String, _FirebaseAiNativeSchemaFixture>{};
    final ids = <String>[];

    for (final entry in manifestFixtures) {
      final manifestFixture = _jsonObject(entry, 'fixtures[]');
      final id = _jsonString(manifestFixture['id'], 'fixtures[].id');
      final fixtureName = _jsonOptionalString(
        manifestFixture['fixture'],
        'fixtures[].fixture',
      );
      final fixtureFile = fixtureName == null
          ? null
          : File('${fixtureDir.path}/$fixtureName');

      ids.add(id);
      fixtures[id] = _FirebaseAiNativeSchemaFixture(
        id: id,
        name: _jsonString(manifestFixture['name'], 'fixtures[].name'),
        source: _jsonString(manifestFixture['source'], 'fixtures[].source'),
        features: _jsonStringList(
          manifestFixture['features'],
          'fixtures[].features',
        ),
        status: _jsonString(manifestFixture['status'], 'fixtures[].status'),
        comparison: _jsonString(
          manifestFixture['comparison'],
          'fixtures[].comparison',
        ),
        unsupportedReason: _jsonOptionalString(
          manifestFixture['unsupportedReason'],
          'fixtures[].unsupportedReason',
        ),
        fixture: fixtureName,
        jsonSchema: fixtureFile == null ? null : _decodeJsonObject(fixtureFile),
      );
    }

    return _FirebaseAiNativeSchemaFixtures(
      sourcePackage: _jsonString(
        manifestJson['sourcePackage'],
        'sourcePackage',
      ),
      sourceVersion: _jsonString(
        manifestJson['sourceVersion'],
        'sourceVersion',
      ),
      sourceClass: _jsonString(manifestJson['sourceClass'], 'sourceClass'),
      ids: ids,
      fixtureCount: _jsonInt(manifestJson['fixtureCount'], 'fixtureCount'),
      featureCoverage: _featureCoverageFromManifest(manifestJson),
      fixtureDirectory: fixtureDir,
      fixtures: fixtures,
    );
  }
}

final class _FirebaseAiNativeSchemaFixture {
  const _FirebaseAiNativeSchemaFixture({
    required this.id,
    required this.name,
    required this.source,
    required this.features,
    required this.status,
    required this.comparison,
    required this.unsupportedReason,
    required this.fixture,
    required this.jsonSchema,
  });

  final String id;
  final String name;
  final String source;
  final List<String> features;
  final String status;
  final String comparison;
  final String? unsupportedReason;
  final String? fixture;
  final Map<String, Object?>? jsonSchema;
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
  if (value is Map<dynamic, dynamic>) return value.cast<String, Object?>();
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

String? _jsonOptionalString(Object? value, String path) {
  if (value == null) return null;
  return _jsonString(value, path);
}

int _jsonInt(Object? value, String path) {
  if (value is int) return value;
  fail('Expected $path to be an integer, got ${value.runtimeType}.');
}

List<String> _jsonStringList(Object? value, String path) {
  return [for (final item in _jsonList(value, path)) _jsonString(item, path)];
}
