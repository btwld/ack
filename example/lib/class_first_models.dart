import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'class_first_models.ack.dart';
part 'class_first_models.ack.g.dart';

/// A signed-in user's account.
@AckModel(
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
  @MinLength(2)
  @AckField(description: 'The name shown to other users.')
  final String displayName;
  final Uri? website;
  final String role;

  static final fromJson = AccountSchema.fromJson;
}

/// A pet, identified by its `type`.
/// @description A pet, identified by its `type`.
@AckModel(discriminatorKey: 'type')
sealed class Pet with _$PetAck {
  const Pet({required this.id});

  final String id;
}

/// A cat with a limited number of lives.
/// @description A cat with a limited number of lives.
@AckModel(discriminatorValue: 'cat')
final class Cat extends Pet with _$CatAck {
  const Cat({required super.id, required this.lives});

  @Min(1)
  @Max(9)
  final int lives;
}

final class Dog extends Pet with _$DogAck {
  const Dog({required super.id, required this.breed});

  final String breed;
}
