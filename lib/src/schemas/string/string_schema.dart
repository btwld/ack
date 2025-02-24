part of '../../ack_base.dart';

final class StringSchema extends Schema<String> {
  const StringSchema({super.nullable, super.constraints, super.strict});

  @override
  StringSchema copyWith({
    bool? nullable,
    List<ConstraintValidator<String>>? constraints,
    bool? strict,
  }) {
    return StringSchema(
      nullable: nullable ?? _nullable,
      constraints: constraints ?? _constraints,
      strict: strict ?? _strict,
    );
  }
}

extension StringSchemaExt<S extends Schema<String>> on S {
  S isEmail() => copyWith(constraints: [const EmailValidator()]) as S;

  S isHexColor() => copyWith(constraints: [const HexColorValidator()]) as S;

  S isEmpty() => copyWith(constraints: [const IsEmptyValidator()]) as S;

  S minLength(int min) => copyWith(constraints: [MinLengthValidator(min)]) as S;

  S maxLength(int max) => copyWith(constraints: [MaxLengthValidator(max)]) as S;

  S oneOf(List<String> values) =>
      copyWith(constraints: [OneOfValidator(values)]) as S;

  S notOneOf(List<String> values) =>
      copyWith(constraints: [NotOneOfValidator(values)]) as S;

  S isEnum(List<String> values) =>
      copyWith(constraints: [EnumValidator(values)]) as S;

  S isNotEmpty() => copyWith(constraints: [const NotEmptyValidator()]) as S;

  S isDateTime() => copyWith(constraints: [const DateTimeValidator()]) as S;
}
