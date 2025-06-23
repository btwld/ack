part of 'schema.dart';

final class DateSchema extends ScalarSchema<DateSchema, DateTime> {
  @override
  final builder = DateSchema.new;

  const DateSchema({
    super.nullable,
    super.constraints,
    super.strict,
    super.description,
    super.defaultValue,
  }) : super(type: SchemaType.date);

  @override
  DateTime? _tryConvertType(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (!_strict) {
      if (value is String) {
        return DateTime.tryParse(value);
      }
    }
    return null;
  }
}
