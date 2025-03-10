part of '../schema.dart';

final class DoubleSchema extends NumSchema<double> {
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

final class IntegerSchema extends NumSchema<int> {
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

sealed class NumSchema<T extends num> extends ScalarSchema<NumSchema<T>, T> {
  const NumSchema({
    super.nullable,
    super.constraints,
    super.strict,
    super.description,
    super.defaultValue,
    required super.type,
  });
}
