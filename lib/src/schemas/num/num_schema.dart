part of '../schema.dart';

final class DoubleSchema extends ScalarSchema<DoubleSchema, double> {
  @override
  final builder = DoubleSchema.new;

  const DoubleSchema({
    super.nullable,
    super.constraints,
    super.strict,
    super.description,
    super.defaultValue,
  }) : super(type: SchemaType.double);
}

final class IntegerSchema extends ScalarSchema<IntegerSchema, int> {
  @override
  final builder = IntegerSchema.new;

  const IntegerSchema({
    super.nullable,
    super.constraints,
    super.strict,
    super.description,
    super.defaultValue,
  }) : super(type: SchemaType.int);
}
