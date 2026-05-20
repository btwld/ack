import 'package:ack/ack.dart';
import 'package:test/test.dart';

final class _Event {
  _Event(this.createdAt);
  final DateTime createdAt;
}

final class _User {
  _User(this.name);
  final String name;
}

enum _Role { admin, member }

final class _StartsWithConstraint extends Constraint<String>
    with Validator<String> {
  _StartsWithConstraint(this.prefix)
    : super(constraintKey: 'startsWith', description: 'Starts with $prefix');

  final String prefix;

  @override
  bool isValid(String value) => value.startsWith(prefix);

  @override
  String buildMessage(String value) => 'Expected value to start with $prefix';
}

final class _OperationRecordingSchema extends AckSchema<String, String>
    with FluentSchema<String, String, _OperationRecordingSchema> {
  _OperationRecordingSchema({
    required this.parseOperations,
    required this.validateOperations,
    required this.encodeOperations,
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  final List<SchemaOperation> parseOperations;
  final List<SchemaOperation> validateOperations;
  final List<SchemaOperation> encodeOperations;

  @override
  SchemaType get schemaType => SchemaType.string;

  @override
  SchemaResult<String> parseWithContext(Object? value, SchemaContext context) {
    parseOperations.add(context.operation);
    return validateRuntimeWithContext(value, context);
  }

  @override
  SchemaResult<String> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    validateOperations.add(context.operation);
    return SchemaResult.ok(value as String);
  }

  @override
  SchemaResult<String> encodeWithContext(String value, SchemaContext context) {
    encodeOperations.add(context.operation);
    final validated = validateRuntimeWithContext(value, context);
    if (validated.isFail) return SchemaResult.fail(validated.getError());
    return SchemaResult.ok(value);
  }

  @override
  _OperationRecordingSchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<String>>? constraints,
    List<Refinement<String>>? refinements,
  }) {
    return _OperationRecordingSchema(
      parseOperations: parseOperations,
      validateOperations: validateOperations,
      encodeOperations: encodeOperations,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() => const {'type': 'string'};
}

void main() {
  group('AckSchema<Boundary, Runtime> type model', () {
    test('Ack.string is AckSchema<String, String>', () {
      final AckSchema<String, String> schema = Ack.string();
      final String? parsed = schema.parse('hello');
      final String? encoded = schema.encode('hello');
      expect(parsed, 'hello');
      expect(encoded, 'hello');
    });

    test('Ack.integer is AckSchema<int, int>', () {
      final AckSchema<int, int> schema = Ack.integer();
      final int? parsed = schema.parse(42);
      final int? encoded = schema.encode(42);
      expect(parsed, 42);
      expect(encoded, 42);
    });

    test('Ack.double is AckSchema<double, double>', () {
      final AckSchema<double, double> schema = Ack.double();
      final double? parsed = schema.parse(1.5);
      final double? encoded = schema.encode(1.5);
      expect(parsed, 1.5);
      expect(encoded, 1.5);
    });

    test('Ack.number is AckSchema<num, num>', () {
      final AckSchema<num, num> schema = Ack.number();
      final num? parsed = schema.parse(42);
      final num? encoded = schema.encode(42);
      expect(parsed, 42);
      expect(encoded, 42);
    });

    test('Ack.boolean is AckSchema<bool, bool>', () {
      final AckSchema<bool, bool> schema = Ack.boolean();
      final bool? parsed = schema.parse(true);
      final bool? encoded = schema.encode(true);
      expect(parsed, true);
      expect(encoded, true);
    });
  });

  group('Built-in codecs', () {
    test('Ack.date encode is statically typed as String', () {
      final schema = Ack.date();
      final String? encoded = schema.encode(DateTime(2026, 5, 10));
      expect(encoded, '2026-05-10');
    });

    test('Ack.date parse is statically typed as DateTime', () {
      final schema = Ack.date();
      final DateTime? parsed = schema.parse('2026-05-10');
      expect(parsed, isA<DateTime>());
      expect(parsed!.year, 2026);
      expect(parsed.month, 5);
      expect(parsed.day, 10);
    });

    test('Ack.datetime encodes to ISO 8601 string', () {
      final schema = Ack.datetime();
      final value = DateTime.utc(2026, 5, 10, 12, 30);
      final String? encoded = schema.encode(value);
      expect(encoded, '2026-05-10T12:30:00.000Z');
    });

    test('Ack.duration encode is statically typed as int', () {
      final schema = Ack.duration();
      final int? encoded = schema.encode(const Duration(milliseconds: 500));
      expect(encoded, 500);
    });

    test('Ack.duration parse is statically typed as Duration', () {
      final schema = Ack.duration();
      final Duration? parsed = schema.parse(1500);
      expect(parsed, const Duration(milliseconds: 1500));
    });

    test('Ack.uri round-trips', () {
      final schema = Ack.uri();
      final Uri? parsed = schema.parse('https://example.com/x');
      expect(parsed, Uri.parse('https://example.com/x'));
      final String? encoded = schema.encode(parsed);
      expect(encoded, 'https://example.com/x');
    });
  });

  group('Nested list codec encode', () {
    test('Ack.list(Ack.date()) encode is List<String>', () {
      final schema = Ack.list(Ack.date());
      final List<String>? encoded = schema.encode([DateTime(2026, 5, 10)]);
      expect(encoded, ['2026-05-10']);
    });

    test('Ack.list(Ack.duration()) encode is List<int>', () {
      final schema = Ack.list(Ack.duration());
      final List<int>? encoded = schema.encode([
        const Duration(milliseconds: 1),
        const Duration(milliseconds: 2),
      ]);
      expect(encoded, [1, 2]);
    });
  });

  group('Object model mapping', () {
    test('ObjectSchema.model parses model and encodes JsonMap', () {
      final schema = Ack.object({'createdAt': Ack.datetime()}).model<_Event>(
        decode: (data) => _Event(data['createdAt'] as DateTime),
        encode: (event) => {'createdAt': event.createdAt},
      );

      final _Event? parsed = schema.parse({
        'createdAt': '2026-05-10T00:00:00.000Z',
      });
      expect(parsed, isNotNull);
      expect(parsed!.createdAt, DateTime.utc(2026, 5, 10));

      final JsonMap? encoded = schema.encode(parsed);
      expect(encoded, {'createdAt': '2026-05-10T00:00:00.000Z'});
    });

    test('model encoder injects missing defaulted property', () {
      final schema =
          Ack.object({
            'name': Ack.string(),
            'role': Ack.string().withDefault('user'),
          }).model<_User>(
            decode: (data) => _User(data['name'] as String),
            encode: (user) => {'name': user.name},
          );

      final result = schema.safeEncode(_User('Ada'));

      expect(result.isOk, true);
      expect(result.getOrNull(), {'name': 'Ada', 'role': 'user'});
    });
  });

  group('Generic codec combinator', () {
    test('schema.codec creates typed bidirectional schema', () {
      final schema = Ack.string().codec<int>(
        decode: int.parse,
        encode: (value) => value.toString(),
      );

      final int? parsed = schema.parse('42');
      final String? encoded = schema.encode(42);
      expect(parsed, 42);
      expect(encoded, '42');
    });

    test(
      'CodecSchema.create supports distinct boundary, input, and runtime',
      () {
        final schema = CodecSchema.create<String, DateTime, int>(
          inputSchema: Ack.date(),
          outputSchema: Ack.integer(),
          decoder: (date) => date.year,
          encoder: (year) => DateTime(year),
        );

        final int? parsed = schema.parse('2026-05-10');
        final String? encoded = schema.encode(2026);

        expect(parsed, 2026);
        expect(encoded, '2026-01-01');
      },
    );

    test('decoder exceptions use codec decode wording', () {
      final transformSchema = Ack.string().transform<int>(
        (_) => throw StateError('transform decoder failed'),
      );
      final transformResult = transformSchema.safeParse('value');

      expect(transformResult.isFail, true);
      final transformError = transformResult.getError();
      expect(transformError, isA<SchemaTransformError>());
      expect(transformError.message, startsWith('Codec decode failed:'));

      final codecSchema = Ack.string().codec<int>(
        decode: (_) => throw StateError('codec decoder failed'),
        encode: (value) => value.toString(),
      );
      final codecResult = codecSchema.safeParse('value');

      expect(codecResult.isFail, true);
      final codecError = codecResult.getError();
      expect(codecError, isA<SchemaTransformError>());
      expect(codecError.message, startsWith('Codec decode failed:'));
    });
  });

  group('Enum schema with String boundary', () {
    test('Parses .name and encodes back', () {
      final schema = Ack.enumValues(_Role.values);
      final _Role? parsed = schema.parse('admin');
      expect(parsed, _Role.admin);
      final String? encoded = schema.encode(_Role.admin);
      expect(encoded, 'admin');
    });
  });

  group('DefaultSchema wrapper', () {
    test('parse(null) returns runtime default', () {
      final schema = Ack.string().withDefault('fallback');
      final String? parsed = schema.parse(null);
      expect(parsed, 'fallback');
    });

    test('encode(null) does NOT inject default', () {
      final schema = Ack.string().nullable().withDefault('fallback');
      final String? encoded = schema.encode(null);
      expect(encoded, isNull);
    });

    test('parse with explicit value bypasses default', () {
      final schema = Ack.integer().withDefault(0);
      expect(schema.parse(5), 5);
    });

    test(
      'withConstraint after default preserves existing inner constraints',
      () {
        final schema = Ack.string()
            .minLength(3)
            .withDefault('abcd')
            .withConstraint(_StartsWithConstraint('a'));

        expect(
          schema.safeParse('ab').isFail,
          true,
          reason: 'minLength from the inner schema should still run',
        );
        expect(
          schema.safeParse('bcd').isFail,
          true,
          reason: 'new constraints added after withDefault should run',
        );
        expect(schema.safeParse('abcd').isOk, true);
      },
    );

    test('refine after default preserves existing inner refinements', () {
      final schema = Ack.string()
          .refine((value) => value.length >= 3, message: 'too short')
          .withDefault('abcd')
          .refine((value) => value.startsWith('a'), message: 'bad prefix');

      expect(
        schema.safeParse('ab').isFail,
        true,
        reason: 'inner refinements should still run',
      );
      expect(
        schema.safeParse('bcd').isFail,
        true,
        reason: 'new refinements added after withDefault should run',
      );
      expect(schema.safeParse('abcd').isOk, true);
    });
  });

  group('One-way transforms use CodecSchema', () {
    test('transform returns CodecSchema', () {
      final schema = Ack.string().transform<int>(int.parse);
      expect(schema, isA<CodecSchema<String, int>>());
    });

    test('parse works via transformer', () {
      final schema = Ack.string().transform<int>(int.parse);
      expect(schema.parse('123'), 123);
    });

    test('encode fails with oneWayTransform error', () {
      final schema = Ack.string().transform<int>(int.parse);
      final result = schema.safeEncode(123);
      expect(result.isFail, true);
      final error = result.getError();
      expect(error, isA<SchemaEncodeError>());
      expect(
        (error as SchemaEncodeError).kind,
        SchemaEncodeFailureKind.oneWayTransform,
      );
    });
  });

  group('WrapperSchema smoke checks', () {
    test('defaults, codecs, and one-way transforms are wrappers', () {
      expect(Ack.string().withDefault('x'), isA<WrapperSchema>());
      expect(Ack.string().transform<int>(int.parse), isA<WrapperSchema>());
      expect(Ack.date(), isA<WrapperSchema>());
    });

    test('default wrapper composes inner nullable flag', () {
      final schema = Ack.string().nullable().withDefault('');
      expect(schema.isNullable, true);
    });

    test('built-in codec exposes typed copyWith', () {
      final schema = Ack.date().copyWith(description: 'd');
      expect(schema.description, 'd');
    });

    test('wrapper fluent calls preserve concrete return types', () {
      final CodecSchema<String, DateTime> nullableCodec = Ack.date().nullable();
      final CodecSchema<String, int> refinedTransform = Ack.string()
          .transform<int>(int.parse)
          .refine((value) => value > 0, message: 'positive');
      final DefaultSchema<String, String> constrainedDefault = Ack.string()
          .withDefault('abcd')
          .withConstraint(_StartsWithConstraint('a'));

      expect(nullableCodec.isNullable, true);
      expect(refinedTransform.safeParse('-1').isFail, true);
      expect(constrainedDefault.safeParse('bcd').isFail, true);
    });

    test('wrapper JSON Schema includes wrapper-owned metadata', () {
      final codecJson = Ack.date()
          .describe('Local date')
          .nullable()
          .toJsonSchema();
      expect(codecJson['description'], 'Local date');
      expect((codecJson['anyOf'] as List).last, {'type': 'null'});

      final defaultJson = Ack.string()
          .withDefault('fallback')
          .describe('Display name')
          .nullable()
          .toJsonSchema();
      expect(defaultJson['description'], 'Display name');
      expect(defaultJson['default'], 'fallback');
      expect((defaultJson['anyOf'] as List).last, {'type': 'null'});
    });

    test('nullable wrapper reuses inner nullable JSON Schema branch', () {
      final json = Ack.string()
          .nullable()
          .withDefault('fallback')
          .describe('Display name')
          .toJsonSchema();

      expect(json['description'], 'Display name');
      expect(json['default'], 'fallback');
      expect(json['anyOf'], isA<List>());
      expect(json['anyOf'], hasLength(2));
      expect((json['anyOf'] as List).last, {'type': 'null'});
    });
  });

  group('Object encode validations', () {
    test('Missing required property fails encode', () {
      final schema = Ack.object({'name': Ack.string(), 'age': Ack.integer()});
      final result = schema.safeEncode({'name': 'x'});
      expect(result.isFail, true);
    });

    test('Unexpected property fails encode', () {
      final schema = Ack.object({'name': Ack.string()});
      final result = schema.safeEncode({'name': 'x', 'extra': 'y'});
      expect(result.isFail, true);
    });

    test('additionalProperties: true allows extras on encode', () {
      final schema = Ack.object({
        'name': Ack.string(),
      }, additionalProperties: true);
      final result = schema.safeEncode({'name': 'x', 'extra': 'y'});
      expect(result.isOk, true);
      expect(result.getOrNull(), {'name': 'x', 'extra': 'y'});
    });

    test('Missing defaulted property is injected on encode', () {
      final schema = Ack.object({'role': Ack.string().withDefault('user')});

      final result = schema.safeEncode({});

      expect(result.isOk, true);
      expect(result.getOrNull(), {'role': 'user'});
    });
  });

  group('SchemaContext.operation', () {
    test('parse path observes SchemaOperation.parse', () {
      final parseOperations = <SchemaOperation>[];
      final validateOperations = <SchemaOperation>[];
      final schema = _OperationRecordingSchema(
        parseOperations: parseOperations,
        validateOperations: validateOperations,
        encodeOperations: [],
      );

      schema.parse('x');

      expect(parseOperations, [SchemaOperation.parse]);
      expect(validateOperations, [SchemaOperation.parse]);
    });

    test('encode path observes SchemaOperation.encode', () {
      final validateOperations = <SchemaOperation>[];
      final encodeOperations = <SchemaOperation>[];
      final schema = _OperationRecordingSchema(
        parseOperations: [],
        validateOperations: validateOperations,
        encodeOperations: encodeOperations,
      );

      schema.encode('x');

      expect(encodeOperations, [SchemaOperation.encode]);
      expect(validateOperations, [SchemaOperation.encode]);
    });
  });
}
