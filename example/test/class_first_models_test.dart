import 'package:ack_example/class_first_models.dart';
import 'package:test/test.dart';

void main() {
  test('class-first object schemas validate and map JSON keys', () {
    final account = Account.fromJson({'display_name': 'Ada'});

    expect(account.role, 'member');
    expect(account.toJson(), {'display_name': 'Ada', 'role': 'member'});
    expect(account.copyWith().role, 'member');
    expect(account.copyWith(role: 'admin').role, 'admin');
    expect(AccountSchema.safeParse({'display_name': 'A'}).isFail, isTrue);
    expect(AccountSchema.toJsonSchema()['type'], 'object');
    expect(AccountSchema.toSchemaModel(), isNotNull);
    expect(AccountSchema.wireSchema, isNotNull);
  });

  test('explicit descriptions and tags become schema descriptions', () {
    final jsonSchema = AccountSchema.toJsonSchema();
    final properties = jsonSchema['properties'] as Map<String, Object?>;

    expect(jsonSchema['description'], "A signed-in user's account.");
    expect(AccountSchema.schema.description, "A signed-in user's account.");
    expect(
      (properties['display_name'] as Map<String, Object?>)['description'],
      'The name shown to other users.',
    );
    expect(PetSchema.schema.description, 'A pet, identified by its `type`.');
    expect(
      CatSchema.schema.description,
      'A cat with a limited number of lives.',
    );
    expect(DogSchema.schema.description, isNull);
  });

  test('class-first sealed models dispatch through a discriminator', () {
    final pet = PetSchema.parse({'type': 'cat', 'id': 'c1', 'lives': 9});

    expect(pet, isA<Cat>());
    expect(pet.toJson(), {'type': 'cat', 'id': 'c1', 'lives': 9});
    expect((pet as Cat).copyWith(lives: 8).id, 'c1');
    expect(CatSchema.parse({'id': 'c2', 'lives': 7}).toJson(), {
      'type': 'cat',
      'id': 'c2',
      'lives': 7,
    });
    expect(PetSchema.safeParse({'id': 'c2', 'lives': 7}).isFail, isTrue);
  });
}
