import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'support/firebase_ai_native_schema_cases.dart';
import 'support/firebase_ai_response_json_schema_cases.dart';

void main() {
  group('Firebase AI schema capability matrix', () {
    test('tracks every ACK adapter case for both Firebase native families', () {
      final ackCases = firebaseAiResponseJsonSchemaCases();

      for (final family in FirebaseAiNativeSchemaFixtureFamily.values) {
        final nativeCases = firebaseAiNativeSchemaCases(family);

        expect(nativeCases.map((schemaCase) => schemaCase.id), [
          for (final schemaCase in ackCases) schemaCase.id,
        ]);
        expect(
          nativeCases.map((schemaCase) => schemaCase.comparison).toSet(),
          containsAll([
            FirebaseAiSchemaComparison.adapterTransformNeeded.jsonValue,
            FirebaseAiSchemaComparison.unsupportedByFirebaseSchema.jsonValue,
          ]),
        );
      }
    });

    test('records known provider-specific classifications', () {
      final schemaCases = _casesById(
        firebaseAiNativeSchemaCases(FirebaseAiNativeSchemaFixtureFamily.schema),
      );
      final jsonSchemaCases = _casesById(
        firebaseAiNativeSchemaCases(
          FirebaseAiNativeSchemaFixtureFamily.jsonSchema,
        ),
      );

      expect(
        schemaCases['ack_schema_string_literal']!.comparison,
        FirebaseAiSchemaComparison.adapterTransformNeeded.jsonValue,
      );
      expect(
        schemaCases['ack_schema_recursive_lazy_ref']!.comparison,
        FirebaseAiSchemaComparison.unsupportedByFirebaseSchema.jsonValue,
      );
      expect(
        jsonSchemaCases['ack_schema_recursive_lazy_ref']!.comparison,
        FirebaseAiSchemaComparison.backendLimited.jsonValue,
      );
      expect(
        jsonSchemaCases['schema_model_allof']!.comparison,
        FirebaseAiSchemaComparison.unsupportedByFirebaseSchema.jsonValue,
      );
      expect(
        jsonSchemaCases['schema_model_boolean_const']!.comparison,
        FirebaseAiSchemaComparison.unsupportedByFirebaseSchema.jsonValue,
      );
    });

    test(
      'generated native fixtures are intentionally comparable to ACK output',
      () {
        final ackFixtures = _AckFixtureSet.load();

        for (final family in FirebaseAiNativeSchemaFixtureFamily.values) {
          for (final nativeCase in firebaseAiNativeSchemaCases(family)) {
            final ackJson = ackFixtures.byId(nativeCase.id);

            switch (nativeCase.comparisonEnum) {
              case FirebaseAiSchemaComparison.exact:
                expect(nativeCase.buildJsonSchema(), ackJson);
              case FirebaseAiSchemaComparison.equivalent:
              case FirebaseAiSchemaComparison.adapterTransformNeeded:
              case FirebaseAiSchemaComparison.backendLimited:
                if (nativeCase.isGenerated) {
                  expect(nativeCase.buildJsonSchema(), isNot(ackJson));
                }
              case FirebaseAiSchemaComparison.unsupportedByFirebaseSchema:
                expect(nativeCase.isGenerated, isFalse);
            }
          }
        }
      },
    );
  });
}

Map<String, FirebaseAiNativeSchemaCase> _casesById(
  List<FirebaseAiNativeSchemaCase> cases,
) {
  return {for (final schemaCase in cases) schemaCase.id: schemaCase};
}

final class _AckFixtureSet {
  const _AckFixtureSet(this._fixtures);

  final Map<String, Map<String, Object?>> _fixtures;

  Map<String, Object?> byId(String id) {
    final fixture = _fixtures[id];
    if (fixture == null) fail('Missing ACK fixture for $id.');
    return fixture;
  }

  static _AckFixtureSet load() {
    final packageRoot = _findPackageRoot();
    final fixtureDir = Directory(
      '${packageRoot.path}/test/fixtures/firebase_ai_response_json_schema',
    );
    final manifestFile = File('${fixtureDir.path}/manifest.json');
    final manifest = _jsonObject(
      jsonDecode(manifestFile.readAsStringSync()),
      manifestFile.path,
    );
    final fixtures = <String, Map<String, Object?>>{};

    for (final entry in _jsonList(manifest['fixtures'], 'fixtures')) {
      final manifestFixture = _jsonObject(entry, 'fixtures[]');
      final id = _jsonString(manifestFixture['id'], 'fixtures[].id');
      final fixtureName = _jsonString(
        manifestFixture['fixture'],
        'fixtures[].fixture',
      );
      final fixtureFile = File('${fixtureDir.path}/$fixtureName');
      fixtures[id] = _jsonObject(
        jsonDecode(fixtureFile.readAsStringSync()),
        fixtureFile.path,
      );
    }

    return _AckFixtureSet(fixtures);
  }
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
