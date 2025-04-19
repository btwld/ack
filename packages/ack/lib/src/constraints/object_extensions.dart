import '../schemas/schema.dart';
import 'constraint.dart';
import 'validators.dart';

/// Extension methods for [ObjectSchema] to provide additional validation capabilities.
extension ObjectSchemaExtensions on ObjectSchema {
  /// {@macro object_min_properties_validator}
  /// Example:
  /// ```dart
  /// final schema = Ack.object({
  ///   'id': Ack.string(),
  ///   'name': Ack.string(),
  /// }).minProperties(1);
  /// ```
  ObjectSchema minProperties(int min) {
    return withConstraints([ObjectMinPropertiesConstraint(min: min)]);
  }

  /// {@macro object_max_properties_validator}
  /// Example:
  /// ```dart
  /// final schema = Ack.object({
  ///   'id': Ack.string(),
  ///   'name': Ack.string(),
  /// }).maxProperties(3);
  /// ```
  ObjectSchema maxProperties(int max) {
    return withConstraints([ObjectMaxPropertiesConstraint(max: max)]);
  }
  
  /// Validates that an object has exactly the specified number of properties.
  /// 
  /// Example:
  /// ```dart
  /// final pointSchema = Ack.object({
  ///   'x': Ack.double,
  ///   'y': Ack.double,
  /// }).exactProperties(2);
  /// ```
  ObjectSchema exactProperties(int count) {
    return minProperties(count).maxProperties(count);
  }
}
