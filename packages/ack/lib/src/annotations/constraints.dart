import 'package:meta/meta_meta.dart';

/// Base type of the Ack rule annotations, such as [HasMinLength] and
/// [IsEmail].
///
/// `ack_generator` reads rules by their type. Write the concrete rule
/// annotations; do not use this type directly.
///
/// ```dart
/// @Schemable()
/// final class User({
///   @IsEmail() required final String email,
///   @HasMinLength(2) required final String name,
/// }) with _$UserAck {
///   static final schema = UserSchema.schema;
/// }
/// ```
///
/// [Validate.kind] and [Validate.value] stay visible on every rule until
/// [Validate] is deleted. Redirecting factories require this subtype, so
/// those fields cannot be dropped earlier.
// ignore: deprecated_member_use_from_same_package
abstract final class AckRule extends Validate {
  const AckRule._(String kind, [Object? value]) : super._(kind, value);
}

/// Marks a class-first field as optional on the JSON wire.
///
/// The JSON key may be omitted. This does not change whether a present JSON
/// value may be `null`: a nullable Dart type still accepts JSON `null`, and
/// [IsNotNull] rejects it. Valid only when the constructor can accept a
/// missing value, with a discriminator-specific exception for union branches.
///
/// On a parameter with a default value, this replaces the inferred
/// `.withDefault(...)` with `.optional()`: a missing key still receives the
/// constructor default, but JSON `null` is rejected for a non-nullable type
/// and the exported JSON Schema has no `default`.
@Target({TargetKind.field, TargetKind.parameter})
final class IsOptional extends AckRule {
  const IsOptional() : super._('optional');
}

/// Marks a class-first field as required on the JSON wire.
///
/// The JSON key must be present. This does not change Dart nullability.
@Target({TargetKind.field, TargetKind.parameter})
final class IsRequired extends AckRule {
  const IsRequired() : super._('required');
}

/// Rejects an explicit JSON `null` without requiring the key to exist.
///
/// Needed only when the Dart type is nullable (`T?`) or `JsonMaybe<T>` but a
/// present JSON value must not be `null`. Non-nullable Dart fields already
/// reject JSON `null`. Dart nullability is unchanged: an omitted optional key
/// still becomes `null` on a nullable field, and encoding omits a null Dart
/// value.
@Target({TargetKind.field, TargetKind.parameter})
final class IsNotNull extends AckRule {
  const IsNotNull() : super._('notNull');
}

/// Adds `.min(min)` to an inferred numeric schema.
@Target({TargetKind.field, TargetKind.parameter})
final class HasMin extends AckRule {
  /// The inclusive lower bound.
  final num min;

  const HasMin(this.min) : super._('min', min);
}

/// Adds `.max(max)` to an inferred numeric schema.
@Target({TargetKind.field, TargetKind.parameter})
final class HasMax extends AckRule {
  /// The inclusive upper bound.
  final num max;

  const HasMax(this.max) : super._('max', max);
}

/// Adds `.multipleOf(divisor)` to an inferred numeric schema.
@Target({TargetKind.field, TargetKind.parameter})
final class IsMultipleOf extends AckRule {
  /// The number that must divide the value.
  final num divisor;

  const IsMultipleOf(this.divisor) : super._('multipleOf', divisor);
}

/// Adds `.positive()` to an inferred numeric schema.
@Target({TargetKind.field, TargetKind.parameter})
final class IsPositive extends AckRule {
  const IsPositive() : super._('positive');
}

/// Adds `.negative()` to an inferred numeric schema.
@Target({TargetKind.field, TargetKind.parameter})
final class IsNegative extends AckRule {
  const IsNegative() : super._('negative');
}

/// Adds `.minLength(length)` to an inferred string schema.
@Target({TargetKind.field, TargetKind.parameter})
final class HasMinLength extends AckRule {
  /// The minimum number of characters.
  final int length;

  const HasMinLength(this.length) : super._('minLength', length);
}

/// Adds `.maxLength(length)` to an inferred string schema.
@Target({TargetKind.field, TargetKind.parameter})
final class HasMaxLength extends AckRule {
  /// The maximum number of characters.
  final int length;

  const HasMaxLength(this.length) : super._('maxLength', length);
}

/// Adds `.matches(pattern)` to an inferred string schema.
///
/// Like `.matches()`, the pattern may match anywhere in the value. Anchor it
/// with `^` and `$` to match the whole value.
@Target({TargetKind.field, TargetKind.parameter})
final class HasMatch extends AckRule {
  /// The regular expression source.
  final String pattern;

  const HasMatch(this.pattern) : super._('matches', pattern);
}

/// Adds `.notEmpty()` to an inferred string or collection (`List` / `Set`)
/// schema.
@Target({TargetKind.field, TargetKind.parameter})
final class IsNotEmpty extends AckRule {
  const IsNotEmpty() : super._('notEmpty');
}

/// Adds `.email()` to an inferred string schema.
@Target({TargetKind.field, TargetKind.parameter})
final class IsEmail extends AckRule {
  const IsEmail() : super._('email');
}

/// Adds `.url()` to an inferred string schema.
@Target({TargetKind.field, TargetKind.parameter})
final class IsUrl extends AckRule {
  const IsUrl() : super._('url');
}

/// Adds `.uri()` to an inferred string schema.
@Target({TargetKind.field, TargetKind.parameter})
final class IsUri extends AckRule {
  const IsUri() : super._('uri');
}

/// Adds `.uuid()` to an inferred string schema.
@Target({TargetKind.field, TargetKind.parameter})
final class IsUuid extends AckRule {
  const IsUuid() : super._('uuid');
}

/// Adds `.date()` to an inferred string schema.
@Target({TargetKind.field, TargetKind.parameter})
final class IsDate extends AckRule {
  const IsDate() : super._('date');
}

/// Adds `.datetime()` to an inferred string schema.
@Target({TargetKind.field, TargetKind.parameter})
final class IsDateTime extends AckRule {
  const IsDateTime() : super._('dateTime');
}

/// Adds `.ip()` to an inferred string schema, or `.ip(version: version)`
/// when [version] is set.
@Target({TargetKind.field, TargetKind.parameter})
final class IsIp extends AckRule {
  /// The IP version, `4` or `6`; `null` accepts either.
  final int? version;

  const IsIp({this.version}) : super._('ip', version);

  // Back the deprecated `Validate.ipv4()` and `Validate.ipv6()`, keeping their
  // original `kind` and `value`.
  const IsIp._ipv4() : version = 4, super._('ipv4');

  const IsIp._ipv6() : version = 6, super._('ipv6');
}

/// Adds `.minItems(count)` to an inferred collection schema.
@Target({TargetKind.field, TargetKind.parameter})
final class HasMinItems extends AckRule {
  /// The minimum number of items.
  final int count;

  const HasMinItems(this.count) : super._('minItems', count);
}

/// Adds `.maxItems(count)` to an inferred collection schema.
@Target({TargetKind.field, TargetKind.parameter})
final class HasMaxItems extends AckRule {
  /// The maximum number of items.
  final int count;

  const HasMaxItems(this.count) : super._('maxItems', count);
}

/// Adds `.unique()` to an inferred collection schema.
@Target({TargetKind.field, TargetKind.parameter})
final class HasUniqueItems extends AckRule {
  const HasUniqueItems() : super._('uniqueItems');
}

/// Deprecated namespace for the Ack rule annotations.
///
/// Each constructor returns the matching rule annotation, so
/// `@Validate.minLength(3)` is the same value as `@HasMinLength(3)`. Use the
/// rule annotations instead. `Validate` is removed before Ack 2.0.0.
@Deprecated(
  'Use the Is and Has rule annotations instead. '
  'Validate is removed before Ack 2.0.0.',
)
@Target({TargetKind.field, TargetKind.parameter})
final class Validate {
  /// The constraint identifier.
  @Deprecated(
    'Read the rule annotation type instead. '
    'Validate is removed before Ack 2.0.0.',
  )
  final String kind;

  /// The constraint argument (`num`, `int`, or `String`), if any.
  @Deprecated(
    'Read the rule annotation field instead. '
    'Validate is removed before Ack 2.0.0.',
  )
  final Object? value;

  const Validate._(this.kind, this.value);

  /// Returns [IsOptional].
  @Deprecated('Use @IsOptional instead. Validate is removed before Ack 2.0.0.')
  const factory Validate.optional() = IsOptional;

  /// Returns [IsRequired].
  @Deprecated('Use @IsRequired instead. Validate is removed before Ack 2.0.0.')
  const factory Validate.required() = IsRequired;

  /// Returns [IsNotNull].
  @Deprecated('Use @IsNotNull instead. Validate is removed before Ack 2.0.0.')
  const factory Validate.notNull() = IsNotNull;

  /// Returns [HasMin].
  @Deprecated('Use @HasMin instead. Validate is removed before Ack 2.0.0.')
  const factory Validate.min(num value) = HasMin;

  /// Returns [HasMax].
  @Deprecated('Use @HasMax instead. Validate is removed before Ack 2.0.0.')
  const factory Validate.max(num value) = HasMax;

  /// Returns [IsMultipleOf].
  @Deprecated(
    'Use @IsMultipleOf instead. Validate is removed before Ack 2.0.0.',
  )
  const factory Validate.multipleOf(num value) = IsMultipleOf;

  /// Returns [IsPositive].
  @Deprecated('Use @IsPositive instead. Validate is removed before Ack 2.0.0.')
  const factory Validate.positive() = IsPositive;

  /// Returns [IsNegative].
  @Deprecated('Use @IsNegative instead. Validate is removed before Ack 2.0.0.')
  const factory Validate.negative() = IsNegative;

  /// Returns [HasMinLength].
  @Deprecated(
    'Use @HasMinLength instead. Validate is removed before Ack 2.0.0.',
  )
  const factory Validate.minLength(int length) = HasMinLength;

  /// Returns [HasMaxLength].
  @Deprecated(
    'Use @HasMaxLength instead. Validate is removed before Ack 2.0.0.',
  )
  const factory Validate.maxLength(int length) = HasMaxLength;

  /// Returns [HasMatch].
  @Deprecated('Use @HasMatch instead. Validate is removed before Ack 2.0.0.')
  const factory Validate.matches(String pattern) = HasMatch;

  /// Returns [IsNotEmpty].
  @Deprecated('Use @IsNotEmpty instead. Validate is removed before Ack 2.0.0.')
  const factory Validate.notEmpty() = IsNotEmpty;

  /// Returns [IsEmail].
  @Deprecated('Use @IsEmail instead. Validate is removed before Ack 2.0.0.')
  const factory Validate.email() = IsEmail;

  /// Returns [IsUrl].
  @Deprecated('Use @IsUrl instead. Validate is removed before Ack 2.0.0.')
  const factory Validate.url() = IsUrl;

  /// Returns [IsUri].
  @Deprecated('Use @IsUri instead. Validate is removed before Ack 2.0.0.')
  const factory Validate.uri() = IsUri;

  /// Returns [IsUuid].
  @Deprecated('Use @IsUuid instead. Validate is removed before Ack 2.0.0.')
  const factory Validate.uuid() = IsUuid;

  /// Returns [IsDate].
  @Deprecated('Use @IsDate instead. Validate is removed before Ack 2.0.0.')
  const factory Validate.date() = IsDate;

  /// Returns [IsDateTime].
  @Deprecated('Use @IsDateTime instead. Validate is removed before Ack 2.0.0.')
  const factory Validate.dateTime() = IsDateTime;

  /// Returns [IsIp].
  @Deprecated('Use @IsIp instead. Validate is removed before Ack 2.0.0.')
  const factory Validate.ip({int? version}) = IsIp;

  /// Returns `IsIp(version: 4)`.
  @Deprecated(
    'Use @IsIp(version: 4) instead. Validate is removed before Ack 2.0.0.',
  )
  const factory Validate.ipv4() = IsIp._ipv4;

  /// Returns `IsIp(version: 6)`.
  @Deprecated(
    'Use @IsIp(version: 6) instead. Validate is removed before Ack 2.0.0.',
  )
  const factory Validate.ipv6() = IsIp._ipv6;

  /// Returns [HasMinItems].
  @Deprecated('Use @HasMinItems instead. Validate is removed before Ack 2.0.0.')
  const factory Validate.minItems(int count) = HasMinItems;

  /// Returns [HasMaxItems].
  @Deprecated('Use @HasMaxItems instead. Validate is removed before Ack 2.0.0.')
  const factory Validate.maxItems(int count) = HasMaxItems;

  /// Returns [HasUniqueItems].
  @Deprecated(
    'Use @HasUniqueItems instead. Validate is removed before Ack 2.0.0.',
  )
  const factory Validate.uniqueItems() = HasUniqueItems;
}
