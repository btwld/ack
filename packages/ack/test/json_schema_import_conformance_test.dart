import 'dart:convert';
import 'dart:io';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  final groups =
      jsonDecode(
            File(
              'test/fixtures/json_schema_import/draft2020-12.json',
            ).readAsStringSync(),
          )
          as List;

  group('official draft 2020-12 supported subset', () {
    for (final group in groups.cast<Map<String, Object?>>()) {
      test(group['description']! as String, () {
        final documents = group['documents'] as Map<String, Object?>? ?? {};
        final imported = importJsonSchema(
          group['schema']!,
          documents: documents.map(
            (uri, value) => MapEntry(Uri.parse(uri), value!),
          ),
        );
        expect(imported.isExact, isTrue);
        final roundTrip = importJsonSchema(imported.schema.toJsonSchema());
        expect(roundTrip.isExact, isTrue);
        for (final example in group['tests']! as List) {
          final value = example['data'];
          final expected = example['valid'] as bool;
          final reason = example['description'] as String;
          expect(
            imported.schema.safeParse(value).isOk,
            expected,
            reason: reason,
          );
          expect(
            imported.schema.safeEncode(value).isOk,
            expected,
            reason: reason,
          );
          expect(
            roundTrip.schema.safeParse(value).isOk,
            expected,
            reason: reason,
          );
        }
      });
    }
  });
}
