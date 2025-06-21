part of 'schema.dart';

final class ListSchema<V extends Object> extends AckSchema<List<V>>
    with SchemaFluentMethods<ListSchema<V>, List<V>> {
  final AckSchema<V> _itemSchema;
  const ListSchema(
    AckSchema<V> itemSchema, {
    super.constraints = const [],
    super.nullable,
    super.description,
    super.defaultValue,
  })  : _itemSchema = itemSchema,
        super(type: SchemaType.list);

  @override
  List<V>? _tryConvertType(Object? value) {
    if (value is! List) return null;

    List<V>? parsedList = <V>[];
    for (final v in value) {
      final parsed = _itemSchema._tryConvertType(v);
      if (parsed == null) {
        parsedList = null;
        break;
      }
      parsedList!.add(parsed);
    }

    return parsedList;
  }

  AckSchema<V> getItemSchema() => _itemSchema;

  @override
  SchemaResult<List<V>> validateNonNullValue(List<V> value) {
    final itemsViolation = <SchemaError>[];

    for (var i = 0; i < value.length; i++) {
      final itemResult = _itemSchema.validate(value[i], debugName: '$i');

      if (itemResult.isFail) {
        itemsViolation.add(itemResult.getError());
      }
    }

    if (itemsViolation.isEmpty) return SchemaResult.ok(value);

    return SchemaResult.fail(
      SchemaNestedError(errors: itemsViolation, context: context),
    );
  }

  @override
  ListSchema<V> copyWith({
    List<Validator<List<V>>>? constraints,
    bool? nullable,
    String? description,
    List<V>? defaultValue,
  }) {
    return ListSchema(
      _itemSchema,
      constraints: constraints ?? _constraints,
      nullable: nullable ?? _nullable,
      description: description ?? _description,
      defaultValue: defaultValue ?? _defaultValue,
    );
  }

  @override
  ListSchema<V> call({
    bool? nullable,
    String? description,
    List<Validator<List<V>>>? constraints,
    List<V>? defaultValue,
  }) {
    return copyWith(
      constraints: constraints,
      nullable: nullable,
      description: description,
      defaultValue: defaultValue,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'itemSchema': _itemSchema.toMap()};
  }
}
