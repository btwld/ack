import 'package:ack/ack.dart';
import 'package:meta/meta_meta.dart';

/// Controls how constructor parameter names are converted into schema keys.
enum CaseStyle { none, camelCase, pascalCase, snakeCase, paramCase }

/// Marks a class as schema-generating using its constructor contract.
@Target({TargetKind.classType})
class Schemable {
  /// Optional custom schema class name.
  final String? schemaName;

  /// Optional description for the schema.
  final String? description;

  /// Whether to allow additional properties not defined in the schema.
  final bool additionalProperties;

  /// The field that stores additional properties on the model.
  final String? additionalPropertiesField;

  /// Discriminator key for sealed union roots.
  final String? discriminatorKey;

  /// Discriminator value for concrete union leaves.
  final String? discriminatorValue;

  /// Case style to apply to parameter names before schema generation.
  final CaseStyle caseStyle;

  /// Explicit compile-time schema providers for custom types without generated schemas.
  final List<Type> useProviders;

  const Schemable({
    this.schemaName,
    this.description,
    this.additionalProperties = false,
    this.additionalPropertiesField,
    this.discriminatorKey,
    this.discriminatorValue,
    this.caseStyle = CaseStyle.none,
    this.useProviders = const [],
  }) : assert(
         discriminatorKey == null || discriminatorValue == null,
         'discriminatorKey and discriminatorValue cannot be used together',
       );
}

/// Convenience constant for the default schemable configuration.
const schemable = Schemable();

/// Marks the constructor that defines the schema contract.
@Target({TargetKind.constructor})
class SchemaConstructor {
  const SchemaConstructor();
}

/// Overrides the generated schema key for a constructor parameter.
@Target({TargetKind.parameter})
class SchemaKey {
  final String name;

  const SchemaKey(this.name);
}

/// Attaches human-readable schema documentation to a constructor parameter.
@Target({TargetKind.parameter})
class Description {
  final String value;

  const Description(this.value);
}

/// Compile-time contract for explicit custom type-schema providers.
///
/// Register provider types through `@Schemable(useProviders: const [...])`
/// when a constructor parameter uses a custom type that is not itself
/// schemable. Providers may compose generated schemas internally, but the
/// provider target type itself must not be `@Schemable()`.
abstract interface class SchemaProvider<T extends Object> {
  const SchemaProvider();

  AckSchema<T> get schema;
}
