import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  for (final defaults in [false, true]) {
    test('encode validates each nested object once (defaults: $defaults)', () {
      var visits = 0;
      AckSchema<Object, Object> schema = Ack.integer();
      Object value = 1;
      for (var i = 0; i < 1000; i++) {
        schema = Ack.object({'x': schema}).refine((_) {
          visits++;
          return true;
        }, message: 'count object validations');
        value = <String, Object?>{'x': value};
        if (defaults) schema = schema.withDefault(value);
      }
      Object? encoded = schema.encode(value);
      for (var i = 0; i < 1000; i++) {
        encoded = (encoded as Map)['x'];
      }
      expect(encoded, 1);
      expect(visits, 1000);
    });
  }

  test('shared object values are validated separately at each property', () {
    var visits = 0;
    final child = Ack.object({'x': Ack.integer()}).refine((_) {
      visits++;
      return true;
    }, message: 'count occurrences');
    final shared = <String, Object?>{'x': 1};
    expect(
      Ack.object({
        'a': child,
        'b': child,
      }).safeEncode({'a': shared, 'b': shared}).isOk,
      isTrue,
    );
    expect(visits, 2);
  });

  test('later object mutations still return normal encode failures', () {
    for (final mutation in [
      {'extra': true},
      {'x': 'bad'},
    ]) {
      final later = <String, Object?>{'x': 1};
      final trigger = Ack.string().codec<String>(
        decode: (v) => v,
        encode: (v) {
          later.addAll(mutation);
          return v;
        },
      );
      final schema = Ack.object({
        'trigger': trigger,
        'later': Ack.object({'x': Ack.integer()}),
      });
      final result = schema.safeEncode({'trigger': 'ok', 'later': later});
      expect(result.isFail, isTrue);
      expect(
        result.getError().toMap().toString(),
        contains('#/later/${mutation.keys.single}'),
      );
    }
  });
}
