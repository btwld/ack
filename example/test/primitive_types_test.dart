import 'package:ack/ack.dart';
import 'package:ack_example/schema_types_primitives.dart';
import 'package:test/test.dart';

void main() {
  group('Primitive Extension Types', () {
    test('PasswordType wraps String and implements String', () {
      final password = PasswordType.parse('mySecurePassword123');

      // Should be a String
      expect(password, isA<String>());

      // Should work with String methods via implements
      expect(password.length, 19);
      expect(password.toUpperCase(), 'MYSECUREPASSWORD123');
      expect(password.contains('Secure'), true);
    });

    test('PasswordType validates min length', () {
      expect(() => PasswordType.parse('short'), throwsA(isA<AckException>()));
    });

    test('PasswordType.safeParse returns SchemaResult<PasswordType>', () {
      final result = PasswordType.safeParse('mySecurePassword123');

      expect(result.isOk, true);
      final password = result.getOrNull();
      expect(password, isA<PasswordType>());
      expect(password, isA<String>());
      expect(password?.length, 19);
    });

    test('AgeType wraps int and implements int', () {
      final age = AgeType.parse(25);

      // Should be an int
      expect(age, isA<int>());

      // Should work with int methods via implements
      expect(age.isEven, false);
      expect(age.isOdd, true);
      expect(age + 5, 30);
      expect(age * 2, 50);
    });

    test('AgeType validates range', () {
      expect(() => AgeType.parse(-1), throwsA(isA<AckException>()));
      expect(() => AgeType.parse(200), throwsA(isA<AckException>()));
    });

    test('PriceType wraps double and implements double', () {
      final price = PriceType.parse(19.99);

      // Should be a double
      expect(price, isA<double>());

      // Should work with double methods via implements
      expect(price.abs(), 19.99);
      expect(price.ceil(), 20);
      expect(price.floor(), 19);
      expect(price + 10, closeTo(29.99, 0.01));
    });

    test('PriceType validates min value', () {
      expect(() => PriceType.parse(-1.0), throwsA(isA<AckException>()));
    });

    test('ActiveType wraps bool and implements bool', () {
      final active = ActiveType.parse(true);

      // Should be a bool
      expect(active, isA<bool>());

      // Should work with bool operations via implements
      expect(active, true);
      expect(!active, false);
      expect(active && true, true);
      expect(active || false, true);
    });

    test('TagsType wraps List<String> and implements List<String>', () {
      final tags = TagsType.parse(['dart', 'flutter', 'validation']);

      // Should be a List<String>
      expect(tags, isA<List<String>>());

      // Should work with List methods via implements
      expect(tags.length, 3);
      expect(tags[0], 'dart');
      expect(tags.first, 'dart');
      expect(tags.last, 'validation');
      expect(tags.contains('flutter'), true);
      expect(tags.map((t) => t.toUpperCase()).toList(), [
        'DART',
        'FLUTTER',
        'VALIDATION',
      ]);
    });

    test('ScoresType wraps List<int> and implements List<int>', () {
      final scores = ScoresType.parse([10, 20, 30, 40]);

      // Should be a List<int>
      expect(scores, isA<List<int>>());

      // Should work with List methods via implements
      expect(scores.length, 4);
      expect(scores[0], 10);
      expect(scores.reduce((a, b) => a + b), 100);
      expect(scores.where((s) => s > 20).toList(), [30, 40]);
    });

    test('Extension types can be used in collections', () {
      final passwords = [
        PasswordType.parse('password123'),
        PasswordType.parse('anotherSecurePass'),
      ];

      expect(passwords, isA<List<PasswordType>>());
      expect(passwords[0], isA<String>());
      expect(passwords.every((p) => p.length >= 8), true);
    });

    test('Extension types can be pattern matched', () {
      final age = AgeType.parse(25);

      final category = switch (age) {
        < 18 => 'minor',
        >= 18 && < 65 => 'adult',
        _ => 'senior',
      };

      expect(category, 'adult');
    });

    test('safeParse captures validation errors', () {
      final result = AgeType.safeParse(200); // max(150)

      expect(result.isFail, true);
      expect(result.isOk, false);
      expect(result.getError(), isNotNull);
      expect(result.getOrNull(), isNull);
    });

    test('Error messages include constraint information', () {
      try {
        AgeType.parse(-5); // min(0)
        fail('Should have thrown AckException');
      } catch (e) {
        expect(e, isA<AckException>());
        final message = e.toString();
        expect(message, contains('Validation failed'));
        expect(message, contains('integer'));
      }
    });

    test('List element types are strongly typed at runtime', () {
      final tags = TagsType.parse(['dart', 'flutter', 'validation']);

      // Type is preserved at runtime
      expect(tags, isA<List<String>>());

      // Can use String methods on elements
      final uppercaseTags = tags.map((t) => t.toUpperCase()).toList();
      expect(uppercaseTags, ['DART', 'FLUTTER', 'VALIDATION']);
    });
  });
}
