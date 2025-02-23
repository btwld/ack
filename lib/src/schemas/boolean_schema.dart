part of '../ack_base.dart';

final class BooleanSchema extends Schema<BooleanSchema, bool> {
  const BooleanSchema({super.nullable, super.constraints});

  @override
  bool? _tryParse(Object value) {
    if (value is bool) return value;
    if (value is String) return bool.tryParse(value);

    return null;
  }

  @override
  BooleanSchema copyWith({
    bool? nullable,
    List<ConstraintsValidator<bool>>? constraints,
  }) {
    return BooleanSchema(
      nullable: nullable ?? _nullable,
      constraints: constraints ?? _constraints,
    );
  }
}
