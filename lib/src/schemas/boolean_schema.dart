part of '../ack_base.dart';

final class BooleanSchema extends Schema<bool> {
  const BooleanSchema({super.nullable, super.constraints, super.strict});

  @override
  BooleanSchema copyWith({
    bool? nullable,
    List<ConstraintValidator<bool>>? constraints,
    bool? strict,
  }) {
    return BooleanSchema(
      nullable: nullable ?? _nullable,
      constraints: constraints ?? _constraints,
      strict: strict ?? _strict,
    );
  }
}
