import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

Future<void> _build(
  Builder builder,
  String source, {
  required Map<String, Object> outputs,
  void Function(LogRecord log)? onLog,
  Map<String, String> supportingSources = const {},
}) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  await testBuilder(
    builder,
    {
      'test_pkg|lib/models.dart': source,
      for (final entry in supportingSources.entries)
        'test_pkg|lib/${entry.key}': entry.value,
    },
    generateFor: const {'test_pkg|lib/models.dart'},
    readerWriter: readerWriter,
    outputs: outputs,
    onLog: onLog,
  );
}

const _parts = """
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part 'models.g.dart';
part 'models.ack.dart';
part 'models.ack.g.dart';
""";

void main() {
  test(
    'unrelated legacy and modern declarations coexist in one library',
    () async {
      const source =
          """
$_parts
@AckType()
final legacySchema = Ack.object({'id': Ack.string()});

@Schemable()
final modernSchema = Ack.object({'name': Ack.string()});
""";

      await _build(
        ackGenerator(BuilderOptions.empty),
        source,
        outputs: {
          'test_pkg|lib/models.g.dart': decodedMatches(
            contains('extension type LegacyType('),
          ),
        },
      );
      await _build(
        ackModelBuilder(BuilderOptions.empty),
        source,
        outputs: {
          'test_pkg|lib/models.ack.dart': decodedMatches(
            contains('final class Modern'),
          ),
        },
      );
    },
  );

  test('modern generators reject a class and facade name collision', () async {
    var sawDiagnostic = false;
    await _build(
      ackModelBuilder(BuilderOptions.empty),
      '''
$_parts
@Schemable(name: 'AddressSchema')
final valueSchema = Ack.string();

@Schemable()
final class Address with _\$AddressAck {
  const Address({required this.city});

  final String city;
}
''',
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE' &&
            log.message.contains('AddressSchema') &&
            log.message.contains('schema-first class') &&
            log.message.contains('class-first facade')) {
          sawDiagnostic = true;
        }
      },
    );
    expect(sawDiagnostic, isTrue);
  });

  for (final entry in {
    'List': 'List<Address?>',
    'Set': 'Set<Address?>',
    'nested List': 'List<List<Address?>>',
  }.entries) {
    test('class-first models reject nullable future-generated elements in '
        '${entry.key}', () async {
      var sawLocatedDiagnostic = false;
      await _build(
        ackModelBuilder(BuilderOptions.empty),
        '''
$_parts
@Schemable()
final addressSchema = Ack.object({'city': Ack.string()});

@Schemable()
final class User with _\$UserAck {
  const User({required this.addresses});

  final ${entry.value} addresses;
}
''',
        outputs: const {},
        onLog: (log) {
          if (log.level.name == 'SEVERE' &&
              log.message.contains('User.addresses') &&
              log.message.contains('nullable collection elements') &&
              log.message.contains('Ack.list')) {
            sawLocatedDiagnostic = true;
          }
        },
      );
      expect(sawLocatedDiagnostic, isTrue);
    });
  }

  test(
    'class-first models explain an unsupported future-generated Map value',
    () async {
      final errors = <String>[];
      await _build(
        ackModelBuilder(BuilderOptions.empty),
        '''
$_parts
@Schemable()
final tagSchema = Ack.object({'label': Ack.string()});

@Schemable()
final class Board with _\$BoardAck {
  const Board({required this.tags, required this.list});

  final Map<String, Tag> tags;
  final List<Tag> list;
}
''',
        outputs: const {},
        onLog: (log) {
          if (log.level.name == 'SEVERE') errors.add(log.message);
        },
      );
      expect(
        errors,
        contains(
          contains(
            'Board.tags uses Map<String, Tag>. A model generated from a '
            '@Schemable schema in this build can be a field type directly or a '
            'List or Set item, but not a Map value.',
          ),
        ),
      );
      expect(errors, everyElement(isNot(contains('InvalidType'))));
    },
  );

  test('class-first models report an unresolvable field type', () async {
    final errors = <String>[];
    await _build(
      ackModelBuilder(BuilderOptions.empty),
      '''
$_parts
@Schemable()
final class Board with _\$BoardAck {
  const Board({required this.owner});

  final Missing owner;
}
''',
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE') errors.add(log.message);
      },
    );
    expect(
      errors,
      contains(
        contains(
          'Board.owner uses Missing, which does not resolve. Check that it is '
          'imported.',
        ),
      ),
    );
  });

  test('class-first models allow a direct nullable future-generated model', () {
    return _build(
      ackModelBuilder(BuilderOptions.empty),
      '''
$_parts
@Schemable()
final addressSchema = Ack.object({'city': Ack.string()});

@Schemable()
final class User with _\$UserAck {
  const User({this.address});

  final Address? address;
}
''',
      outputs: {
        'test_pkg|lib/models.ack.dart': decodedMatches(
          allOf([
            contains(r'Address.$ack.schema.optional().nullable()'),
            contains('address as Address?'),
          ]),
        ),
      },
    );
  });

  test(
    'AckField schema overrides nullable future-generated collection inference',
    () {
      return _build(
        ackModelBuilder(BuilderOptions.empty),
        '''
$_parts
AckSchema<Object?, List<Address?>> addressListSchema() =>
    Ack.any().nullable().codec<List<Address?>>(
      decode: (value) => value as List<Address?>,
      encode: (value) => value,
    );

@Schemable()
final addressSchema = Ack.object({'city': Ack.string()});

@Schemable()
final class User with _\$UserAck {
  const User({required this.addresses});

  @AckField(schema: addressListSchema)
  final List<Address?> addresses;
}
''',
        outputs: {
          'test_pkg|lib/models.ack.dart': decodedMatches(
            contains('addressListSchema()'),
          ),
        },
      );
    },
  );

  test(
    'class-first models resolve a future schema-first model through a barrel',
    () {
      return _build(
        ackModelBuilder(BuilderOptions.empty),
        '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';
import 'exports.dart';

part 'models.ack.dart';
part 'models.ack.g.dart';

@Schemable()
final class User with _\$UserAck {
  const User({required this.address});

  final Address address;
}
''',
        supportingSources: {
          'address.dart': '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part 'address.ack.dart';
part 'address.ack.g.dart';

@Schemable()
final addressSchema = Ack.object({'city': Ack.string()});
''',
          'exports.dart': "export 'address.dart' show addressSchema, Address;",
        },
        outputs: {
          'test_pkg|lib/models.ack.dart': decodedMatches(
            allOf([
              contains(r'Address.$ack.schema'),
              contains(r'Address.$ack.fromRuntime'),
            ]),
          ),
          'test_pkg|lib/address.ack.dart': anything,
        },
      );
    },
  );

  test(
    'class-first models reject a future schema-first class hidden by a barrel',
    () async {
      var sawLocatedDiagnostic = false;
      await _build(
        ackModelBuilder(BuilderOptions.empty),
        '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';
import 'exports.dart';

part 'models.ack.dart';
part 'models.ack.g.dart';

@Schemable()
final class User with _\$UserAck {
  const User({required this.address});

  final Address address;
}
''',
        supportingSources: {
          'address.dart': '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part 'address.ack.dart';
part 'address.ack.g.dart';

@Schemable()
final addressSchema = Ack.object({'city': Ack.string()});
''',
          'exports.dart': "export 'address.dart' show addressSchema;",
        },
        outputs: {'test_pkg|lib/address.ack.dart': anything},
        onLog: (log) {
          if (log.level.name == 'SEVERE' &&
              log.message.contains('User.address') &&
              log.message.contains('Address') &&
              log.message.contains('export combinator')) {
            sawLocatedDiagnostic = true;
          }
        },
      );
      expect(sawLocatedDiagnostic, isTrue);
    },
  );

  test('modern schemas reject a nested legacy reference graph', () async {
    var sawDiagnostic = false;
    await _build(
      ackModelBuilder(BuilderOptions.empty),
      """
$_parts
@AckType()
final addressSchema = Ack.object({'city': Ack.string()});

@Schemable()
final userSchema = Ack.object({'address': addressSchema});
""",
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE' &&
            log.message.contains('userSchema.address') &&
            log.message.contains('migrate this connected graph together')) {
          sawDiagnostic = true;
        }
      },
    );
    expect(sawDiagnostic, isTrue);
  });

  test('legacy schemas reject a nested modern reference graph', () async {
    var sawDiagnostic = false;
    await _build(
      ackGenerator(BuilderOptions.empty),
      """
$_parts
@Schemable()
final addressSchema = Ack.object({'city': Ack.string()});

@AckType()
final userSchema = Ack.object({'address': addressSchema});
""",
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE' &&
            log.message.contains('userSchema.address') &&
            log.message.contains('migrate this connected graph together')) {
          sawDiagnostic = true;
        }
      },
    );
    expect(sawDiagnostic, isTrue);
  });

  test('class-first models reject a nested legacy generated type', () async {
    var sawDiagnostic = false;
    await _build(
      ackModelBuilder(BuilderOptions.empty),
      """
$_parts
@AckType()
final addressSchema = Ack.object({'city': Ack.string()});

@Schemable()
final class User with _\$UserAck {
  const User({required this.addresses});

  final List<AddressType> addresses;
}
""",
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE' &&
            log.message.contains('User.addresses') &&
            log.message.contains('migrate this connected graph together')) {
          sawDiagnostic = true;
        }
      },
    );
    expect(sawDiagnostic, isTrue);
  });

  test('class-first models reject a scalar legacy generated type', () async {
    var sawDiagnostic = false;
    await _build(
      ackModelBuilder(BuilderOptions.empty),
      """
$_parts
@AckType()
final addressSchema = Ack.object({'city': Ack.string()});

@Schemable()
final class User with _\$UserAck {
  const User({required this.address});

  final AddressType address;
}
""",
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE' &&
            log.message.contains('User.address') &&
            log.message.contains('migrate this connected graph together')) {
          sawDiagnostic = true;
        }
      },
    );
    expect(sawDiagnostic, isTrue);
  });

  test('class-first models reject a resolved legacy generated type', () async {
    const source =
        """
$_parts
@AckType()
final addressSchema = Ack.object({'city': Ack.string()});

@Schemable()
final class User with _\$UserAck {
  const User({required this.addresses});

  final List<AddressType> addresses;
}
""";
    final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
    await readerWriter.testing.loadIsolateSources();
    await testBuilder(
      ackGenerator(BuilderOptions.empty),
      {'test_pkg|lib/models.dart': source},
      generateFor: const {'test_pkg|lib/models.dart'},
      readerWriter: readerWriter,
      outputs: {
        'test_pkg|lib/models.g.dart': decodedMatches(
          contains('extension type AddressType('),
        ),
      },
    );
    final generatedAsset = readerWriter.testing.assets.singleWhere(
      (asset) => asset.path.endsWith('/models.g.dart'),
    );
    final generatedSource = readerWriter.testing.readString(generatedAsset);
    final resolvedReaderWriter = TestReaderWriter(rootPackage: 'test_pkg');
    await resolvedReaderWriter.testing.loadIsolateSources();

    var sawDiagnostic = false;
    await testBuilder(
      ackModelBuilder(BuilderOptions.empty),
      {
        'test_pkg|lib/models.dart': source,
        'test_pkg|lib/models.g.dart': generatedSource,
      },
      generateFor: const {'test_pkg|lib/models.dart'},
      readerWriter: resolvedReaderWriter,
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE' &&
            log.message.contains('User.addresses') &&
            log.message.contains('migrate this connected graph together')) {
          sawDiagnostic = true;
        }
      },
    );
    expect(sawDiagnostic, isTrue);
  });

  test('class-first models reject a resolved scalar legacy type', () async {
    const source =
        """
$_parts
@AckType()
final addressSchema = Ack.object({'city': Ack.string()});

@Schemable()
final class User with _\$UserAck {
  const User({required this.address});

  final AddressType address;
}
""";
    final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
    await readerWriter.testing.loadIsolateSources();
    await testBuilder(
      ackGenerator(BuilderOptions.empty),
      {'test_pkg|lib/models.dart': source},
      generateFor: const {'test_pkg|lib/models.dart'},
      readerWriter: readerWriter,
      outputs: {
        'test_pkg|lib/models.g.dart': decodedMatches(
          contains('extension type AddressType('),
        ),
      },
    );
    final generatedAsset = readerWriter.testing.assets.singleWhere(
      (asset) => asset.path.endsWith('/models.g.dart'),
    );
    final generatedSource = readerWriter.testing.readString(generatedAsset);
    final resolvedReaderWriter = TestReaderWriter(rootPackage: 'test_pkg');
    await resolvedReaderWriter.testing.loadIsolateSources();

    var sawDiagnostic = false;
    await testBuilder(
      ackModelBuilder(BuilderOptions.empty),
      {
        'test_pkg|lib/models.dart': source,
        'test_pkg|lib/models.g.dart': generatedSource,
      },
      generateFor: const {'test_pkg|lib/models.dart'},
      readerWriter: resolvedReaderWriter,
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE' &&
            log.message.contains('User.address') &&
            log.message.contains('migrate this connected graph together')) {
          sawDiagnostic = true;
        }
      },
    );
    expect(sawDiagnostic, isTrue);
  });

  test('legacy schemas reject a nested class-first facade', () async {
    var sawDiagnostic = false;
    await _build(
      ackGenerator(BuilderOptions.empty),
      """
$_parts
@Schemable()
final class Address with _\$AddressAck {
  const Address({required this.city});

  final String city;
}

@AckType()
final userSchema = Ack.object({
  'addresses': Ack.list(AddressSchema.schema),
});
""",
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE' &&
            log.message.contains('userSchema.addresses') &&
            log.message.contains('migrate this connected graph together')) {
          sawDiagnostic = true;
        }
      },
    );
    expect(sawDiagnostic, isTrue);
  });

  for (final entry in {
    'scalar': 'AddressSchema.schema',
    'parenthesized': '(AddressSchema.schema)',
    'postfix non-null assertion': 'AddressSchema.schema!',
  }.entries) {
    test(
      'legacy schemas reject ${entry.key} class-first facade references',
      () async {
        var sawDiagnostic = false;
        await _build(
          ackGenerator(BuilderOptions.empty),
          '''
$_parts
@Schemable()
final class Address with _\$AddressAck {
  const Address({required this.city});

  final String city;
}

@AckType()
final userSchema = Ack.object({'address': ${entry.value}});
''',
          outputs: const {},
          onLog: (log) {
            if (log.level.name == 'SEVERE' &&
                log.message.contains('userSchema.address') &&
                log.message.contains('migrate this connected graph together')) {
              sawDiagnostic = true;
            }
          },
        );
        expect(sawDiagnostic, isTrue);
      },
    );
  }

  test('legacy schemas reject class-first facades through barrels', () async {
    var sawDiagnostic = false;
    await _build(
      ackGenerator(BuilderOptions.empty),
      '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';
import 'address_models.dart';

part 'models.g.dart';
part 'models.ack.dart';
part 'models.ack.g.dart';

@AckType()
final userSchema = Ack.object({'address': AddressSchema.schema});
''',
      supportingSources: const {
        'address_models.dart': "export 'address.dart';\n",
        'address.dart': '''
import 'package:ack/annotations.dart';

@Schemable()
final class Address {
  const Address({required this.city});

  final String city;
}
''',
      },
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE' &&
            log.message.contains('userSchema.address') &&
            log.message.contains('migrate this connected graph together')) {
          sawDiagnostic = true;
        }
      },
    );
    expect(sawDiagnostic, isTrue);
  });

  test(
    'legacy schemas reject an unparsed field instead of dropping it',
    () async {
      var sawDiagnostic = false;
      await _build(
        ackGenerator(BuilderOptions.empty),
        '''
$_parts
@AckType()
final userSchema = Ack.object({'name': (Ack.string())});
''',
        outputs: const {},
        onLog: (log) {
          if (log.level.name == 'SEVERE' &&
              log.message.contains('userSchema.name') &&
              log.message.contains('unsupported schema expression')) {
            sawDiagnostic = true;
          }
        },
      );
      expect(sawDiagnostic, isTrue);
    },
  );
}
