part of '../../ack.dart';

/// Provides validation methods for [ListSchema].
extension ListSchemaValidatorsExt<T extends Object> on ListSchema<T> {
  /// {@macro unique_items_list_validator}
  ///
  /// Example:
  /// ```dart
  /// final schema = Ack.list(Ack.string).uniqueItems();
  /// ```
  ListSchema<T> uniqueItems() {
    return withConstraints([UniqueItemsListValidator()]);
  }

  /// {@macro min_items_list_validator}
  ///
  /// Example:
  /// ```dart
  /// final schema = Ack.list(Ack.string).minItems(2);
  /// ```
  ListSchema<T> minItems(int min) =>
      withConstraints([MinItemsListValidator(min)]);

  /// {@macro max_items_list_validator}
  ///
  /// Example:
  ListSchema<T> maxItems(int max) =>
      withConstraints([MaxItemsListValidator(max)]);
}

/// {@template unique_items_list_validator}
/// Validator that checks if a [List] has unique items
///
/// Equivalent of calling `list.toSet().length == list.length`
/// {@endtemplate}
class UniqueItemsListValidator<T extends Object>
    extends OpenApiConstraintValidator<List<T>> {
  const UniqueItemsListValidator();

  @override
  bool isValid(List<T> value) => value.duplicates.isEmpty;

  @override
  ConstraintError onError(List<T> value) {
    final nonUniqueValues = value.duplicates;

    return buildError(
      message:
          'List items are not unique ${nonUniqueValues.map((e) => e.toString()).join(', ')}',
      context: {'value': value, 'notUnique': nonUniqueValues},
    );
  }

  @override
  Map<String, Object?> toSchema() => {'uniqueItems': true};
  @override
  String get name => 'list_unique_items';

  @override
  String get description => 'List items must be unique';
}

/// {@template min_items_list_validator}
/// Validator that checks if a [List] has at least a certain number of items
///
/// Equivalent of calling `list.length >= min`
/// {@endtemplate}
class MinItemsListValidator<T extends Object>
    extends OpenApiConstraintValidator<List<T>> {
  final int min;
  const MinItemsListValidator(this.min);

  @override
  bool isValid(List<T> value) => value.length >= min;

  @override
  ConstraintError onError(List<T> value) {
    return buildError(
      message: 'List length is less than the minimum required length: $min',
      context: {'value': value, 'min': min},
    );
  }

  @override
  Map<String, Object?> toSchema() => {'minItems': min};

  @override
  String get name => 'list_min_items';

  @override
  String get description => 'List must have at least $min items';
}

/// {@template max_items_list_validator}
/// Validator that checks if a [List] has at most a certain number of items
///
/// Equivalent of calling `list.length <= max`
/// {@endtemplate}
class MaxItemsListValidator<T> extends OpenApiConstraintValidator<List<T>> {
  final int max;
  const MaxItemsListValidator(this.max);

  @override
  bool isValid(List<T> value) => value.length <= max;

  @override
  ConstraintError onError(List<T> value) {
    return buildError(
      message: 'List length is greater than the maximum required length: $max',
      context: {'value': value, 'max': max},
    );
  }

  @override
  Map<String, Object?> toSchema() => {'maxItems': max};

  @override
  String get name => 'list_max_items';

  @override
  String get description => 'List must have at most $max items';
}
