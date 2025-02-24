part of '../ack_base.dart';

final class ListSchema<V extends Object> extends Schema<List<V>> {
  final Schema<V> itemSchema;
  const ListSchema(
    this.itemSchema, {
    super.constraints = const [],
    super.nullable,
  });

  @override
  ListSchema<V> copyWith({
    List<ConstraintsValidator<List<V>>>? constraints,
    bool? nullable,
  }) {
    return ListSchema(
      itemSchema,
      constraints: constraints ?? _constraints,
      nullable: nullable ?? _nullable,
    );
  }

  @override
  List<V>? _tryParse(Object value) {
    if (value is! List) return null;

    final parsedList = <V>[];
    for (final v in value) {
      final parsed = itemSchema._tryParse(v);
      if (parsed == null) {
        parsedList.clear();
        break;
      }
      parsedList.add(parsed);
    }
    return parsedList;
  }

  @override
  List<ConstraintsValidationError> _validateParsed(List<V> value) {
    final constraintsErrors = _constraints
        .map((e) => e.validate(value))
        .whereType<ConstraintsValidationError>()
        .toList();

    final errors = <ListConstraintsValidationError>[];
    for (var i = 0; i < value.length; i++) {
      final result = itemSchema.validate(value[i]);

      result.onFail((error) {
        errors.add(ListConstraintsValidationError.index(i, error));
      });
    }
    return [...constraintsErrors, ...errors];
  }
}

extension ListSchemaExt<T extends Object> on Schema<List<T>> {
  Schema<List<T>> _consraint(ConstraintsValidator<List<T>> validator) =>
      copyWith(constraints: [validator]);

  Schema<List<T>> uniqueItems() => _consraint(UniqueItemsValidator());

  Schema<List<T>> minItems(int min) => _consraint(MinItemsValidator(min));

  Schema<List<T>> maxItems(int max) => _consraint(MaxItemsValidator(max));
}

// unique item list validator
class UniqueItemsValidator<T extends Object>
    extends ConstraintsValidator<List<T>> {
  const UniqueItemsValidator()
      : super(
          type: 'list_unique_items',
          description: 'List items must be unique',
        );

  List<T> _notUnique(List<T> value) {
    final unique = value.toSet();
    return unique.length == value.length
        ? value
        : value.where((e) => !unique.contains(e)).toList();
  }

  @override
  ConstraintsValidationError? validate(List<T> value) {
    final unique = value.toSet();
    return unique.length == value.length
        ? null
        : ConstraintsValidationError(
            type: type,
            message:
                'List items are not unique ${_notUnique(value).map((e) => e.toString()).join(', ')}',
            context: {
              'value': value,
              'unique': unique,
            },
          );
  }
}

// min length of list validator
class MinItemsValidator<T extends Object>
    extends ConstraintsValidator<List<T>> {
  final int min;
  const MinItemsValidator(this.min)
      : super(
          type: 'list_min_items',
          description: 'List must have at least $min items',
        );

  @override
  ConstraintsValidationError? validate(List<T> value) {
    return value.length >= min
        ? null
        : ConstraintsValidationError(
            type: type,
            message:
                'List length is less than the minimum required length: $min',
            context: {
              'value': value,
              'min': min,
            },
          );
  }
}

// max length of list validator
class MaxItemsValidator<T> extends ConstraintsValidator<List<T>> {
  final int max;
  const MaxItemsValidator(this.max)
      : super(
          type: 'list_max_items',
          description: 'List must have at most $max items',
        );

  @override
  ConstraintsValidationError? validate(List<T> value) {
    return value.length <= max
        ? null
        : ConstraintsValidationError(
            type: type,
            message:
                'List length is greater than the maximum required length: $max',
            context: {
              'value': value,
              'max': max,
            },
          );
  }
}

final class ListConstraintsValidationError extends ConstraintsValidationError {
  const ListConstraintsValidationError._({
    required super.type,
    required super.message,
    required super.context,
  });

  // Index error
  factory ListConstraintsValidationError.index(
    int index,
    SchemaValidationError error,
  ) {
    return ListConstraintsValidationError._(
      type: 'list_index_error',
      message: 'List index $index has errors: ${error.message}',
      context: {
        'index': index,
        'error': error.toMap(),
      },
    );
  }
}
