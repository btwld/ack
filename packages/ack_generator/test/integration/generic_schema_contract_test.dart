import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

const _head = r'''
import 'package:ack/ack.dart';
part 'models.g.dart';
''';

Future<void> _build(
  String source, {
  Matcher? output,
  List<String> errors = const [],
}) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  final actualErrors = <String>[];
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {'test_pkg|lib/models.dart': '$_head\n$source'},
    generateFor: const {'test_pkg|lib/models.dart'},
    readerWriter: readerWriter,
    outputs: output == null
        ? const {}
        : {'test_pkg|lib/models.g.dart': decodedMatches(output)},
    onLog: (log) {
      if (log.level.name == 'SEVERE') actualErrors.add(log.message);
    },
  );
  for (final error in errors) {
    expect(actualErrors, contains(contains(error)));
  }
}

const _box = r'''
final class Box<T> {
  const Box(this.value);
  final T value;
}
AckSchema<String, Box<String>> boxSchema() => Ack.string().codec<Box<String>>(
  decode: Box<String>.new, encode: (box) => box.value,
);
AckSchema<String, Box<String?>> nullableBoxSchema() =>
    Ack.string().codec<Box<String?>>(
      decode: Box<String?>.new, encode: (box) => box.value!,
    );
''';

const _bounded = r'''
final class Bounded<T> {
  const Bounded(this.value);
  final T value;
  static AckSchema<String, Bounded<U>> schema<U extends Comparable<U>>() =>
      Ack.string().codec<Bounded<U>>(
        decode: (value) => Bounded<U>(value as U),
        encode: (bounded) => bounded.value.toString(),
      );
}
''';

void main() {
  test(
    'does not register nullable application arguments for nonnullable fields',
    () async {
      await _build(
        '''
final class Box<T> {
  const Box(this.value);
  final T value;
}
AckSchema<String, Box<String?>> nullableBoxSchema() =>
    Ack.string().codec<Box<String?>>(
      decode: Box<String?>.new, encode: (box) => box.value!,
    );
@Schemable(schemas: [nullableBoxSchema])
final class Holder with _\$HolderAck {
  const Holder({required this.box});
  final Box<String> box;
}
''',
        errors: ['Holder.box', 'unsupported Box<String>'],
      );
    },
  );

  test(
    'distinguishes registrations by application argument nullability',
    () async {
      await _build(
        '''
$_box
@Schemable(schemas: [boxSchema, nullableBoxSchema])
final class Holder with _\$HolderAck {
  const Holder({required this.box, required this.nullableBox});
  final Box<String> box;
  final Box<String?> nullableBox;
}
''',
        output: allOf([
          contains("'box': boxSchema()"),
          contains("'nullableBox': nullableBoxSchema()"),
        ]),
      );
    },
  );

  test(
    'rejects a type-owned schema with different argument nullability',
    () async {
      await _build(
        r'''
final class Box<T> {
  const Box(this.value);
  final T value;
  static AckSchema<String, Box<U?>> schema<U>() => Ack.string().codec<Box<U?>>(
    decode: (value) => Box<U?>(value as U?),
    encode: (box) => box.value.toString(),
  );
}
@Schemable()
final class Holder with _$HolderAck {
  const Holder({required this.box});
  final Box<String> box;
}
''',
        errors: [
          'Holder.box',
          'produces Box<String?>',
          'field type is Box<String>',
        ],
      );
    },
  );

  test('substitutes nested F-bounds for valid type-owned schemas', () async {
    await _build('''
$_bounded
@Schemable()
final class Holder with _\$HolderAck {
  const Holder({required this.box});
  final Bounded<String> box;
}
''', output: contains('Bounded.schema<String>()'));
  });

  test('reports the substituted bound for invalid type arguments', () async {
    await _build(
      '''
$_bounded
@Schemable()
final class Holder with _\$HolderAck {
  const Holder({required this.box});
  final Bounded<Object?> box;
}
''',
      errors: ['Holder.box', 'Comparable<Object?>', 'received Object?'],
    );
  });
}
