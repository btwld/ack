import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  test('ContextO rejection scales linearly with contextual characters', () {
    final schema = Ack.fromJsonSchema({
      'format': 'idn-hostname',
    }, assertFormats: true);
    double elapsed(int size) {
      final input = '${'・' * size}カ.example';
      final samples = <int>[];
      for (var sample = 0; sample < 3; sample++) {
        final watch = Stopwatch()..start();
        expect(schema.safeParse(input).isFail, isTrue);
        samples.add(watch.elapsedMicroseconds);
      }
      samples.sort();
      return samples[1].toDouble();
    }

    // Warm up format assertion and Unicode tables before comparing growth.
    elapsed(1000);
    final small = elapsed(1000);
    final large = elapsed(10000);
    expect(
      large / small,
      lessThan(40),
      reason: '10x input must stay below 40x',
    );
  });
}
