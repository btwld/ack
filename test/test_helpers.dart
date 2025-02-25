import 'package:ack/ack.dart';
import 'package:test/test.dart';

class IsSchemaError extends Matcher {
  final String type;

  IsSchemaError(this.type);

  @override
  bool matches(item, Map matchState) {
    return item is SchemaError && item.type == type;
  }

  @override
  Description describe(Description description) {
    return description.add(
      'a SchemaError containing error type "$type"',
    );
  }

  @override
  Description describeMismatch(
    item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is! SchemaError) {
      return mismatchDescription.add('was not a SchemaError');
    }

    return mismatchDescription.add(
      'had error type "$item" instead of "$type"',
    );
  }
}

class IsConstraintError extends Matcher {
  final String name;

  IsConstraintError(this.name);

  @override
  bool matches(item, Map matchState) {
    return item is ConstraintError && item.name == name;
  }

  @override
  Description describe(Description description) {
    return description.add(
      'a ConstraintError containing error name "$name"',
    );
  }

  @override
  Description describeMismatch(
    item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is! ConstraintError) {
      return mismatchDescription.add('was not a ConstraintError');
    }
    return mismatchDescription.add(
      'Constrained name is "$item" instead of "$name"',
    );
  }
}

class HasSchemaErrors extends Matcher {
  final List<String> types;
  final int expectedCount;

  /// [types] is a list of allowed SchemaError types.
  /// [expectedCount] is an optional parameter; if provided, the Fail result must contain exactly that many errors.
  HasSchemaErrors(this.types, this.expectedCount);

  @override
  bool matches(item, Map matchState) {
    final isFail = item is Fail;
    final isErrors = item is List<SchemaError>;
    if (!isFail && !isErrors) {
      matchState['reason'] = 'was not a Fail result or a List<SchemaError>';
      return false;
    }

    List<SchemaError> errors = [];

    if (item is Fail) {
      errors = item.errors;
    } else if (item is List<SchemaError>) {
      errors = item;
    } else {
      throw ArgumentError('Invalid argument type: ${item.runtimeType}');
    }

    if (errors.length != expectedCount) {
      matchState['reason'] =
          'expected $expectedCount SchemaErrors with types $types, but found ${errors.length} errors with types ${errors.map((e) => e.type).toList()}';
      return false;
    }

    if (errors.isEmpty) {
      matchState['reason'] = 'Fail result did not contain any SchemaErrors';
      return false;
    }

    for (final error in errors) {
      if (!types.contains(error.type)) {
        matchState['reason'] =
            'expected $expectedCount SchemaErrors with types $types, but found ${errors.length} errors with types ${errors.map((e) => e.type).toList()}';
        return false;
      }
    }

    return true;
  }

  @override
  Description describe(Description description) {
    return description.add(
        'a Fail result containing $expectedCount SchemaErrors with types $types');
  }

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    if (matchState.containsKey('reason')) {
      mismatchDescription.add(matchState['reason']);
    } else {
      mismatchDescription.add('was $item');
    }
    return mismatchDescription;
  }
}

class HasConstraintErrors extends Matcher {
  final List<String> names;
  final int expectedCount;

  HasConstraintErrors(this.names, this.expectedCount);

  @override
  bool matches(item, Map matchState) {
    if (item is! Fail) {
      matchState['reason'] = 'was not a Fail result';
      return false;
    }

    final errors = item.errors.whereType<ConstraintError>();

    if (errors.length != expectedCount) {
      matchState['reason'] =
          'expected $expectedCount ConstraintErrors with names $names, but found ${errors.length} errors with names ${errors.map((e) => e.name).toList()}';
      return false;
    }

    for (final error in errors) {
      if (!names.contains(error.name)) {
        matchState['reason'] =
            'expected $expectedCount ConstraintErrors with names $names, but found ${errors.length} errors with names ${errors.map((e) => e.name).toList()}';
        return false;
      }
    }

    return true;
  }

  @override
  Description describe(Description description) {
    return description.add(
        'a Fail result containing $expectedCount ConstraintErrors with names $names');
  }

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    if (matchState.containsKey('reason')) {
      mismatchDescription.add(matchState['reason']);
    } else {
      mismatchDescription.add('was $item');
    }
    return mismatchDescription;
  }
}

Matcher _hasSchemaErrors(List<String> types, {required int count}) {
  assert(
    count == types.length,
    'count must be equal to the number of types in the list',
  );
  return HasSchemaErrors(types, count);
}

class IsOkMatcher<T extends Object> extends Matcher {
  const IsOkMatcher();

  @override
  bool matches(item, Map matchState) {
    // Check if the item is of type Ok<T, E>.
    if (item is! Ok<T>) {
      // Save extra info in matchState.
      matchState['actualType'] = item.runtimeType;
      matchState['expectedType'] = 'Ok<$T>';
      return false;
    }
    return true;
  }

  @override
  Description describe(Description description) =>
      description.add('an Ok result of type Ok<$T>');

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    // Use the stored values to generate a more helpful message.
    if (matchState.containsKey('actualType') &&
        matchState.containsKey('expectedType')) {
      mismatchDescription.add('has type ${matchState['actualType']}, '
          'but expected ${matchState['expectedType']}');
    } else {
      mismatchDescription.add('was $item');
    }
    return mismatchDescription;
  }
}

Matcher isSchemaError(String type) => IsSchemaError(type);
Matcher isConstraintError(String name) => IsConstraintError(name);

Matcher hasOneSchemaError(String type) => _hasSchemaErrors([type], count: 1);
Matcher hasTwoSchemaErrors(List<String> types) =>
    _hasSchemaErrors(types, count: 2);
Matcher hasThreeSchemaErrors(List<String> types) =>
    _hasSchemaErrors(types, count: 3);

Matcher hasOneConstraintError(String name) => HasConstraintErrors([name], 1);
Matcher hasTwoConstraintErrors(List<String> names) =>
    HasConstraintErrors(names, 2);
Matcher hasThreeConstraintErrors(List<String> names) =>
    HasConstraintErrors(names, 3);

extension FailExt<T extends Object> on Fail<T> {
  List<SchemaError> get schemaErrors =>
      errors.whereType<SchemaError>().toList();

  List<PathSchemaError> get pathSchemaError =>
      errors.whereType<PathSchemaError>().toList();
}
