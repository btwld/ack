part of '../../ack_base.dart';

final class ListSchema<V extends Object> extends Schema<List<V>> {
  final Schema<V> _itemSchema;
  ListSchema(
    Schema<V> itemSchema, {
    super.constraints = const [],
    super.nullable,
    super.strict,
  }) : _itemSchema = itemSchema.copyWith(strict: strict);

  @override
  ListSchema<V> copyWith({
    List<ConstraintValidator<List<V>>>? constraints,
    bool? nullable,
    bool? strict,
  }) {
    return ListSchema(
      _itemSchema,
      constraints: constraints ?? _constraints,
      nullable: nullable ?? _nullable,
      strict: strict ?? _strict,
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
      final result = _itemSchema.validate(value[i]);

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

extension ListSchemaExt<T extends Object> on Schema<List<T>> {
  Schema<List<T>> _consraint(ConstraintValidator<List<T>> validator) =>
      copyWith(constraints: [validator]);

  Schema<List<T>> uniqueItems() => _consraint(UniqueItemsValidator());

  Schema<List<T>> minItems(int min) => _consraint(MinItemsValidator(min));

  Schema<List<T>> maxItems(int max) => _consraint(MaxItemsValidator(max));
}
