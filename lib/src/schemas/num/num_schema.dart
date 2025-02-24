part of '../../ack_base.dart';

final class DoubleSchema extends Schema<double> {
  const DoubleSchema({super.nullable, super.constraints, super.strict});

  @override
  DoubleSchema copyWith({
    bool? nullable,
    List<ConstraintValidator<double>>? constraints,
    bool? strict,
  }) {
    return DoubleSchema(
      nullable: nullable ?? _nullable,
      constraints: constraints ?? _constraints,
      strict: strict ?? _strict,
    );
  }
}

final class IntSchema extends Schema<int> {
  const IntSchema({super.nullable, super.constraints, super.strict});

  @override
  IntSchema copyWith({
    bool? nullable,
    List<ConstraintValidator<int>>? constraints,
    bool? strict,
  }) {
    return IntSchema(
      nullable: nullable ?? _nullable,
      constraints: constraints ?? _constraints,
      strict: strict ?? _strict,
    );
  }
}

extension DoubleSchemaExt<S extends Schema<double>> on S {
  S maxValue(num max) =>
      copyWith(constraints: [MaxValueValidator<double>(max)]) as S;

  S minValue(num min) =>
      copyWith(constraints: [MinValueValidator<double>(min)]) as S;

  S range(num min, num max) =>
      copyWith(constraints: [RangeValidator<double>(min, max)]) as S;
}

extension IntSchemaExt<S extends Schema<int>> on S {
  S maxValue(num max) =>
      copyWith(constraints: [MaxValueValidator<int>(max)]) as S;

  S minValue(num min) =>
      copyWith(constraints: [MinValueValidator<int>(min)]) as S;

  S range(num min, num max) =>
      copyWith(constraints: [RangeValidator<int>(min, max)]) as S;
}
