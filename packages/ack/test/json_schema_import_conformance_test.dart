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
        final schema = Ack.fromJsonSchema(
          group['schema']!,
          documents: documents.map(
            (uri, value) => MapEntry(Uri.parse(uri), value!),
          ),
        );
        final roundTrip = Ack.fromJsonSchema(schema.toJsonSchema());
        for (final example in group['tests']! as List) {
          final value = example['data'];
          final expected = example['valid'] as bool;
          final reason = example['description'] as String;
          expect(schema.safeParse(value).isOk, expected, reason: reason);
          expect(schema.safeEncode(value).isOk, expected, reason: reason);
          expect(roundTrip.safeParse(value).isOk, expected, reason: reason);
        }
      });
    }
  });
}
