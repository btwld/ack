import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

Future<void> _expectGenerationFailure({
  required Builder builder,
  required Map<String, String> assets,
  required String expectedMessage,
  Map<String, Object>? expectedOutputs,
}) async {
  var sawExpectedError = false;
  await testBuilder(
    builder,
    assets,
    outputs: expectedOutputs ?? {},
    onLog: (log) {
      if (log.level.name == 'SEVERE' && log.message.contains(expectedMessage)) {
        sawExpectedError = true;
      }
    },
  );
  expect(
    sawExpectedError,
    isTrue,
    reason: 'Expected SEVERE log containing "$expectedMessage"',
  );
}

void main() {
  group('@AckType discriminated schemas', () {
    test('generates discriminated base and subtype extension types', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final catSchema = Ack.object({
  'kind': Ack.literal('cat'),
  'lives': Ack.integer(),
});

@AckType()
ObjectSchema get dogSchema => Ack.object({
  'kind': Ack.literal('dog'),
  'bark': Ack.boolean(),
}).passthrough();

@AckType()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {
    'cat': catSchema,
    'dog': dogSchema,
  },
);
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('extension type PetType(Map<String, Object?> _data)'),
              contains('implements Map<String, Object?>'),
              contains("switch (map['kind'])"),
              contains("'cat' => CatType(map)"),
              contains("'dog' => DogType(map)"),
              contains('extension type CatType(Map<String, Object?> _data)'),
              contains('extension type DogType(Map<String, Object?> _data)'),
              contains('implements PetType, Map<String, Object?>'),
              contains('return catSchema.parseRepresentationAs('),
              contains('return catSchema.safeParseRepresentationAs('),
              contains('return dogSchema.parseRepresentationAs('),
              contains('return dogSchema.safeParseRepresentationAs('),
              contains('CatType copyWith({int? lives})'),
              contains('DogType copyWith({bool? bark})'),
              contains("'kind': 'cat'"),
              contains("'kind': 'dog'"),
              contains('Map<String, Object?> get args =>'),
              predicate((content) {
                final source = content as String;
                final count = RegExp(
                  r"String get kind => _data\['kind'\] as String;",
                ).allMatches(source).length;
                return count == 3;
              }, 'contains one kind getter per generated type'),
            ]),
          ),
        },
      );
    });

    test(
      'generates representation-first getters and copyWith for transformed branches',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final catSchema = Ack.object({
  'kind': Ack.literal('cat'),
  'homepage': Ack.uri(),
});

@AckType()
final dogSchema = Ack.object({
  'kind': Ack.literal('dog'),
  'timeout': Ack.duration(),
});

@AckType()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {
    'cat': catSchema,
    'dog': dogSchema,
  },
);
''',
          },
          outputs: {
            'test_pkg|lib/schema.g.dart': decodedMatches(
              allOf([
                contains(
                  'String get homepage => _data[\'homepage\'] as String',
                ),
                contains('Uri get homepageParsed'),
                contains('int get timeout => _data[\'timeout\'] as int'),
                contains('Duration get timeoutParsed'),
                contains('CatType copyWith({String? homepage})'),
                contains('DogType copyWith({int? timeout})'),
              ]),
            ),
          },
        );
      },
    );

    test('fails when a branch is an inline expression', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await _expectGenerationFailure(
        builder: builder,
        expectedMessage: 'must reference a top-level schema variable/getter',
        assets: {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {
    'cat': Ack.object({
      'kind': Ack.literal('cat'),
      'lives': Ack.integer(),
    }),
  },
);
''',
        },
      );
    });

    test('fails when a branch lacks @AckType', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await _expectGenerationFailure(
        builder: builder,
        expectedMessage: 'must be annotated with @AckType',
        assets: {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

final catSchema = Ack.object({
  'kind': Ack.literal('cat'),
  'lives': Ack.integer(),
});

@AckType()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {
    'cat': catSchema,
  },
);
''',
        },
      );
    });

    test('fails when a branch schema is not object-shaped', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await _expectGenerationFailure(
        builder: builder,
        expectedMessage: 'must be an object schema',
        assets: {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final catSchema = Ack.string();

@AckType()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {
    'cat': catSchema,
  },
);
''',
        },
      );
    });

    test('fails when a branch comes from another library', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await _expectGenerationFailure(
        builder: builder,
        expectedMessage: 'must be declared in the same library',
        expectedOutputs: {'test_pkg|lib/branches.g.dart': anything},
        assets: {
          ...allAssets,
          'test_pkg|lib/branches.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final catSchema = Ack.object({
  'kind': Ack.literal('cat'),
  'lives': Ack.integer(),
});
''',
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'branches.dart';

@AckType()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {
    'cat': catSchema,
  },
);
''',
        },
      );
    });

    test('fails when discriminated base is nullable', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await _expectGenerationFailure(
        builder: builder,
        expectedMessage: 'cannot be nullable when used with @AckType',
        assets: {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final catSchema = Ack.object({
  'kind': Ack.literal('cat'),
  'lives': Ack.integer(),
});

@AckType()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {
    'cat': catSchema,
  },
).nullable();
''',
        },
      );
    });

    test('fails when schemas map is empty', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await _expectGenerationFailure(
        builder: builder,
        expectedMessage: 'must contain at least one branch',
        assets: {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {},
);
''',
        },
      );
    });

    test('fails when a branch schema is nullable', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await _expectGenerationFailure(
        builder: builder,
        expectedMessage: 'cannot be nullable',
        assets: {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final catSchema = Ack.object({
  'kind': Ack.literal('cat'),
  'lives': Ack.integer(),
}).nullable();

@AckType()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {
    'cat': catSchema,
  },
);
''',
        },
      );
    });

    test('fails when discriminator values are duplicated', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await _expectGenerationFailure(
        builder: builder,
        expectedMessage: 'duplicate discriminator value',
        assets: {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final catSchema = Ack.object({
  'kind': Ack.literal('cat'),
  'lives': Ack.integer(),
});

@AckType()
final dogSchema = Ack.object({
  'kind': Ack.literal('dog'),
  'bark': Ack.boolean(),
});

@AckType()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {
    'cat': catSchema,
    'cat': dogSchema,
  },
);
''',
        },
      );
    });

    test(
      'fails when branch map key mismatches discriminator literal',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await _expectGenerationFailure(
          builder: builder,
          expectedMessage: 'but is mapped as',
          assets: {
            ...allAssets,
            'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final catSchema = Ack.object({
  'kind': Ack.literal('cat'),
  'lives': Ack.integer(),
});

@AckType()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {
    'cat': catSchema,
    'kitty': catSchema,
  },
);
''',
          },
        );
      },
    );

    test(
      'fails when schemas key does not match branch discriminator literal',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await _expectGenerationFailure(
          builder: builder,
          expectedMessage: 'but is mapped as',
          assets: {
            ...allAssets,
            'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final dogSchema = Ack.object({
  'kind': Ack.literal('dog'),
  'bark': Ack.boolean(),
});

@AckType()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {
    'cat': dogSchema,
  },
);
''',
          },
        );
      },
    );

    test('fails when a branch is reused across multiple bases', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await _expectGenerationFailure(
        builder: builder,
        expectedMessage: 'mapped to multiple discriminated bases',
        assets: {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final catSchema = Ack.object({
  'kind': Ack.literal('cat'),
  'lives': Ack.integer(),
});

@AckType()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {
    'cat': catSchema,
  },
);

@AckType()
final anotherPetSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {
    'cat': catSchema,
  },
);
''',
        },
      );
    });

    test('fails when aliased branch is reused across multiple bases', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await _expectGenerationFailure(
        builder: builder,
        expectedMessage: 'mapped to multiple discriminated bases',
        assets: {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final catSchema = Ack.object({
  'kind': Ack.literal('cat'),
  'lives': Ack.integer(),
});

@AckType()
final catAliasOne = catSchema;

@AckType()
final catAliasTwo = catSchema;

@AckType()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {
    'cat': catAliasOne,
  },
);

@AckType()
final anotherPetSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {
    'cat': catAliasTwo,
  },
);
''',
        },
      );
    });

    test('fails when a branch is itself a discriminated base', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await _expectGenerationFailure(
        builder: builder,
        expectedMessage: 'Nested discriminated unions are not supported',
        assets: {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final catSchema = Ack.object({
  'kind': Ack.literal('cat'),
  'lives': Ack.integer(),
});

@AckType()
final innerSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {
    'cat': catSchema,
  },
);

@AckType()
final outerSchema = Ack.discriminated(
  discriminatorKey: 'type',
  schemas: {
    'inner': innerSchema,
  },
);
''',
        },
      );
    });
  });
}
