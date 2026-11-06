import 'package:ack_generator/src/analyzer/schema_first_names.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:test/test.dart';

void main() {
  test('member checks distinguish keywords from generated type collisions', () {
    for (final entry in Keyword.keywords.entries) {
      if (entry.value.isReservedWord) continue;
      final name = entry.key;
      expect(
        ackSchemaFirstFieldNameProblem(name, capturesExtras: false),
        name == 'dynamic'
            ? 'shadows the dynamic type used by generated JSON methods.'
            : isNull,
        reason: name,
      );
      final parsed = parseString(
        content:
            '''class Fields {
  const Fields({required this.$name});
  final bool $name;
  Fields copyWith({bool? $name}) => Fields($name: $name ?? this.$name);
}
''',
        throwIfDiagnostics: false,
      );
      expect(parsed.errors, isEmpty, reason: name);
    }
  });

  test('reserved words remain invalid field names', () {
    for (final entry in Keyword.keywords.entries) {
      if (!entry.value.isReservedWord) continue;
      expect(
        ackSchemaFirstFieldNameProblem(entry.key, capturesExtras: false),
        'cannot be represented as a Dart field name.',
        reason: entry.key,
      );
    }
  });
}
