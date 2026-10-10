import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('JsonMaybe', () {
    test('JsonMaybe.absent() state and equality', () {
      const absent1 = JsonMaybe<String>.absent();
      const absent2 = JsonAbsent<String>();

      expect(absent1, isA<JsonAbsent<String>>());
      expect(absent1.isAbsent, isTrue);
      expect(absent1.isPresent, isFalse);
      expect(absent1.isNull, isFalse);
      expect(absent1.valueOrNull, isNull);
      expect(absent1, equals(absent2));
      expect(absent1.hashCode, equals(absent2.hashCode));
      expect(absent1.toString(), equals('JsonMaybe.absent()'));
    });

    test('JsonMaybe.value() / present() / nullValue() state and equality', () {
      const present = JsonMaybe<String>.value('Ada');
      const presentAlias = JsonMaybe<String>.present('Ada');
      const explicitNull = JsonMaybe<String>.nullValue();
      const valueNull = JsonMaybe<String>.value(null);

      expect(present, isA<JsonValue<String>>());
      expect(present.isPresent, isTrue);
      expect(present.isAbsent, isFalse);
      expect(present.isNull, isFalse);
      expect(present.valueOrNull, equals('Ada'));
      expect(present, equals(presentAlias));
      expect(present.hashCode, equals(presentAlias.hashCode));
      expect(present.toString(), equals('JsonMaybe.value(Ada)'));

      expect(explicitNull.isPresent, isTrue);
      expect(explicitNull.isAbsent, isFalse);
      expect(explicitNull.isNull, isTrue);
      expect(explicitNull.valueOrNull, isNull);
      expect(explicitNull, equals(valueNull));
      expect(explicitNull.hashCode, equals(valueNull.hashCode));
      expect(explicitNull, isNot(equals(const JsonMaybe<String>.absent())));
    });

    test('JsonValue deep equality on collections', () {
      const listA = JsonMaybe<List<int>>.value([1, 2, 3]);
      const listB = JsonMaybe<List<int>>.value([1, 2, 3]);
      const listC = JsonMaybe<List<int>>.value([1, 2, 4]);

      expect(listA, equals(listB));
      expect(listA.hashCode, equals(listB.hashCode));
      expect(listA, isNot(equals(listC)));
    });

    test('exhaustive switch over JsonMaybe', () {
      String describe(JsonMaybe<int> field) {
        return switch (field) {
          JsonAbsent() => 'omitted',
          JsonValue(:final value) => 'present:$value',
        };
      }

      expect(describe(const JsonMaybe.absent()), equals('omitted'));
      expect(describe(const JsonMaybe.nullValue()), equals('present:null'));
      expect(describe(const JsonMaybe.value(42)), equals('present:42'));
    });
  });
}
