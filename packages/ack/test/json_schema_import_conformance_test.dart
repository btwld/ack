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

  test('asserted date-time matches the official format fixture', () {
    final fixture =
        jsonDecode(
              File(
                'test/fixtures/json_schema_2020_12_full/'
                'draft2020-12/optional/format/date-time.json',
              ).readAsStringSync(),
            )
            as List<dynamic>;
    final imported = Ack.fromJsonSchema({'format': 'date-time'});
    final native = Ack.string().datetime();
    var count = 0;
    for (final group in fixture.cast<Map<String, dynamic>>()) {
      for (final probe
          in (group['tests'] as List).cast<Map<String, dynamic>>()) {
        final value = probe['data'];
        final expected = probe['valid'] as bool;
        final reason = probe['description'] as String;
        expect(imported.safeParse(value).isOk, expected, reason: reason);
        if (value is String) {
          expect(native.safeParse(value).isOk, expected, reason: reason);
        }
        count++;
      }
    }
    expect(count, 43);
  });
}
