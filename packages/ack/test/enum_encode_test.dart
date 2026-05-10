import 'package:ack/ack.dart';
import 'package:test/test.dart';

enum _Status { active, inactive, archived }

void main() {
  group('EnumSchema runtime/boundary split (M8)', () {
    group('parse', () {
      test('accepts the enum value itself', () {
        final schema = Ack.enumValues(_Status.values);
        expect(schema.parse(_Status.active), equals(_Status.active));
      });

      test('accepts the enum .name string', () {
        final schema = Ack.enumValues(_Status.values);
        expect(schema.parse('active'), equals(_Status.active));
        expect(schema.parse('inactive'), equals(_Status.inactive));
      });

      test('accepts a legacy integer index (per A4 decision)', () {
        // Decision A4 (codec-open-questions.md:84) keeps integer-index parsing
        // for legacy boundary input on the parse side.
        final schema = Ack.enumValues(_Status.values);
        expect(schema.parse(0), equals(_Status.active));
        expect(schema.parse(2), equals(_Status.archived));
      });

      test('rejects unknown name', () {
        final schema = Ack.enumValues(_Status.values);
        final result = schema.safeParse('pending');
        expect(result.isFail, isTrue);
      });
    });

    group('encode', () {
      test('returns the enum value\'s .name string', () {
        final schema = Ack.enumValues(_Status.values);
        expect(schema.encode(_Status.active), equals('active'));
        expect(schema.encode(_Status.archived), equals('archived'));
      });

      test('rejects a boundary string (must be enum runtime value)', () {
        // Per A4: encode and _validateRuntime require enum values, not the
        // legacy boundary forms (string name or integer index).
        final schema = Ack.enumValues(_Status.values);
        final result = schema.safeEncode('active');
        expect(result.isFail, isTrue);
        expect(result.getError(), isA<SchemaEncodeError>());
      });

      test('rejects an integer index (must be enum runtime value)', () {
        final schema = Ack.enumValues(_Status.values);
        final result = schema.safeEncode(0);
        expect(result.isFail, isTrue);
        expect(result.getError(), isA<SchemaEncodeError>());
      });

      test('rejects an enum value outside the schema\'s allowed subset', () {
        // Schema only allows _Status.active. Encoding _Status.inactive must
        // fail via the values-membership constraint, not as a type mismatch.
        final schema = Ack.enumValues([_Status.active]);
        final result = schema.safeEncode(_Status.inactive);
        expect(result.isFail, isTrue);
        expect(result.getError(), isA<SchemaConstraintsError>());
      });
    });

    group('round-trip', () {
      test('parse(encode(value)) == value for every allowed enum value', () {
        final schema = Ack.enumValues(_Status.values);
        for (final v in _Status.values) {
          expect(schema.parse(schema.encode(v)), equals(v));
        }
      });
    });

    group('integration', () {
      test('ObjectSchema with EnumSchema child encodes enum to .name', () {
        final schema = Ack.object({
          'status': Ack.enumValues(_Status.values),
        });
        final encoded = schema.encode({'status': _Status.archived});
        expect(encoded, equals({'status': 'archived'}));
      });

      test('ListSchema with EnumSchema items encodes each enum to .name', () {
        final schema = Ack.list(Ack.enumValues(_Status.values));
        final encoded = schema.encode([_Status.active, _Status.inactive]);
        expect(encoded, equals(['active', 'inactive']));
      });
    });

    group('null handling', () {
      test('null on a non-nullable enum schema fails on encode', () {
        final schema = Ack.enumValues(_Status.values);
        final result = schema.safeEncode(null);
        expect(result.isFail, isTrue);
        expect(result.getError(), isA<SchemaEncodeError>());
      });

      test('null on a nullable enum schema returns Ok(null) on encode', () {
        final schema = Ack.enumValues(_Status.values).nullable();
        final result = schema.safeEncode(null);
        expect(result.isOk, isTrue);
        expect(result.getOrNull(), isNull);
      });
    });
  });
}
