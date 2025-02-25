part of '../../ack_base.dart';

final class ListSchema<V extends Object> extends Schema<List<V>>
    with SchemaFluentMethods<ListSchema<V>, List<V>> {
  late final Schema<V> _itemSchema;
  ListSchema(
    Schema<V> itemSchema, {
    super.constraints = const [],
    super.nullable,
    super.strict,
    super.description,
  }) {
    _itemSchema = _strict ? _applyStrictToSchema(itemSchema) : itemSchema;
  }

  Schema<V> _applyStrictToSchema(Schema<V> schema) {
    return schema.copyWith(strict: true);
  }

  @override
  ListSchema<V> copyWith({
    List<ConstraintValidator<List<V>>>? constraints,
    bool? nullable,
    bool? strict,
    String? description,
  }) {
    return ListSchema(
      _itemSchema,
      constraints: constraints ?? _constraints,
      nullable: nullable ?? _nullable,
      strict: strict ?? _strict,
      description: description ?? _description,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      'type': 'list',
      'itemSchema': _itemSchema.toMap(),
      'nullable': _nullable,
      'constraints': _constraints.map((e) => e.toMap()).toList(),
    };
  }

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
  List<SchemaError> validateAsType(List<V> value) {
    final errors = [
      ..._constraints.map((e) => e.validate(value)).whereType<SchemaError>()
    ];

    for (var i = 0; i < value.length; i++) {
      final result = _itemSchema.checkResult(value[i]);

      result.onFail((errors) {
        errors.addAll(
          SchemaError.pathSchemas(
            path: '[$i]',
            errors: errors,
            message: 'Item in index [$i] schema validation failed',
            schema: _itemSchema,
          ),
        );
      });
    }
    return errors;
  }
}

extension ListSchemaExt<T extends Object> on ListSchema<T> {
  ListSchema<T> uniqueItems() => withConstraints([UniqueItemsValidator()]);

  ListSchema<T> minItems(int min) => withConstraints([MinItemsValidator(min)]);

  ListSchema<T> maxItems(int max) => withConstraints([MaxItemsValidator(max)]);
}
