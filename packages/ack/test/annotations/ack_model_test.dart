import 'package:ack/annotations.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Schemable options are const and default to class-first conventions',
    () {
      const defaults = Schemable();
      expect(defaults.name, isNull);
      expect(defaults.schemaName, isNull);
      expect(defaults.caseStyle, AckCaseStyle.none);
      expect(defaults.discriminatorKey, isNull);
      expect(defaults.discriminatorValue, isNull);
      expect(defaults.unknownProperties, AckUnknownPropertyPolicy.reject);
      expect(defaults.captureField, 'additionalProperties');

      const configured = Schemable(
        name: 'WireUser',
        schemaName: 'WireUserSchema',
        caseStyle: AckCaseStyle.snake,
        discriminatorKey: 'type',
        discriminatorValue: 'user',
        unknownProperties: AckUnknownPropertyPolicy.capture,
        captureField: 'args',
      );
      expect(configured.name, 'WireUser');
      expect(configured.schemaName, 'WireUserSchema');
      expect(configured.caseStyle, AckCaseStyle.snake);
      expect(configured.discriminatorKey, 'type');
      expect(configured.discriminatorValue, 'user');
      expect(configured.unknownProperties, AckUnknownPropertyPolicy.capture);
      expect(configured.captureField, 'args');
      expect(AckCaseStyle.values, const [
        AckCaseStyle.none,
        AckCaseStyle.snake,
        AckCaseStyle.kebab,
        AckCaseStyle.pascal,
        AckCaseStyle.screamingSnake,
      ]);
      expect(AckUnknownPropertyPolicy.values, const [
        AckUnknownPropertyPolicy.reject,
        AckUnknownPropertyPolicy.discard,
        AckUnknownPropertyPolicy.capture,
      ]);
    },
  );

  test('AckKey accepts a positional wire key name', () {
    const key = AckKey('wire_key');
    expect(key.name, 'wire_key');
  });

  test('rule annotations are const and expose their arguments', () {
    const presence = <Object>[IsOptional(), IsRequired(), IsNotNull()];
    const flags = <Object>[
      IsPositive(),
      IsNegative(),
      IsNotEmpty(),
      IsEmail(),
      IsUrl(),
      IsUri(),
      IsUuid(),
      IsDate(),
      IsDateTime(),
      HasUniqueItems(),
    ];

    expect([...presence, ...flags], everyElement(isA<AckRule>()));
    expect(const HasMin(1).min, 1);
    expect(const HasMax(9.5).max, 9.5);
    expect(const IsMultipleOf(2).divisor, 2);
    expect(const HasMinLength(1).length, 1);
    expect(const HasMaxLength(100).length, 100);
    expect(const HasMatch(r'^[a-z]+$').pattern, r'^[a-z]+$');
    expect(const IsIp().version, isNull);
    expect(const IsIp(version: 4).version, 4);
    expect(const IsIp(version: 6).version, 6);
    expect(const HasMinItems(1).count, 1);
    expect(const HasMaxItems(10).count, 10);
  });
}
