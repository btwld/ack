part of '../schema.dart';

final class ListSchema<V extends Object> extends Schema<List<V>>
    with SchemaFluentMethods<ListSchema<V>, List<V>> {
  final Schema<V> _itemSchema;
  const ListSchema(
    Schema<V> itemSchema, {
    super.constraints = const [],
    super.nullable,
    super.description,
    super.defaultValue,
  })  : _itemSchema = itemSchema,
        super(type: SchemaType.list);

  Schema<V> getItemSchema() => _itemSchema;

  @override
  SchemaResult<List<V>> validateValue(Object? value) {
    final result = super.validateValue(value);

    if (result.isFail) return result;

    final listValue = result.getOrNull();

    if (_nullable && listValue == null) return SchemaResult.unit();

    final itemsViolation = <SchemaError>[];

    for (var i = 0; i < listValue!.length; i++) {
      final itemResult = _itemSchema.validate(listValue[i], debugName: '$i');

      if (itemResult.isFail) {
        itemsViolation.add(itemResult.getError());
      }
    }

    if (itemsViolation.isEmpty) return SchemaResult.ok(listValue);

    return SchemaResult.fail(
      SchemaNestedError(errors: itemsViolation, context: context),
    );
  }

  @override
  List<V>? tryParse(Object? value) {
    if (value is! List) return null;

    List<V>? parsedList = <V>[];
    for (final v in value) {
      final parsed = _itemSchema.tryParse(v);
      if (parsed == null) {
        parsedList = null;
        break;
      }
      parsedList!.add(parsed);
    }

    return parsedList;
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
