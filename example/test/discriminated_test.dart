import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../lib/discriminated_example.dart';

void main() {
  group('Discriminated Types Implementation Tests', () {
    group('Schema Generation Tests', () {
      test('Animal discriminated schema is generated correctly', () {
        expect(animalSchema, isA<DiscriminatedObjectSchema>());
      });

      test('Shape discriminated schema is generated correctly', () {
        expect(shapeSchema, isA<DiscriminatedObjectSchema>());
      });

      test('Cat schema is generated correctly', () {
        expect(catSchema, isA<ObjectSchema>());
      });

      test('Dog schema is generated correctly', () {
        expect(dogSchema, isA<ObjectSchema>());
      });
    });

    group('SchemaModel Tests', () {
      test('Animal SchemaModel can create Cat from map', () {
        final animalModel = AnimalSchemaModel();
        final catData = {
          'type': 'cat',
          'meow': true,
          'lives': 9,
        };

        final result = animalModel.createFromMap(catData);
        expect(result, isA<Cat>());

        final cat = result as Cat;
        expect(cat.type, equals('cat'));
        expect(cat.meow, isTrue);
        expect(cat.lives, equals(9));
      });

      test('Animal SchemaModel can create Dog from map', () {
        final animalModel = AnimalSchemaModel();
        final dogData = {
          'type': 'dog',
          'bark': false,
          'breed': 'Golden Retriever',
        };

        final result = animalModel.createFromMap(dogData);
        expect(result, isA<Dog>());

        final dog = result as Dog;
        expect(dog.type, equals('dog'));
        expect(dog.bark, isFalse);
        expect(dog.breed, equals('Golden Retriever'));
      });

      test('Animal SchemaModel can create Bird from map', () {
        final animalModel = AnimalSchemaModel();
        final birdData = {
          'type': 'bird',
          'canFly': true,
          'wingspan': 2.5,
        };

        final result = animalModel.createFromMap(birdData);
        expect(result, isA<Bird>());

        final bird = result as Bird;
        expect(bird.type, equals('bird'));
        expect(bird.canFly, isTrue);
        expect(bird.wingspan, equals(2.5));
      });

      test('Animal SchemaModel throws error for unknown type', () {
        final animalModel = AnimalSchemaModel();
        final invalidData = {
          'type': 'fish',
          'swimming': true,
        };

        expect(
          () => animalModel.createFromMap(invalidData),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Unknown type: fish'),
          )),
        );
      });
    });

    group('Shape Discriminated Types Tests', () {
      test('Shape SchemaModel can create Circle from map', () {
        final shapeModel = ShapeSchemaModel();
        final circleData = {
          'kind': 'circle',
          'radius': 5.0,
        };

        final result = shapeModel.createFromMap(circleData);
        expect(result, isA<Circle>());

        final circle = result as Circle;
        expect(circle.kind, equals('circle'));
        expect(circle.radius, equals(5.0));
        expect(circle.area, closeTo(78.54, 0.01)); // π * 5²
      });

      test('Shape SchemaModel can create Rectangle from map', () {
        final shapeModel = ShapeSchemaModel();
        final rectangleData = {
          'kind': 'rectangle',
          'width': 4.0,
          'height': 3.0,
        };

        final result = shapeModel.createFromMap(rectangleData);
        expect(result, isA<Rectangle>());

        final rectangle = result as Rectangle;
        expect(rectangle.kind, equals('rectangle'));
        expect(rectangle.width, equals(4.0));
        expect(rectangle.height, equals(3.0));
        expect(rectangle.area, equals(12.0));
      });

      test('Shape SchemaModel throws error for unknown kind', () {
        final shapeModel = ShapeSchemaModel();
        final invalidData = {
          'kind': 'triangle',
          'base': 5.0,
          'height': 4.0,
        };

        expect(
          () => shapeModel.createFromMap(invalidData),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Unknown kind: triangle'),
          )),
        );
      });
    });

    group('Individual SchemaModel Tests', () {
      test('Cat SchemaModel works correctly', () {
        final catModel = CatSchemaModel();
        final catData = {
          'meow': true,
          'lives': 7,
        };

        final cat = catModel.createFromMap(catData);
        expect(cat.meow, isTrue);
        expect(cat.lives, equals(7));
        expect(cat.type, equals('cat'));
      });

      test('Dog SchemaModel works correctly', () {
        final dogModel = DogSchemaModel();
        final dogData = {
          'bark': true,
          'breed': 'Labrador',
        };

        final dog = dogModel.createFromMap(dogData);
        expect(dog.bark, isTrue);
        expect(dog.breed, equals('Labrador'));
        expect(dog.type, equals('dog'));
      });
    });
  });
}
