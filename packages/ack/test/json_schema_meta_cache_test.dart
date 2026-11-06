import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  test('repeated small imports amortize fixed meta-schema indexing', () {
    final reference = Ack.object({
      for (var i = 0; i < 100; i++) 'p$i': Ack.integer(),
    });
    final ratios = <double>[];
    for (var sample = 0; sample < 5; sample++) {
      final compile = Stopwatch();
      final export = Stopwatch();
      for (var i = 0; i < 500; i++) {
        compile.start();
        Ack.fromJsonSchema({'type': 'string'});
        compile.stop();
        export.start();
        reference.toJsonSchema();
        export.stop();
      }
      ratios.add(compile.elapsedMicroseconds / export.elapsedMicroseconds);
    }
    ratios.sort();
    expect(ratios[2], lessThan(3), reason: 'fixed meta work must be reused');
  });

  test('standard references retain per-import format assertion state', () {
    final document = {
      r'$ref':
          'https://json-schema.org/draft/2020-12/meta/core'
          r'#/$defs/uriReferenceString',
    };
    final relaxed = Ack.fromJsonSchema(document);
    final strict = Ack.fromJsonSchema(document, assertFormats: true);
    final relaxedAgain = Ack.fromJsonSchema(document);
    const value = 'https://invalid host.example';
    for (final schema in [relaxed, relaxedAgain]) {
      expect(schema.safeParse(value).isOk, isTrue);
      expect(schema.safeEncode(value).isOk, isTrue);
    }
    expect(strict.safeParse(value).isFail, isTrue);
    expect(strict.safeEncode(value).isFail, isTrue);
  });
}
