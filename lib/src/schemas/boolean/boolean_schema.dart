part of '../../ack.dart';

final class BooleanSchema extends ScalarSchema<BooleanSchema, bool> {
  @override
  final builder = BooleanSchema.new;

  const BooleanSchema({
    super.nullable,
    super.constraints,
    super.strict,
    super.description,
    super.defaultValue,
  }) : super(type: SchemaType.boolean);
}
