import 'package:ack/src/helpers.dart';
import 'package:meta/meta.dart';

part 'constraint.dart';
part 'schemas/boolean_schema.dart';
part 'schemas/discriminated_schema.dart';
part 'schemas/list_schema.dart';
part 'schemas/num_schema.dart';
part 'schemas/object_schema.dart';
part 'schemas/schema.dart';
part 'schemas/string_schema.dart';
part 'validation.dart';

final class Ack<S extends Schema<T>, T extends Object> {
  final S _schema;
  const Ack(this._schema);

  S nullable() => _schema.copyWith(nullable: true) as S;

  S withConstraints(List<ConstraintsValidator<T>> constraints) {
    return _schema.copyWith(constraints: constraints) as S;
  }

  S call() => _schema;

  void validateOrThrow(Object value) {
    final result = validate(value);

    result.onFail((error) {
      throw AckException(error);
    });
  }

  SchemaResult validate(Object? value) {
    try {
      return _schema.validate(value);
    } catch (e, stackTrace) {
      return Fail(
        SchemaValidationError.unknownException(
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Ack<ListSchema<T>, List<T>> get list => Ack(ListSchema(_schema));

  factory Ack.discriminated({
    required String discriminatorKey,
    required Map<String, ObjectSchema> schemas,
  }) {
    return Ack(
      DiscriminatedMapSchema(
        discriminatorKey: discriminatorKey,
        schemas: schemas,
      ) as S,
    );
  }

  factory Ack.object({
    required Map<String, Schema> properties,
    bool additionalProperties = false,
    List<String> required = const [],
  }) {
    return Ack(
      ObjectSchema(
        properties,
        additionalProperties: additionalProperties,
        required: required,
      ) as S,
    );
  }

  static Ack<StringSchema, String> enumString(List<String> values) {
    return Ack(Ack.string.withConstraints([EnumValidator(values)]));
  }

  static Ack<StringSchema, String> enumValues(List<Enum> values) {
    return enumString(values.map((e) => e.name).toList());
  }

  static const string = Ack(StringSchema());

  static const boolean = Ack(BooleanSchema());

  static const int = Ack(IntSchema());
  static const double = Ack(DoubleSchema());
}

extension OkMapExt on Ack<ObjectSchema, MapValue> {
  Ack<ObjectSchema, MapValue> extend(
    Map<String, Schema> properties, {
    bool? additionalProperties,
    List<String>? required,
    List<ConstraintsValidator<MapValue>>? constraints,
  }) {
    return Ack(
      _schema.extend(
        properties,
        additionalProperties: additionalProperties,
        required: required,
        constraints: constraints,
      ),
    );
  }
}
