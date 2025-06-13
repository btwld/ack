/// Decorator for classes that need schema validation
/// This annotation marks a class for schema generation
class Schema {
  /// Model description for documentation
  final String? description;

  /// Whether to allow additional properties not defined in the schema
  final bool additionalProperties;

  /// The name of the field that should store additional properties
  /// Must be a `Map<String, dynamic>` field in your class
  final String? additionalPropertiesField;

  /// Name of the schema class to generate (defaults to {ClassName}Schema)
  final String? schemaClassName;

  /// Field to use as discriminator for polymorphic sealed or abstract classes
  final String? discriminatedKey;

  /// Value to use for this specific subclass in a discriminated hierarchy
  final String? discriminatedValue;

  const Schema({
    this.description,
    this.additionalProperties = false,
    this.additionalPropertiesField,
    this.schemaClassName,
    this.discriminatedKey,
    this.discriminatedValue,
  });
}

/// Annotation to specify which constructor to use for schema generation
class SchemaConstructor {
  /// The name of the constructor (leave empty for default constructor)
  final String? name;

  const SchemaConstructor([this.name]);
}

/// Base class for property constraint annotations
abstract class PropertyConstraint {
  const PropertyConstraint();

  /// Get constraint key for code generation
  String get constraintKey;

  /// Get constraint parameters for code generation
  Map<String, Object?> get parameters;
}

/// Mark a property as required in the schema
class IsRequired extends PropertyConstraint {
  const IsRequired();

  @override
  String get constraintKey => 'required';

  @override
  Map<String, Object?> get parameters => {};
}

/// @deprecated Use IsRequired instead for consistent naming
@Deprecated('Use IsRequired instead for consistent naming')
class Required extends IsRequired {
  const Required();
}

/// Mark a property as nullable in the schema
class IsNullable extends PropertyConstraint {
  const IsNullable();

  @override
  String get constraintKey => 'nullable';

  @override
  Map<String, Object?> get parameters => {};
}

/// @deprecated Use IsNullable instead for consistent naming
@Deprecated('Use IsNullable instead for consistent naming')
class Nullable extends IsNullable {
  const Nullable();
}

/// Add a description to a property
class Description extends PropertyConstraint {
  final String text;

  const Description(this.text);

  @override
  String get constraintKey => 'description';

  @override
  Map<String, Object?> get parameters => {'text': text};
}

// String constraints
class IsEmail extends PropertyConstraint {
  /// Optional description for documentation or error message customization
  final String? description;

  const IsEmail({this.description});

  @override
  String get constraintKey => 'email';

  @override
  Map<String, Object?> get parameters =>
      description != null ? {'description': description} : {};
}

class IsMinLength extends PropertyConstraint {
  final int length;

  /// Optional description for documentation or error message customization
  final String? description;

  const IsMinLength(this.length, {this.description});

  @override
  String get constraintKey => 'minLength';

  @override
  Map<String, Object?> get parameters => {
        'length': length,
        if (description != null) 'description': description,
      };
}

/// @deprecated Use IsMinLength instead for consistent naming
@Deprecated('Use IsMinLength instead for consistent naming')
class MinLength extends IsMinLength {
  const MinLength(super.length);
}

class IsMaxLength extends PropertyConstraint {
  final int length;

  /// Optional description for documentation or error message customization
  final String? description;

  const IsMaxLength(this.length, {this.description});

  @override
  String get constraintKey => 'maxLength';

  @override
  Map<String, Object?> get parameters => {
        'length': length,
        if (description != null) 'description': description,
      };
}

/// @deprecated Use IsMaxLength instead for consistent naming
@Deprecated('Use IsMaxLength instead for consistent naming')
class MaxLength extends IsMaxLength {
  const MaxLength(super.length);
}

class IsPattern extends PropertyConstraint {
  final String pattern;

  /// Optional description for documentation or error message customization
  final String? description;

  const IsPattern(this.pattern, {this.description});

  @override
  String get constraintKey => 'pattern';

  @override
  Map<String, Object?> get parameters => {
        'pattern': pattern,
        if (description != null) 'description': description,
      };
}

/// @deprecated Use IsPattern instead for consistent naming
@Deprecated('Use IsPattern instead for consistent naming')
class Pattern extends IsPattern {
  const Pattern(super.pattern);
}

class IsNotEmpty extends PropertyConstraint {
  /// Optional description for documentation or error message customization
  final String? description;

  const IsNotEmpty({this.description});

  @override
  String get constraintKey => 'notEmpty';

  @override
  Map<String, Object?> get parameters =>
      description != null ? {'description': description} : {};
}

class IsEnumValues extends PropertyConstraint {
  final List<String> values;

  /// Optional description for documentation or error message customization
  final String? description;

  const IsEnumValues(this.values, {this.description});

  @override
  String get constraintKey => 'enumValues';

  @override
  Map<String, Object?> get parameters => {
        'values': values,
        if (description != null) 'description': description,
      };
}

/// @deprecated Use IsEnumValues instead for consistent naming
@Deprecated('Use IsEnumValues instead for consistent naming')
class EnumValues extends IsEnumValues {
  const EnumValues(super.values);
}

// Number constraints
class IsMin extends PropertyConstraint {
  final num value;

  /// Optional description for documentation or error message customization
  final String? description;

  const IsMin(this.value, {this.description});

  @override
  String get constraintKey => 'min';

  @override
  Map<String, Object?> get parameters => {
        'value': value,
        if (description != null) 'description': description,
      };
}

/// @deprecated Use IsMin instead for consistent naming
@Deprecated('Use IsMin instead for consistent naming')
class Min extends IsMin {
  const Min(super.value);
}

class IsMax extends PropertyConstraint {
  final num value;

  /// Optional description for documentation or error message customization
  final String? description;

  const IsMax(this.value, {this.description});

  @override
  String get constraintKey => 'max';

  @override
  Map<String, Object?> get parameters => {
        'value': value,
        if (description != null) 'description': description,
      };
}

/// @deprecated Use IsMax instead for consistent naming
@Deprecated('Use IsMax instead for consistent naming')
class Max extends IsMax {
  const Max(super.value);
}

class IsMultipleOf extends PropertyConstraint {
  final num value;

  /// Optional description for documentation or error message customization
  final String? description;

  const IsMultipleOf(this.value, {this.description});

  @override
  String get constraintKey => 'multipleOf';

  @override
  Map<String, Object?> get parameters => {
        'value': value,
        if (description != null) 'description': description,
      };
}

/// @deprecated Use IsMultipleOf instead for consistent naming
@Deprecated('Use IsMultipleOf instead for consistent naming')
class MultipleOf extends IsMultipleOf {
  const MultipleOf(super.value);
}

/// Validates that a number is positive (greater than 0)
class IsPositive extends PropertyConstraint {
  /// Optional description for documentation or error message customization
  final String? description;

  const IsPositive({this.description});

  @override
  String get constraintKey => 'positive';

  @override
  Map<String, Object?> get parameters =>
      description != null ? {'description': description} : {};
}

/// Validates that a number is negative (less than 0)
class IsNegative extends PropertyConstraint {
  /// Optional description for documentation or error message customization
  final String? description;

  const IsNegative({this.description});

  @override
  String get constraintKey => 'negative';

  @override
  Map<String, Object?> get parameters =>
      description != null ? {'description': description} : {};
}

/// Validates that a string is a valid date in YYYY-MM-DD format
class IsDate extends PropertyConstraint {
  /// Optional description for documentation or error message customization
  final String? description;

  const IsDate({this.description});

  @override
  String get constraintKey => 'date';

  @override
  Map<String, Object?> get parameters =>
      description != null ? {'description': description} : {};
}

/// Validates that a string is a valid date-time in ISO 8601 format
class IsDateTime extends PropertyConstraint {
  /// Optional description for documentation or error message customization
  final String? description;

  const IsDateTime({this.description});

  @override
  String get constraintKey => 'dateTime';

  @override
  Map<String, Object?> get parameters =>
      description != null ? {'description': description} : {};
}

// List constraints
class IsMinItems extends PropertyConstraint {
  final int count;

  /// Optional description for documentation or error message customization
  final String? description;

  const IsMinItems(this.count, {this.description});

  @override
  String get constraintKey => 'minItems';

  @override
  Map<String, Object?> get parameters => {
        'count': count,
        if (description != null) 'description': description,
      };
}

/// @deprecated Use IsMinItems instead for consistent naming
@Deprecated('Use IsMinItems instead for consistent naming')
class MinItems extends IsMinItems {
  const MinItems(super.count);
}

class IsMaxItems extends PropertyConstraint {
  final int count;

  /// Optional description for documentation or error message customization
  final String? description;

  const IsMaxItems(this.count, {this.description});

  @override
  String get constraintKey => 'maxItems';

  @override
  Map<String, Object?> get parameters => {
        'count': count,
        if (description != null) 'description': description,
      };
}

/// @deprecated Use IsMaxItems instead for consistent naming
@Deprecated('Use IsMaxItems instead for consistent naming')
class MaxItems extends IsMaxItems {
  const MaxItems(super.count);
}

class IsUniqueItems extends PropertyConstraint {
  /// Optional description for documentation or error message customization
  final String? description;

  const IsUniqueItems({this.description});

  @override
  String get constraintKey => 'uniqueItems';

  @override
  Map<String, Object?> get parameters =>
      description != null ? {'description': description} : {};
}

/// @deprecated Use IsUniqueItems instead for consistent naming
@Deprecated('Use IsUniqueItems instead for consistent naming')
class UniqueItems extends IsUniqueItems {
  const UniqueItems();
}

// Object field type annotation
// Use this only when type inference might not work correctly
class FieldType extends PropertyConstraint {
  final Type type;

  const FieldType(this.type);

  @override
  String get constraintKey => 'fieldType';

  @override
  Map<String, Object?> get parameters => {'type': type.toString()};
}
