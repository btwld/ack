part of '../../ack_base.dart';

class UniqueItemsValidator<T extends Object>
    extends ConstraintValidator<List<T>> {
  const UniqueItemsValidator();

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
      context: {'value': value, 'notUnique': notUnique},
    );
  }

  @override
  String get name => 'list_unique_items';

  @override
  String get description => 'List items must be unique';
}

class MinItemsValidator<T extends Object> extends ConstraintValidator<List<T>> {
  final int min;
  const MinItemsValidator(this.min);

  @override
  bool check(List<T> value) => value.length >= min;

  @override
  ConstraintError onError(List<T> value) {
    return buildError(
      message: 'List length is less than the minimum required length: $min',
      context: {'value': value, 'min': min},
    );
  }

  @override
  String get name => 'list_min_items';

  @override
  String get description => 'List must have at least $min items';
}

class MaxItemsValidator<T> extends ConstraintValidator<List<T>> {
  final int max;
  const MaxItemsValidator(this.max);

  @override
  bool check(List<T> value) => value.length <= max;

  @override
  ConstraintError onError(List<T> value) {
    return buildError(
      message: 'List length is greater than the maximum required length: $max',
      context: {'value': value, 'max': max},
    );
  }

  @override
  String get name => 'list_max_items';

  @override
  String get description => 'List must have at most $max items';
}
