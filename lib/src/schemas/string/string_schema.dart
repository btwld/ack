part of '../../ack.dart';

final class StringSchema extends ScalarSchema<StringSchema, String> {
  @override
  final builder = StringSchema.new;

  const StringSchema({
    super.nullable,
    super.constraints,
    super.strict,
    super.description,
    super.defaultValue,
  }) : super(type: SchemaType.string);
}
