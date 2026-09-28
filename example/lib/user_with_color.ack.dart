// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'user_with_color.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

/// Immutable value model generated from `colorSchema`.
@AckInfer.jsonSerializable
final class ColorModel {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  ColorModel(this.value);

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory ColorModel.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory ColorModel.fromJson(String json) {
    return $ack.parse(json);
  }

  /// The wrapped value.
  final Color value;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => colorSchema,
    fromRuntime: ColorModel._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<ColorModel> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  String toJson() => $ack.encode(this);

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<String> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $ColorModelCopyWith<ColorModel> get copyWith => _$ColorModelCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ColorModel &&
          runtimeType == other.runtimeType &&
          deepEquals(value, other.value));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(value)]);

  @override
  String toString() => 'ColorModel(value: $value)';

  static ColorModel _fromAckRuntime(Color value) =>
      _$ColorModelFromJson(<String, dynamic>{'value': value});

  Color _toAckRuntime() => _$ColorModelToJson(this)['value'] as Color;

  static Color _ackFromRuntimeValue(Object? value) => value as Color;

  static Object? _ackToRuntimeValue(Color value) => value;
}

/// Creates copies of [ColorModel] with selected fields replaced.
abstract interface class $ColorModelCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({Color? value});
}

final class _$ColorModelCopyWith implements $ColorModelCopyWith<ColorModel> {
  const _$ColorModelCopyWith(this._source);

  final ColorModel _source;

  @override
  ColorModel call({Color? value}) => ColorModel(value ?? _source.value);
}

/// Immutable model generated from `profileSchema`.
@AckInfer.jsonSerializable
final class Profile {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  Profile({required this.bio, this.website});

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Profile.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Profile.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String bio;

  final Uri? website;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => profileSchema,
    fromRuntime: Profile._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Profile> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $ProfileCopyWith<Profile> get copyWith => _$ProfileCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          runtimeType == other.runtimeType &&
          deepEquals(bio, other.bio) &&
          deepEquals(website, other.website));

  @override
  int get hashCode =>
      Object.hashAll([runtimeType, deepHashCode(bio), deepHashCode(website)]);

  @override
  String toString() => 'Profile(bio: $bio, website: $website)';

  static Profile _fromAckRuntime(Map<String, Object?> value) =>
      _$ProfileFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$ProfileToJson(this),
  };

  static String _ackFromRuntimeBio(Object? value) => value as String;

  static Object? _ackToRuntimeBio(String value) => value;

  static Uri? _ackFromRuntimeWebsite(Object? value) => value as Uri?;

  static Object? _ackToRuntimeWebsite(Uri? value) => value;
}

final class _ProfileCopyWithUnset {
  const _ProfileCopyWithUnset();
}

/// Creates copies of [Profile] with selected fields replaced.
abstract interface class $ProfileCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({String? bio, Uri? website});
}

final class _$ProfileCopyWith implements $ProfileCopyWith<Profile> {
  const _$ProfileCopyWith(this._source);

  static const _ProfileCopyWithUnset _ackCopyWithUnset =
      _ProfileCopyWithUnset();

  final Profile _source;

  @override
  Profile call({String? bio, Object? website = _ackCopyWithUnset}) => Profile(
    bio: bio ?? _source.bio,
    website: identical(website, _ackCopyWithUnset)
        ? _source.website
        : website as Uri?,
  );
}

/// Immutable model generated from `userWithColorSchema`.
@AckInfer.jsonSerializable
final class UserWithColor {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  UserWithColor({
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.profile,
    required this.color,
    this.favoriteColor,
    required this.pet,
    required List<Pet> pets,
  }) : pets = List<Pet>.unmodifiable(pets.map((item) => item));

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory UserWithColor.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory UserWithColor.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String firstName;

  final String lastName;

  final int age;

  final Profile profile;

  final ColorModel color;

  final ColorModel? favoriteColor;

  final Pet pet;

  final List<Pet> pets;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => userWithColorSchema,
    fromRuntime: UserWithColor._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<UserWithColor> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $UserWithColorCopyWith<UserWithColor> get copyWith =>
      _$UserWithColorCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserWithColor &&
          runtimeType == other.runtimeType &&
          deepEquals(firstName, other.firstName) &&
          deepEquals(lastName, other.lastName) &&
          deepEquals(age, other.age) &&
          deepEquals(profile, other.profile) &&
          deepEquals(color, other.color) &&
          deepEquals(favoriteColor, other.favoriteColor) &&
          deepEquals(pet, other.pet) &&
          deepEquals(pets, other.pets));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(firstName),
    deepHashCode(lastName),
    deepHashCode(age),
    deepHashCode(profile),
    deepHashCode(color),
    deepHashCode(favoriteColor),
    deepHashCode(pet),
    deepHashCode(pets),
  ]);

  @override
  String toString() =>
      'UserWithColor(firstName: $firstName, lastName: $lastName, age: $age, profile: $profile, color: $color, favoriteColor: $favoriteColor, pet: $pet, pets: $pets)';

  static UserWithColor _fromAckRuntime(Map<String, Object?> value) =>
      _$UserWithColorFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$UserWithColorToJson(this),
  };

  static String _ackFromRuntimeFirstName(Object? value) => value as String;

  static Object? _ackToRuntimeFirstName(String value) => value;

  static String _ackFromRuntimeLastName(Object? value) => value as String;

  static Object? _ackToRuntimeLastName(String value) => value;

  static int _ackFromRuntimeAge(Object? value) => value as int;

  static Object? _ackToRuntimeAge(int value) => value;

  static Profile _ackFromRuntimeProfile(Object? value) =>
      Profile.$ack.fromRuntime(value as Map<String, Object?>);

  static Object? _ackToRuntimeProfile(Profile value) =>
      Profile.$ack.toRuntime(value);

  static ColorModel _ackFromRuntimeColor(Object? value) =>
      ColorModel.$ack.fromRuntime(value as Color);

  static Object? _ackToRuntimeColor(ColorModel value) =>
      ColorModel.$ack.toRuntime(value);

  static ColorModel? _ackFromRuntimeFavoriteColor(Object? value) =>
      switch (value) {
        null => null,
        final fieldValue => ColorModel.$ack.fromRuntime(fieldValue as Color),
      };

  static Object? _ackToRuntimeFavoriteColor(ColorModel? value) =>
      switch (value) {
        null => null,
        final fieldValue => ColorModel.$ack.toRuntime(fieldValue),
      };

  static Pet _ackFromRuntimePet(Object? value) =>
      Pet.$ack.fromRuntime(value as Map<String, Object?>);

  static Object? _ackToRuntimePet(Pet value) => Pet.$ack.toRuntime(value);

  static List<Pet> _ackFromRuntimePets(Object? value) => (value as List)
      .map((item) => Pet.$ack.fromRuntime(item as Map<String, Object?>))
      .toList();

  static Object? _ackToRuntimePets(List<Pet> value) =>
      value.map((item) => Pet.$ack.toRuntime(item)).toList(growable: false);
}

final class _UserWithColorCopyWithUnset {
  const _UserWithColorCopyWithUnset();
}

/// Creates copies of [UserWithColor] with selected fields replaced.
abstract interface class $UserWithColorCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({
    String? firstName,
    String? lastName,
    int? age,
    Profile? profile,
    ColorModel? color,
    ColorModel? favoriteColor,
    Pet? pet,
    List<Pet>? pets,
  });
}

final class _$UserWithColorCopyWith
    implements $UserWithColorCopyWith<UserWithColor> {
  const _$UserWithColorCopyWith(this._source);

  static const _UserWithColorCopyWithUnset _ackCopyWithUnset =
      _UserWithColorCopyWithUnset();

  final UserWithColor _source;

  @override
  UserWithColor call({
    String? firstName,
    String? lastName,
    int? age,
    Profile? profile,
    ColorModel? color,
    Object? favoriteColor = _ackCopyWithUnset,
    Pet? pet,
    List<Pet>? pets,
  }) => UserWithColor(
    firstName: firstName ?? _source.firstName,
    lastName: lastName ?? _source.lastName,
    age: age ?? _source.age,
    profile: profile ?? _source.profile,
    color: color ?? _source.color,
    favoriteColor: identical(favoriteColor, _ackCopyWithUnset)
        ? _source.favoriteColor
        : favoriteColor as ColorModel?,
    pet: pet ?? _source.pet,
    pets: pets ?? _source.pets,
  );
}
