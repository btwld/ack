// ignore_for_file: deprecated_member_use_from_same_package

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

  test('Check.* constraint annotations are const and expose kind + value', () {
    const checks = <Check>[
      Check.min(1),
      Check.max(9.5),
      Check.multipleOf(2),
      Check.positive(),
      Check.negative(),
      Check.minLength(1),
      Check.maxLength(100),
      Check.matches(r'^[a-z]+$'),
      Check.notEmpty(),
      Check.email(),
      Check.url(),
      Check.uri(),
      Check.uuid(),
      Check.date(),
      Check.dateTime(),
      Check.datetime(),
      Check.ip(),
      Check.ip(version: 4),
      Check.ipv4(),
      Check.ipv6(),
      Check.minItems(1),
      Check.maxItems(10),
      Check.uniqueItems(),
      Check.unique(),
    ];

    expect(
      checks.map((c) => (c.kind, c.value)).toList(),
      const <(String, Object?)>[
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
        ('datetime', null),
        ('ip', null),
        ('ip', 4),
        ('ipv4', null),
        ('ipv6', null),
        ('minItems', 1),
        ('maxItems', 10),
        ('uniqueItems', null),
        ('unique', null),
      ],
    );
  });

  test('legacy constraint sugar annotations remain const data', () {
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
