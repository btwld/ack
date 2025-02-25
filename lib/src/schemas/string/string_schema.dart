part of '../../ack_base.dart';

final class StringSchema extends Schema<String>
    with SchemaFluentMethods<StringSchema, String> {
  const StringSchema(
      {super.nullable, super.constraints, super.strict, super.description});

  @override
  StringSchema copyWith({
    bool? nullable,
    List<ConstraintValidator<String>>? constraints,
    bool? strict,
    String? description,
  }) {
    return StringSchema(
      nullable: nullable ?? _nullable,
      constraints: constraints ?? _constraints,
      strict: strict ?? _strict,
      description: description ?? _description,
    );
  }
}

extension StringSchemaExt on StringSchema {
  StringSchema isEmail() => withConstraints([const EmailValidator()]);

  StringSchema isHexColor() => withConstraints([const HexColorValidator()]);

  StringSchema isEmpty() => withConstraints([const IsEmptyValidator()]);

  StringSchema minLength(int min) => withConstraints([MinLengthValidator(min)]);

  StringSchema maxLength(int max) => withConstraints([MaxLengthValidator(max)]);

  StringSchema oneOf(List<String> values) =>
      withConstraints([OneOfValidator(values)]);

  StringSchema notOneOf(List<String> values) =>
      withConstraints([NotOneOfValidator(values)]);

  StringSchema isEnum(List<String> values) =>
      withConstraints([EnumValidator(values)]);

  StringSchema isNotEmpty() => withConstraints([const NotEmptyValidator()]);

  StringSchema isDateTime() => withConstraints([const DateTimeValidator()]);
}
