import 'package:ack/annotations.dart';
import 'package:test/test.dart';

Object _customSchema() => Object();

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
        schemaName: 'WireUserSchema',
        caseStyle: AckCaseStyle.snake,
        discriminatorKey: 'type',
        discriminatorValue: 'user',
        unknownProperties: AckUnknownPropertyPolicy.capture,
        captureField: 'args',
      );
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

  test('AckField accepts name, schema tear-off, and description', () {
    const inferred = AckField(
      name: 'wire_key',
      schema: _customSchema,
      description: 'Field description',
    );
    expect(inferred.name, 'wire_key');
    expect(inferred.schema, same(_customSchema));
    expect(inferred.description, 'Field description');

    const defaults = AckField();
    expect(defaults.name, isNull);
    expect(defaults.schema, isNull);
    expect(defaults.description, isNull);
  });

  test('presence and null annotations are const', () {
    const optional = Optional();
    const required = Required();
    const notNull = NotNull();
    expect(optional, isA<Optional>());
    expect(required, isA<Required>());
    expect(notNull, isA<NotNull>());
  });

  test('constraint sugar annotations are const data', () {
    const annotations = <Object>[
      Min(1),
      Max(9),
      MultipleOf(2),
      Positive(),
      Negative(),
      MinLength(1),
      MaxLength(100),
      Matches(r'^[a-z]+$'),
      Email(),
      NotEmpty(),
      MinItems(1),
      MaxItems(10),
      UniqueItems(),
    ];

    expect((annotations[0] as Min).value, 1);
    expect((annotations[1] as Max).value, 9);
    expect((annotations[2] as MultipleOf).value, 2);
    expect((annotations[5] as MinLength).length, 1);
    expect((annotations[6] as MaxLength).length, 100);
    expect((annotations[7] as Matches).pattern, r'^[a-z]+$');
    expect((annotations[10] as MinItems).count, 1);
    expect((annotations[11] as MaxItems).count, 10);
  });
}
