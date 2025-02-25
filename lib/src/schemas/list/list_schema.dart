part of '../../ack.dart';

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

  @override
  List<V>? _tryParse(Object value) {
    if (value is! List) return null;

    List<V>? parsedList = <V>[];
    for (final v in value) {
      final parsed = _itemSchema._tryParse(v);
      if (parsed == null) {
        parsedList = null;
        break;
      }
      parsedList!.add(parsed);
    }

    return parsedList;
  }

  @override
  List<SchemaError> _validateAsType(List<V> value) {
    final errors = [
      ..._constraints.map((e) => e.validate(value)).whereType<SchemaError>(),
    ];

    for (var i = 0; i < value.length; i++) {
      final result = _itemSchema.checkResult(value[i]);

      result.onFail((errors) {
        errors.addAll(
          SchemaError.pathSchemas(
            path: '[$i]',
            message: 'Item in index [$i] schema validation failed',
            errors: errors,
            schema: _itemSchema,
          ),
        );
      });
    }

    return errors;
  }

  Schema<V> getItemSchema() => _itemSchema;

  @override
  ListSchema<V> copyWith({
    List<ConstraintValidator<List<V>>>? constraints,
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
    List<ConstraintValidator<List<V>>>? constraints,
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
