// Generated parts use this helper across the package boundary.
// ignore_for_file: invalid_use_of_internal_member

import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  test('field policies replace custom presence while keeping the codec', () {
    final custom = Ack.string()
        .minLength(2)
        .codec<Uri>(decode: Uri.parse, encode: (value) => value.toString())
        .optional()
        .nullable()
        .withDefault(Uri.parse('inner'));
    final field = AckSchema.forGeneratedField(custom);
    final required = Ack.object({'value': field});
    expect(required.safeParse({}).isFail, isTrue);
    expect(required.safeParse({'value': null}).isFail, isTrue);
    expect(required.safeParse({'value': 'x'}).isFail, isTrue);
    expect(required.parse({'value': 'valid'}), {'value': Uri.parse('valid')});
    expect(required.encode({'value': Uri.parse('valid')}), {'value': 'valid'});
    expect(field.toJsonSchema().containsKey('default'), isFalse);

    final optional = field.optional().nullable().describe('field');
    expect(Ack.object({'value': optional}).parse({}), isEmpty);
    expect(Ack.object({'value': optional}).parse({'value': null}), {
      'value': null,
    });
    expect(optional.toJsonSchema().containsKey('default'), isFalse);

    final defaulted = field.nullable().withDefault(Uri.parse('fallback'));
    final schema = Ack.object({'value': defaulted});
    expect(schema.parse({}), {'value': Uri.parse('fallback')});
    expect(schema.parse({'value': null}), {'value': Uri.parse('fallback')});
    expect(schema.encode({'value': null}), {'value': 'fallback'});
    expect(defaulted.toJsonSchema()['default'], 'fallback');
  });

  test('suppressing a field default preserves nested property defaults', () {
    final custom = Ack.object({
      'child': Ack.string().withDefault('child-default'),
    }).withDefault(const {'child': 'root-default'});
    final field = AckSchema.forGeneratedField(custom).describe('field');
    final exported = field.toJsonSchema();
    expect(exported.containsKey('default'), isFalse);
    expect(exported['properties'], {
      'child': {'type': 'string', 'default': 'child-default'},
    });
    expect(field.parse({}), {'child': 'child-default'});
    expect(custom.toJsonSchema()['default'], {'child': 'root-default'});
  });
}
