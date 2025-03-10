// deprecations.dart
//
// Deprecated type aliases for backwards compatibility.
// These aliases will be removed in a future release. Please migrate to the new types.

import 'package:ack/src/constraints/constraint_extensions.dart';

import 'constraints/constraint.dart';
import 'constraints/validators.dart';
import 'schemas/schema.dart';
import 'validation/ack_exception.dart';

@Deprecated('Use Validator<T> instead')
typedef ConstraintValidator<T extends Object> = Validator<T>;

@Deprecated('Use Validator<T> instead')
typedef OpenApiConstraintValidator<T extends Object> = Validator<T>;

@Deprecated('Use StringEmailConstraint instead')
typedef EmailStringValidator = StringEmailConstraint;

@Deprecated('Use StringHexColorValidator instead')
typedef HexColorStringValidator = StringHexColorValidator;

@Deprecated('Use StringEmptyConstraint instead')
typedef IsEmptyStringValidator = StringEmptyConstraint;

@Deprecated('Use StringMinLengthConstraint instead')
typedef MinLengthStringValidator = StringMinLengthConstraint;

@Deprecated('Use StringMaxLengthConstraint instead')
typedef MaxLengthStringValidator = StringMaxLengthConstraint;

@Deprecated('Use StringEnumConstraint instead')
typedef OneOfStringValidator = StringEnumConstraint;

@Deprecated('Use StringNotOneOfValidator instead')
typedef NotOneOfStringValidator = StringNotOneOfValidator;

@Deprecated('Use StringEnumConstraint instead')
typedef EnumStringValidator = StringEnumConstraint;

@Deprecated('Use StringNotEmptyValidator instead')
typedef NotEmptyStringValidator = StringNotEmptyValidator;

@Deprecated('Use StringDateTimeConstraint instead')
typedef DateTimeStringValidator = StringDateTimeConstraint;

@Deprecated('Use StringDateConstraint instead')
typedef DateStringValidator = StringDateConstraint;

// --- List Validators ---

@Deprecated('Use ListUniqueItemsConstraint instead')
typedef UniqueItemsListValidator<T extends Object>
    = ListUniqueItemsConstraint<T>;

@Deprecated('Use ListMinItemsConstraint instead')
typedef MinItemsListValidator<T extends Object> = ListMinItemsConstraint<T>;

@Deprecated('Use ListMaxItemsConstraint instead')
typedef MaxItemsListValidator<T extends Object> = ListMaxItemsConstraint<T>;

// --- Number Validators ---

@Deprecated('Use NumberMinConstraint instead')
typedef MinNumValidator<T extends num> = NumberMinConstraint<T>;

@Deprecated('Use NumberMaxConstraint instead')
typedef MaxNumValidator<T extends num> = NumberMaxConstraint<T>;

@Deprecated('Use NumberRangeConstraint instead')
typedef RangeNumValidator<T extends num> = NumberRangeConstraint<T>;

@Deprecated('Use NumberMultipleOfConstraint instead')
typedef MultipleOfNumValidator<T extends num> = NumberMultipleOfConstraint<T>;

// --- Object Validators ---

@Deprecated('Use ObjectMinPropertiesConstraint instead')
typedef MinPropertiesObjectValidator = ObjectMinPropertiesConstraint;

@Deprecated('Use ObjectMaxPropertiesConstraint instead')
typedef MaxPropertiesObjectValidator = ObjectMaxPropertiesConstraint;

// --- Discriminated Object Validators ---
// If you previously used DiscriminatedObjectSchemaError,
// please migrate to the new discriminator constraints.
@Deprecated('Use ObjectDiscriminatorStructureConstraint instead')
typedef DiscriminatedObjectSchemaError = ObjectDiscriminatorStructureConstraint;

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
