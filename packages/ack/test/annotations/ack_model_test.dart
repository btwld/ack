// These tests also cover the deprecated AckModel and AckField.presence API.
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
      expect(defaults.jsonSerializable.includeIfNull, isFalse);
      expect(defaults.jsonSerializable.fieldRename!.name, 'none');

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
      expect(configured.jsonSerializable.includeIfNull, isFalse);
      expect(configured.jsonSerializable.fieldRename!.name, 'snake');
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

  test('every case style maps to the pinned JSON phase configuration', () {
    const models = [
      Schemable(),
      Schemable(caseStyle: AckCaseStyle.snake),
      Schemable(caseStyle: AckCaseStyle.kebab),
      Schemable(caseStyle: AckCaseStyle.pascal),
      Schemable(caseStyle: AckCaseStyle.screamingSnake),
    ];
    final configs = {
      for (final model in models) model.caseStyle: model.jsonSerializable,
    };

    expect(
      configs.map((style, config) => MapEntry(style, config.fieldRename!.name)),
      const {
        AckCaseStyle.none: 'none',
        AckCaseStyle.snake: 'snake',
        AckCaseStyle.kebab: 'kebab',
        AckCaseStyle.pascal: 'pascal',
        AckCaseStyle.screamingSnake: 'screamingSnake',
      },
    );
    expect(configs.values.every((config) => !config.includeIfNull!), isTrue);
  });

  test('deprecated AckModel derives the same JSON configuration', () {
    const model = AckModel(caseStyle: AckCaseStyle.kebab);
    const schemable = Schemable(caseStyle: AckCaseStyle.kebab);

    expect(model.jsonSerializable.fieldRename!.name, 'kebab');
    expect(
      model.jsonSerializable.fieldRename,
      schemable.jsonSerializable.fieldRename,
    );
    expect(model.jsonSerializable.includeIfNull, isFalse);
  });

  test('AckField accepts a schema tear-off and a presence override', () {
    const inferred = AckField(schema: _customSchema);
    expect(inferred.schema, same(_customSchema));
    expect(inferred.presence, AckFieldPresence.inferred);

    const optional = AckField(presence: AckFieldPresence.optional);
    expect(optional.schema, isNull);
    expect(optional.presence, AckFieldPresence.optional);
    expect(AckFieldPresence.values, const [
      AckFieldPresence.inferred,
      AckFieldPresence.required,
      AckFieldPresence.optional,
    ]);
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
      Pattern(r'^[a-z]+$'),
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
    expect((annotations[7] as Pattern).pattern, r'^[a-z]+$');
    expect((annotations[10] as MinItems).count, 1);
    expect((annotations[11] as MaxItems).count, 10);
  });

  test('JsonKey is re-exported without importing json_annotation', () {
    const key = JsonKey(name: 'wire_name');
    expect(key.name, 'wire_name');
  });
}
