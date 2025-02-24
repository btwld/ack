part of '../ack_base.dart';

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

// unique item list validator
class UniqueItemsValidator<T extends Object>
    extends ConstraintValidator<List<T>> {
  const UniqueItemsValidator();

  @override
  String get name => 'list_unique_items';

  @override
  String get description => 'List items must be unique';

  List<T> _notUnique(List<T> value) {
    final unique = value.toSet();
    return unique.length == value.length
        ? value
        : value.where((e) => !unique.contains(e)).toList();
  }

  @override
  bool check(List<T> value) {
    final unique = value.toSet();
    return unique.length == value.length;
  }

  @override
  ConstraintError onError(List<T> value) {
    final notUnique = _notUnique(value);
    return buildError(
      message:
          'List items are not unique ${notUnique.map((e) => e.toString()).join(', ')}',
      context: {
        'value': value,
        'notUnique': notUnique,
      },
    );
  }
}

// min length of list validator
class MinItemsValidator<T extends Object> extends ConstraintValidator<List<T>> {
  final int min;
  const MinItemsValidator(this.min);

  @override
  String get name => 'list_min_items';

  @override
  String get description => 'List must have at least $min items';

  @override
  bool check(List<T> value) => value.length >= min;

  @override
  ConstraintError onError(List<T> value) {
    return buildError(
      message: 'List length is less than the minimum required length: $min',
      context: {
        'value': value,
        'min': min,
      },
    );
  }
}

// max length of list validator
class MaxItemsValidator<T> extends ConstraintValidator<List<T>> {
  final int max;
  const MaxItemsValidator(this.max);

  @override
  String get name => 'list_max_items';

  @override
  String get description => 'List must have at most $max items';

  @override
  bool check(List<T> value) => value.length <= max;

  @override
  ConstraintError onError(List<T> value) {
    return buildError(
      message: 'List length is greater than the maximum required length: $max',
      context: {
        'value': value,
        'max': max,
      },
    );
  }
}
