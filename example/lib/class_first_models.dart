import 'package:ack/ack.dart';

part 'class_first_models.g.dart';

/// A signed-in user's account.
@Schemable(
  caseStyle: AckCaseStyle.snake,
  description: "A signed-in user's account.",
)
final class Account with _$AccountAck {
  const Account({
    required this.displayName,
    this.website,
    this.role = 'member',
  });

  /// The name shown to other users.
  @Check.minLength(2)
  @AckField(description: 'The name shown to other users.')
  final String displayName;
  final Uri? website;
  final String role;

  static final fromJson = AccountSchema.fromJson;
}

/// A pet, identified by its `type`.
/// @description A pet, identified by its `type`.
@Schemable(discriminatorKey: 'type')
sealed class Pet with _$PetAck {
  const Pet({required this.id});

  final String id;
}

/// A cat with a limited number of lives.
/// @description A cat with a limited number of lives.
@Schemable(discriminatorValue: 'cat')
final class Cat extends Pet with _$CatAck {
  const Cat({required super.id, required this.lives});

  @Check.min(1)
  @Check.max(9)
  final int lives;
}

final class Dog extends Pet with _$DogAck {
  const Dog({required super.id, required this.breed});

  final String breed;
}
