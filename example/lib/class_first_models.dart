import 'package:ack/ack.dart';

part 'class_first_models.g.dart';

/// A signed-in user's account.
@Schemable(
  caseStyle: AckCaseStyle.snake,
  description: "A signed-in user's account.",
)
final class const Account({
  /// The name shown to other users.
  /// @description The name shown to other users.
  @HasMinLength(2) required final String displayName,
  final Uri? website,
  final String role = 'member',
}) with _$AccountAck {
  static final schema = AccountSchema.schema;
  static final fromJson = AccountSchema.fromJson;
}

/// A pet, identified by its `type`.
/// @description A pet, identified by its `type`.
@Schemable(discriminatorKey: 'type')
sealed class const Pet({required final String id}) with _$PetAck;

/// A cat with a limited number of lives.
/// @description A cat with a limited number of lives.
@Schemable(discriminatorValue: 'cat')
final class const Cat({
  required super.id,
  @HasMin(1) @HasMax(9) required final int lives,
}) extends Pet with _$CatAck;

final class const Dog({required super.id, required final String breed})
    extends Pet
    with _$DogAck;
