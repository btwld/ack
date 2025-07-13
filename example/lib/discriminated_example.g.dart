// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'discriminated_example.dart';

/// Generated schema for Animal
final animalSchema = Ack.discriminated(
  discriminatorKey: 'type',
  schemas: {'cat': catSchema, 'dog': dogSchema, 'bird': birdSchema},
);

/// Generated schema for Shape
final shapeSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {'circle': circleSchema, 'rectangle': rectangleSchema},
);

/// Generated schema for Cat
final catSchema = Ack.object({'meow': Ack.boolean(), 'lives': Ack.integer()});

/// Generated schema for Dog
final dogSchema = Ack.object({'bark': Ack.boolean(), 'breed': Ack.string()});

/// Generated schema for Bird
final birdSchema = Ack.object({
  'canFly': Ack.boolean(),
  'wingspan': Ack.double(),
});

/// Generated schema for Circle
final circleSchema = Ack.object({'radius': Ack.double()});

/// Generated schema for Rectangle
final rectangleSchema = Ack.object({
  'width': Ack.double(),
  'height': Ack.double(),
});

/// Generated SchemaModel for [Animal].
class AnimalSchemaModel extends SchemaModel<Animal> {
  AnimalSchemaModel._();

  factory AnimalSchemaModel() {
    return _instance;
  }

  static final _instance = AnimalSchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return animalSchema as ObjectSchema;
  }

  @override
  Animal createFromMap(Map<String, dynamic> map) {
    final type = map['type'] as String;
    return switch (type) {
      'cat' => CatSchemaModel._instance.createFromMap(map),
      'dog' => DogSchemaModel._instance.createFromMap(map),
      'bird' => BirdSchemaModel._instance.createFromMap(map),
      _ => throw ArgumentError(
          'Unknown type: $type. Valid values: \'cat\', \'dog\', \'bird\'',
        ),
    };
  }
}

/// Generated SchemaModel for [Shape].
class ShapeSchemaModel extends SchemaModel<Shape> {
  ShapeSchemaModel._();

  factory ShapeSchemaModel() {
    return _instance;
  }

  static final _instance = ShapeSchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return shapeSchema as ObjectSchema;
  }

  @override
  Shape createFromMap(Map<String, dynamic> map) {
    final kind = map['kind'] as String;
    return switch (kind) {
      'circle' => CircleSchemaModel._instance.createFromMap(map),
      'rectangle' => RectangleSchemaModel._instance.createFromMap(map),
      _ => throw ArgumentError(
          'Unknown kind: $kind. Valid values: \'circle\', \'rectangle\'',
        ),
    };
  }
}

/// Generated SchemaModel for [Cat].
class CatSchemaModel extends SchemaModel<Cat> {
  CatSchemaModel._();

  factory CatSchemaModel() {
    return _instance;
  }

  static final _instance = CatSchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return catSchema;
  }

  @override
  Cat createFromMap(Map<String, dynamic> map) {
    return Cat(meow: map['meow'] as bool, lives: map['lives'] as int);
  }
}

/// Generated SchemaModel for [Dog].
class DogSchemaModel extends SchemaModel<Dog> {
  DogSchemaModel._();

  factory DogSchemaModel() {
    return _instance;
  }

  static final _instance = DogSchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return dogSchema;
  }

  @override
  Dog createFromMap(Map<String, dynamic> map) {
    return Dog(bark: map['bark'] as bool, breed: map['breed'] as String);
  }
}

/// Generated SchemaModel for [Bird].
class BirdSchemaModel extends SchemaModel<Bird> {
  BirdSchemaModel._();

  factory BirdSchemaModel() {
    return _instance;
  }

  static final _instance = BirdSchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return birdSchema;
  }

  @override
  Bird createFromMap(Map<String, dynamic> map) {
    return Bird(
      canFly: map['canFly'] as bool,
      wingspan: map['wingspan'] as double,
    );
  }
}

/// Generated SchemaModel for [Circle].
class CircleSchemaModel extends SchemaModel<Circle> {
  CircleSchemaModel._();

  factory CircleSchemaModel() {
    return _instance;
  }

  static final _instance = CircleSchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return circleSchema;
  }

  @override
  Circle createFromMap(Map<String, dynamic> map) {
    return Circle(radius: map['radius'] as double);
  }
}

/// Generated SchemaModel for [Rectangle].
class RectangleSchemaModel extends SchemaModel<Rectangle> {
  RectangleSchemaModel._();

  factory RectangleSchemaModel() {
    return _instance;
  }

  static final _instance = RectangleSchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return rectangleSchema;
  }

  @override
  Rectangle createFromMap(Map<String, dynamic> map) {
    return Rectangle(
      width: map['width'] as double,
      height: map['height'] as double,
    );
  }
}
