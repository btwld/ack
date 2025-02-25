part of '../../ack_base.dart';

final class BooleanSchema extends Schema<bool>
    with SchemaFluentMethods<BooleanSchema, bool> {
  const BooleanSchema({
    super.nullable,
    super.constraints,
    super.strict,
    super.description,
  });

  @override
  BooleanSchema copyWith({
    bool? nullable,
    List<ConstraintValidator<bool>>? constraints,
    bool? strict,
    String? description,
  }) {
    return BooleanSchema(
      nullable: nullable ?? _nullable,
      constraints: constraints ?? _constraints,
      strict: strict ?? _strict,
      description: description ?? _description,
    );
  }
}
