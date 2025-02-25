part of '../../ack.dart';

/// Schema for validating boolean values
///
/// BooleanSchema validates boolean data and supports:
/// - Nullability via [nullable]
/// - Default values via [defaultValue]
/// - Strict parsing via [strict]
/// - Custom descriptions via [description]
final class BooleanSchema extends ScalarSchema<BooleanSchema, bool> {
  /// Builder function to create new instances
  @override
  final builder = BooleanSchema.new;

  /// Creates a new BooleanSchema
  ///
  /// Parameters:
  /// - [nullable] - Whether null values are allowed
  /// - [constraints] - Additional validation constraints
  /// - [strict] - Whether to use strict parsing
  /// - [description] - Schema description
  /// - [defaultValue] - Default value if none provided
  const BooleanSchema({
    super.nullable,
    super.constraints,
    super.strict,
    super.description,
    super.defaultValue,
  }) : super(type: SchemaType.boolean);
}
