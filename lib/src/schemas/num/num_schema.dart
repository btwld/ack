part of '../../ack_base.dart';

final class DoubleSchema extends Schema<double>
    with SchemaFluentMethods<DoubleSchema, double> {
  const DoubleSchema({
    super.nullable,
    super.constraints,
    super.strict,
    super.description,
  });

  @override
  DoubleSchema copyWith({
    bool? nullable,
    List<ConstraintValidator<double>>? constraints,
    bool? strict,
    String? description,
  }) {
    return DoubleSchema(
      nullable: nullable ?? _nullable,
      constraints: constraints ?? _constraints,
      strict: strict ?? _strict,
      description: description ?? _description,
    );
  }
}

final class IntSchema extends Schema<int>
    with SchemaFluentMethods<IntSchema, int> {
  const IntSchema({
    super.nullable,
    super.constraints,
    super.strict,
    super.description,
  });

  @override
  IntSchema copyWith({
    bool? nullable,
    List<ConstraintValidator<int>>? constraints,
    bool? strict,
    String? description,
  }) {
    return IntSchema(
      nullable: nullable ?? _nullable,
      constraints: constraints ?? _constraints,
      strict: strict ?? _strict,
      description: description ?? _description,
    );
  }
}

extension IntSchemaExt on IntSchema {
  IntSchema maxValue(int max) => withConstraints([MaxValueValidator<int>(max)]);

  IntSchema minValue(int min) => withConstraints([MinValueValidator<int>(min)]);

  IntSchema range(int min, int max) =>
      withConstraints([RangeValidator<int>(min, max)]);
}

extension DoubleSchemaExt on DoubleSchema {
  DoubleSchema maxValue(double max) =>
      withConstraints([MaxValueValidator<double>(max)]);

  DoubleSchema minValue(double min) =>
      withConstraints([MinValueValidator<double>(min)]);

  DoubleSchema range(double min, double max) =>
      withConstraints([RangeValidator<double>(min, max)]);
}
