import 'dart:convert';
import 'dart:io';

import 'package:ack/ack.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  const fixtureRoot = 'test/fixtures/json_schema_2020_12_full';
  final groups = <Map<String, Object?>>[
    for (final filename in [
      'dynamicRef.json',
      'unevaluatedProperties.json',
      'unevaluatedItems.json',
    ])
      for (final group
          in (jsonDecode(
                    File(
                      '$fixtureRoot/draft2020-12/$filename',
                    ).readAsStringSync(),
                  )
                  as List)
              .cast<Map<String, Object?>>())
        if (filename == 'dynamicRef.json' ||
            (group['description'] as String).contains(r'$dynamicRef'))
          {...group, 'description': '$filename: ${group['description']}'},
  ];
  final remotes = Directory('$fixtureRoot/remotes/draft2020-12');
  final documents = <Uri, Object>{
    for (final file in remotes.listSync(recursive: true).whereType<File>())
      if (file.path.endsWith('.json'))
        Uri.parse(
          'http://localhost:1234/draft2020-12/'
          '${p.relative(file.path, from: remotes.path).replaceAll('\\', '/')}',
        ): jsonDecode(
          file.readAsStringSync(),
        )!,
  };

  group('official 2020-12 dynamicRef validation', () {
    for (final group in groups) {
      test(group['description']! as String, () {
        final schema = Ack.fromJsonSchema(
          group['schema']!,
          baseUri: Uri.parse(
            'http://localhost:1234/draft2020-12/__dynamic_ref_test__.json',
          ),
          documents: documents,
        );
        final exported = Ack.fromJsonSchema(schema.toJsonSchema());
        for (final example in group['tests']! as List) {
          final value = example['data'];
          final expected = example['valid'] as bool;
          final reason = example['description'] as String;
          expect(schema.safeParse(value).isOk, expected, reason: reason);
          expect(schema.safeEncode(value).isOk, expected, reason: reason);
          expect(exported.safeParse(value).isOk, expected, reason: reason);
        }
      });
    }
  });
}
