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

  test(
    'Validate.* constraint annotations are const and expose kind + value',
    () {
      const checks = <Validate>[
        Validate.optional(),
        Validate.required(),
        Validate.notNull(),
        Validate.min(1),
        Validate.max(9.5),
        Validate.multipleOf(2),
        Validate.positive(),
        Validate.negative(),
        Validate.minLength(1),
        Validate.maxLength(100),
        Validate.matches(r'^[a-z]+$'),
        Validate.notEmpty(),
        Validate.email(),
        Validate.url(),
        Validate.uri(),
        Validate.uuid(),
        Validate.date(),
        Validate.dateTime(),
        Validate.ip(),
        Validate.ip(version: 4),
        Validate.ipv4(),
        Validate.ipv6(),
        Validate.minItems(1),
        Validate.maxItems(10),
        Validate.uniqueItems(),
      ];

      expect(
        checks.map((c) => (c.kind, c.value)).toList(),
        const <(String, Object?)>[
          ('optional', null),
          ('required', null),
          ('notNull', null),
          ('min', 1),
          ('max', 9.5),
          ('multipleOf', 2),
          ('positive', null),
          ('negative', null),
          ('minLength', 1),
          ('maxLength', 100),
          ('matches', r'^[a-z]+$'),
          ('notEmpty', null),
          ('email', null),
          ('url', null),
          ('uri', null),
          ('uuid', null),
          ('date', null),
          ('dateTime', null),
          ('ip', null),
          ('ip', 4),
          ('ipv4', null),
          ('ipv6', null),
          ('minItems', 1),
          ('maxItems', 10),
          ('uniqueItems', null),
        ],
      );
    },
  );
}
