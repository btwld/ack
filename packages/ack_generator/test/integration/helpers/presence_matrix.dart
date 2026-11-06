import 'dart:io';

import 'package:path/path.dart' as p;

/// Adds the same field-policy matrix for inferred scalars and custom codecs to
/// an existing build-runner fixture, so generation, analysis and runtime tests
/// all exercise the emitted code in one build.
void writePresenceMatrix(Directory project) {
  final models = StringBuffer(r'''
import 'package:ack/ack.dart';
part 'presence_matrix.g.dart';

final class MatrixValue {
  const MatrixValue(this.text);
  final String text;
}

AckSchema<String, MatrixValue> matrixPlain() =>
    Ack.string().minLength(2).codec<MatrixValue>(
      decode: MatrixValue.new, encode: (value) => value.text,
    );
AckSchema<String, MatrixValue> matrixWrapped() =>
    matrixPlain().optional().nullable();
AckSchema<String, MatrixValue> matrixDefaulted() =>
    matrixWrapped().withDefault(const MatrixValue('inner'));
''');
  final tests = StringBuffer('''
import 'package:ack/ack.dart';
import 'package:ack_class_first_runtime/presence_matrix.dart';
import 'package:test/test.dart';

void main() {
''');
  for (final source in ['Inferred', 'Plain', 'Wrapped', 'Defaulted']) {
    final custom = source != 'Inferred';
    final type = custom ? 'MatrixValue' : 'String';
    final defaultCode = custom ? "const MatrixValue('fallback')" : "'fallback'";
    for (final presence in ['Required', 'Optional', 'Default']) {
      for (final nullPolicy in ['NonNullable', 'Nullable', 'NotNull']) {
        final name = '$source$presence$nullPolicy';
        final nullable = nullPolicy != 'NonNullable';
        final acceptsNull = nullPolicy == 'Nullable';
        final defaulted = presence == 'Default';
        final required = presence == 'Required';
        final optionalNonNullable = presence == 'Optional' && !nullable;
        final parameter = defaulted
            ? 'this.value = $defaultCode'
            : optionalNonNullable
            ? '$type? value'
            : required && !nullable
            ? 'required this.value'
            : 'this.value';
        models.writeln('''
@Schemable(${custom ? 'schemas: [matrix$source]' : ''})
final class $name with _\$${name}Ack {
  const $name({$parameter})${optionalNonNullable ? ' : value = value ?? $defaultCode' : ''};
  ${required ? '@IsRequired()' : ''}
  ${presence == 'Optional' ? '@IsOptional()' : ''}
  ${nullPolicy == 'NotNull' ? '@IsNotNull()' : ''}
  ${custom ? '' : '@HasMinLength(2)'}
  final $type${nullable ? '?' : ''} value;
}
''');
        for (final input in ['missing', 'null', 'value']) {
          final json = switch (input) {
            'missing' => '<String, Object?>{}',
            'null' => "<String, Object?>{'value': null}",
            _ => "<String, Object?>{'value': 'valid'}",
          };
          final succeeds = input == 'missing'
              ? !required
              : input == 'null'
              ? acceptsNull
              : true;
          final expected = input == 'value'
              ? "'valid'"
              : defaulted || optionalNonNullable
              ? "'fallback'"
              : 'null';
          final encoded = presence == 'Optional' && expected == 'null'
              ? '<String, Object?>{}'
              : "{'value': $expected}";
          tests.writeln('''
  test('$name parses $input', () {
    final result = ${name}Schema.safeParse($json);
    expect(result.isOk, $succeeds);
    ${succeeds ? '''
    final model = result.getOrThrow()!;
    expect(model.value${custom
                    ? nullable
                          ? '?.text'
                          : '.text'
                    : ''}, $expected);
    expect(${name}Schema.safeEncode(model).getOrThrow(), $encoded);
    ''' : '''
    final error = result.getError() as SchemaNestedError;
    expect(error.errors.single, isA<SchemaConstraintsError>());
    '''}
  });
''');
        }
        tests.writeln('''
  test('$name preserves validation and exports field policy', () {
    expect(${name}Schema.safeParse({'value': 'x'}).isFail, true);
    final schema = ${name}Schema.toJsonSchema();
    expect((schema['required'] as List? ?? []).contains('value'), $required);
    final property = (schema['properties'] as Map)['value'] as Map;
    expect(property.containsKey('default'), $defaulted);
    expect(Ack.fromJsonSchema(property.cast<String, Object?>()).safeParse(null).isOk, $acceptsNull);
    ${defaulted ? "expect(property['default'], 'fallback');" : ''}
    ${nullable && !defaulted ? 'expect(${name}Schema.safeEncode($name()).isOk, ${!required || acceptsNull});' : ''}
    ${nullable && defaulted ? "expect($name(value: null).toJson(), {'value': 'fallback'});" : ''}
  });
''');
      }
    }
  }
  tests.writeln('}');
  File(
    p.join(project.path, 'lib', 'presence_matrix.dart'),
  ).writeAsStringSync(models.toString());
  File(
    p.join(project.path, 'test', 'presence_matrix_test.dart'),
  ).writeAsStringSync(tests.toString());
}
