import 'dart:convert';
import 'dart:io';

import 'package:ack/ack.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  const root = 'test/fixtures/json_schema_2020_12_full/draft2020-12';
  final formatDirectory = Directory('$root/optional/format');

  group('official 2020-12 optional format assertion', () {
    for (final file in formatDirectory.listSync().whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      final filename = p.basename(file.path);
      final groups = (jsonDecode(file.readAsStringSync()) as List)
          .cast<Map<String, Object?>>();
      for (final group in groups) {
        test('$filename: ${group['description']}', () {
          if (filename == 'unknown.json') {
            expect(
              () => Ack.fromJsonSchema(group['schema']!, assertFormats: true),
              throwsA(isA<JsonSchemaImportException>()),
            );
            return;
          }
          final schema = Ack.fromJsonSchema(
            group['schema']!,
            assertFormats: true,
          );
          final roundTrip = Ack.fromJsonSchema(
            schema.toJsonSchemaPreservingImportedDialect(),
          );
          final mismatches = <String>[];
          for (final example in group['tests']! as List) {
            final testCase = example as Map<String, Object?>;
            final actual = schema.safeParse(testCase['data']).isOk;
            if (actual != testCase['valid']) {
              mismatches.add(
                '${testCase['description']}: expected ${testCase['valid']}, got $actual',
              );
            }
            final exported = roundTrip.safeParse(testCase['data']).isOk;
            if (exported != testCase['valid']) {
              mismatches.add(
                'export: ${testCase['description']}: expected ${testCase['valid']}, got $exported',
              );
            }
          }
          expect(mismatches, isEmpty);
        });
      }
    }
  });

  group('official 2020-12 format-assertion vocabulary', () {
    final groups =
        (jsonDecode(
                  File(
                    '$root/optional/format-assertion.json',
                  ).readAsStringSync(),
                )
                as List)
            .cast<Map<String, Object?>>();
    final documents = <Uri, Object>{
      for (final value in ['true', 'false'])
        Uri.parse(
          'http://localhost:1234/draft2020-12/format-assertion-$value.json',
        ): jsonDecode(
          File(
            '$root/../remotes/draft2020-12/format-assertion-$value.json',
          ).readAsStringSync(),
        )!,
    };
    for (final group in groups) {
      test(group['description']! as String, () {
        final schema = Ack.fromJsonSchema(
          group['schema']!,
          documents: documents,
        );
        final roundTrip = Ack.fromJsonSchema(
          schema.toJsonSchemaPreservingImportedDialect(),
        );
        for (final example in group['tests']! as List) {
          final testCase = example as Map<String, Object?>;
          expect(
            schema.safeParse(testCase['data']).isOk,
            testCase['valid'],
            reason: testCase['description'] as String,
          );
          expect(
            roundTrip.safeParse(testCase['data']).isOk,
            testCase['valid'],
            reason: 'export: ${testCase['description']}',
          );
        }
      });
    }
  });
}
