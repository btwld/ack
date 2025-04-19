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

  const Schema({
    this.description,
    this.additionalProperties = false,
    this.additionalPropertiesField,
    this.schemaClassName,
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
class Required extends PropertyConstraint {
  const Required();

  @override
  String get constraintKey => 'required';

  @override
  Map<String, Object?> get parameters => {};
}

/// Mark a property as nullable in the schema
class Nullable extends PropertyConstraint {
  const Nullable();

  @override
  String get constraintKey => 'nullable';

  @override
  Map<String, Object?> get parameters => {};
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
  const IsEmail();

  @override
  String get constraintKey => 'isEmail';

  @override
  Map<String, Object?> get parameters => {};
}

class MinLength extends PropertyConstraint {
  final int length;

  const MinLength(this.length);

  @override
  String get constraintKey => 'minLength';

  @override
  Map<String, Object?> get parameters => {'length': length};
}

class MaxLength extends PropertyConstraint {
  final int length;

  const MaxLength(this.length);

  @override
  String get constraintKey => 'maxLength';

  @override
  Map<String, Object?> get parameters => {'length': length};
}

class Pattern extends PropertyConstraint {
  final String pattern;

  const Pattern(this.pattern);

  @override
  String get constraintKey => 'pattern';

  @override
  Map<String, Object?> get parameters => {'pattern': pattern};
}

class IsNotEmpty extends PropertyConstraint {
  const IsNotEmpty();

  @override
  String get constraintKey => 'isNotEmpty';

  @override
  Map<String, Object?> get parameters => {};
}

class EnumValues extends PropertyConstraint {
  final List<String> values;

  const EnumValues(this.values);

  @override
  String get constraintKey => 'enumValues';

  @override
  Map<String, Object?> get parameters => {'values': values};
}

// Number constraints
class Min extends PropertyConstraint {
  final num value;

  const Min(this.value);

  @override
  String get constraintKey => 'min';

  @override
  Map<String, Object?> get parameters => {'value': value};
}

class Max extends PropertyConstraint {
  final num value;

  const Max(this.value);

  @override
  String get constraintKey => 'max';

  @override
  Map<String, Object?> get parameters => {'value': value};
}

class MultipleOf extends PropertyConstraint {
  final num value;

  const MultipleOf(this.value);

  @override
  String get constraintKey => 'multipleOf';

  @override
  Map<String, Object?> get parameters => {'value': value};
}

// List constraints
class MinItems extends PropertyConstraint {
  final int count;

  const MinItems(this.count);

  @override
  String get constraintKey => 'minItems';

  @override
  Map<String, Object?> get parameters => {'count': count};
}

class MaxItems extends PropertyConstraint {
  final int count;

  const MaxItems(this.count);

  @override
  String get constraintKey => 'maxItems';

  @override
  Map<String, Object?> get parameters => {'count': count};
}

class UniqueItems extends PropertyConstraint {
  const UniqueItems();

  @override
  String get constraintKey => 'uniqueItems';

  @override
  Map<String, Object?> get parameters => {};
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
