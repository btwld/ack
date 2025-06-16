// deprecations.dart
//
// Deprecated type aliases for backwards compatibility.
// These aliases will be removed in a future release. Please migrate to the new types.

import 'constraints/constraint.dart';
import 'constraints/list_extensions.dart';
import 'constraints/number_extensions.dart';
import 'constraints/validators.dart';
import 'schemas/schema.dart';
import 'validation/ack_exception.dart';

@Deprecated('Use Validator<T> instead')
typedef ConstraintValidator<T extends Object> = Validator<T>;

@Deprecated('Use Validator<T> instead')
typedef OpenApiConstraintValidator<T extends Object> = Validator<T>;

// --- List Validators ---

@Deprecated('Use ListUniqueItemsConstraint instead')
typedef UniqueItemsListValidator<T extends Object>
    = ListUniqueItemsConstraint<T>;

// --- Exceptions ---

@Deprecated('Use AckViolationException instead')
typedef AckViolationException = AckException;

// --- Numeric Schemas ---
// Previously you might have used minValue/maxValue.
// Now use min/max methods defined in the NumSchemaValidatorExt extension.

extension LegacyNumSchemaExtensions<T extends num> on NumSchema<T> {
  @Deprecated('Use min(T min) instead')
  NumSchema<T> minValue(T min) => this.min(min);

  @Deprecated('Use max(T max) instead')
  NumSchema<T> maxValue(T max) => this.max(max);

  @Deprecated('Use range(T min, T max) instead')
  NumSchema<T> rangeNum(T min, T max) => range(min, max);

  @Deprecated('Use multipleOf(T multiple) instead')
  NumSchema<T> multipleOfNum(T multiple) => multipleOf(multiple);
}

// --- List Schemas ---
// Old extension methods for lists may have used different names.
// For example, if you previously used .minLength() or .maxLength() on lists,
// map these to the new .minItems() or .maxItems() respectively.

extension LegacyListSchemaExtensions<T extends Object> on ListSchema<T> {
  @Deprecated('Use minItems(int min) instead')
  ListSchema<T> minLength(int min) => minItems(min);

  @Deprecated('Use maxItems(int max) instead')
  ListSchema<T> maxLength(int max) => maxItems(max);
}