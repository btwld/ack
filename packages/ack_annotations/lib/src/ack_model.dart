import 'package:meta/meta_meta.dart';

/// Annotation to mark a class for schema generation.
///
/// This annotation can be used in two main ways:
///
/// ## Regular Models
/// Generate schema validation for a single class:
/// ```dart
/// @AckModel()
/// class User {
///   final String name;
///   final int age;
///   User({required this.name, required this.age});
/// }
/// ```
///
/// ## Discriminated Types (Polymorphic Models)
/// Generate discriminated schemas for inheritance hierarchies:
///
/// ### Base Class (Abstract)
/// Use [discriminatedKey] to specify the field that determines the type:
/// ```dart
/// @AckModel(discriminatedKey: 'type')
/// abstract class Animal {
///   String get type;
/// }
/// ```
///
/// ### Concrete Implementations
/// Use [discriminatedValue] to specify this class's discriminator value:
/// ```dart
/// @AckModel(discriminatedValue: 'cat')
/// class Cat extends Animal {
///   @override
///   String get type => 'cat';
///   final bool meow;
///   Cat({required this.meow});
/// }
///
/// @AckModel(discriminatedValue: 'dog')
/// class Dog extends Animal {
///   @override
///   String get type => 'dog';
///   final bool bark;
///   Dog({required this.bark});
/// }
/// ```
///
/// This generates:
/// ```dart
/// final animalSchema = Ack.discriminated(
///   discriminatorKey: 'type',
///   schemas: {
///     'cat': catSchema,
///     'dog': dogSchema,
///   },
/// );
/// ```
@Target({TargetKind.classType})
class AckModel {
  /// Optional custom schema class name
  final String? schemaName;

  /// Optional description for the schema
  final String? description;

  /// Whether to allow additional properties not defined in the schema
  final bool additionalProperties;

  /// The name of the field that should store additional properties
  /// Must be a `Map<String, dynamic>` field in your class
  final String? additionalPropertiesField;

  /// Whether to generate a SchemaModel class in addition to the schema variable
  /// When true, generates both:
  /// - Schema variable (e.g., productSchema)
  /// - SchemaModel class (e.g., ProductSchemaModel)
  final bool model;

  /// Field name to use for discriminating between types in a polymorphic hierarchy.
  /// Use this on abstract/base classes to indicate which field contains the type discriminator.
  /// Example: @AckModel(discriminatedKey: 'type')
  /// Cannot be used together with [discriminatedValue].
  final String? discriminatedKey;

  /// The discriminator value this class represents in a polymorphic hierarchy.
  /// Use this on concrete classes that extend an abstract class with [discriminatedKey].
  /// Example: @AckModel(discriminatedValue: 'cat')
  /// Cannot be used together with [discriminatedKey].
  final String? discriminatedValue;

  const AckModel({
    this.schemaName,
    this.description,
    this.additionalProperties = false,
    this.additionalPropertiesField,
    this.model = false,
    this.discriminatedKey,
    this.discriminatedValue,
  }) : assert(
          discriminatedKey == null || discriminatedValue == null,
          'discriminatedKey and discriminatedValue cannot be used together',
        );
}
