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
  AnimalSchemaModel._internal(DiscriminatedObjectSchema this.schema);

  factory AnimalSchemaModel() {
    return AnimalSchemaModel._internal(animalSchema);
  }

  AnimalSchemaModel._withSchema(DiscriminatedObjectSchema customSchema)
      : schema = customSchema;

  @override
  final DiscriminatedObjectSchema schema;

  @override
  Animal createFromMap(Map<String, dynamic> map) {
    final type = map['type'] as String;
    return switch (type) {
      'cat' => CatSchemaModel().createFromMap(map),
      'dog' => DogSchemaModel().createFromMap(map),
      'bird' => BirdSchemaModel().createFromMap(map),
      _ => throw ArgumentError(
          'Unknown type: $type. Valid values: \'cat\', \'dog\', \'bird\'',
        ),
    };
  }

  /// Returns a new schema with the specified description.
  AnimalSchemaModel describe(String description) {
    final newSchema = schema.copyWith(description: description);
    return AnimalSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with the specified default value.
  AnimalSchemaModel withDefault(Map<String, dynamic> defaultValue) {
    final newSchema = schema.copyWith(defaultValue: defaultValue);
    return AnimalSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with nullable flag set to the specified value.
  AnimalSchemaModel nullable([bool value = true]) {
    final newSchema = schema.copyWith(isNullable: value);
    return AnimalSchemaModel._withSchema(newSchema);
  }
}

/// Generated SchemaModel for [Shape].
class ShapeSchemaModel extends SchemaModel<Shape> {
  ShapeSchemaModel._internal(DiscriminatedObjectSchema this.schema);

  factory ShapeSchemaModel() {
    return ShapeSchemaModel._internal(shapeSchema);
  }

  ShapeSchemaModel._withSchema(DiscriminatedObjectSchema customSchema)
      : schema = customSchema;

  @override
  final DiscriminatedObjectSchema schema;

  @override
  Shape createFromMap(Map<String, dynamic> map) {
    final kind = map['kind'] as String;
    return switch (kind) {
      'circle' => CircleSchemaModel().createFromMap(map),
      'rectangle' => RectangleSchemaModel().createFromMap(map),
      _ => throw ArgumentError(
          'Unknown kind: $kind. Valid values: \'circle\', \'rectangle\'',
        ),
    };
  }

  /// Returns a new schema with the specified description.
  ShapeSchemaModel describe(String description) {
    final newSchema = schema.copyWith(description: description);
    return ShapeSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with the specified default value.
  ShapeSchemaModel withDefault(Map<String, dynamic> defaultValue) {
    final newSchema = schema.copyWith(defaultValue: defaultValue);
    return ShapeSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with nullable flag set to the specified value.
  ShapeSchemaModel nullable([bool value = true]) {
    final newSchema = schema.copyWith(isNullable: value);
    return ShapeSchemaModel._withSchema(newSchema);
  }
}

/// Generated SchemaModel for [Cat].
class CatSchemaModel extends SchemaModel<Cat> {
  CatSchemaModel._internal(ObjectSchema this.schema);

  factory CatSchemaModel() {
    return CatSchemaModel._internal(catSchema);
  }

  CatSchemaModel._withSchema(ObjectSchema customSchema) : schema = customSchema;

  @override
  final ObjectSchema schema;

  @override
  Cat createFromMap(Map<String, dynamic> map) {
    return Cat(meow: map['meow'] as bool, lives: map['lives'] as int);
  }

  /// Returns a new schema with the specified description.
  CatSchemaModel describe(String description) {
    final newSchema = schema.copyWith(description: description);
    return CatSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with the specified default value.
  CatSchemaModel withDefault(Map<String, dynamic> defaultValue) {
    final newSchema = schema.copyWith(defaultValue: defaultValue);
    return CatSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with nullable flag set to the specified value.
  CatSchemaModel nullable([bool value = true]) {
    final newSchema = schema.copyWith(isNullable: value);
    return CatSchemaModel._withSchema(newSchema);
  }
}

/// Generated SchemaModel for [Dog].
class DogSchemaModel extends SchemaModel<Dog> {
  DogSchemaModel._internal(ObjectSchema this.schema);

  factory DogSchemaModel() {
    return DogSchemaModel._internal(dogSchema);
  }

  DogSchemaModel._withSchema(ObjectSchema customSchema) : schema = customSchema;

  @override
  final ObjectSchema schema;

  @override
  Dog createFromMap(Map<String, dynamic> map) {
    return Dog(bark: map['bark'] as bool, breed: map['breed'] as String);
  }

  /// Returns a new schema with the specified description.
  DogSchemaModel describe(String description) {
    final newSchema = schema.copyWith(description: description);
    return DogSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with the specified default value.
  DogSchemaModel withDefault(Map<String, dynamic> defaultValue) {
    final newSchema = schema.copyWith(defaultValue: defaultValue);
    return DogSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with nullable flag set to the specified value.
  DogSchemaModel nullable([bool value = true]) {
    final newSchema = schema.copyWith(isNullable: value);
    return DogSchemaModel._withSchema(newSchema);
  }
}

/// Generated SchemaModel for [Bird].
class BirdSchemaModel extends SchemaModel<Bird> {
  BirdSchemaModel._internal(ObjectSchema this.schema);

  factory BirdSchemaModel() {
    return BirdSchemaModel._internal(birdSchema);
  }

  BirdSchemaModel._withSchema(ObjectSchema customSchema)
      : schema = customSchema;

  @override
  final ObjectSchema schema;

  @override
  Bird createFromMap(Map<String, dynamic> map) {
    return Bird(
      canFly: map['canFly'] as bool,
      wingspan: map['wingspan'] as double,
    );
  }

  /// Returns a new schema with the specified description.
  BirdSchemaModel describe(String description) {
    final newSchema = schema.copyWith(description: description);
    return BirdSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with the specified default value.
  BirdSchemaModel withDefault(Map<String, dynamic> defaultValue) {
    final newSchema = schema.copyWith(defaultValue: defaultValue);
    return BirdSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with nullable flag set to the specified value.
  BirdSchemaModel nullable([bool value = true]) {
    final newSchema = schema.copyWith(isNullable: value);
    return BirdSchemaModel._withSchema(newSchema);
  }
}

/// Generated SchemaModel for [Circle].
class CircleSchemaModel extends SchemaModel<Circle> {
  CircleSchemaModel._internal(ObjectSchema this.schema);

  factory CircleSchemaModel() {
    return CircleSchemaModel._internal(circleSchema);
  }

  CircleSchemaModel._withSchema(ObjectSchema customSchema)
      : schema = customSchema;

  @override
  final ObjectSchema schema;

  @override
  Circle createFromMap(Map<String, dynamic> map) {
    return Circle(radius: map['radius'] as double);
  }

  /// Returns a new schema with the specified description.
  CircleSchemaModel describe(String description) {
    final newSchema = schema.copyWith(description: description);
    return CircleSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with the specified default value.
  CircleSchemaModel withDefault(Map<String, dynamic> defaultValue) {
    final newSchema = schema.copyWith(defaultValue: defaultValue);
    return CircleSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with nullable flag set to the specified value.
  CircleSchemaModel nullable([bool value = true]) {
    final newSchema = schema.copyWith(isNullable: value);
    return CircleSchemaModel._withSchema(newSchema);
  }
}

/// Generated SchemaModel for [Rectangle].
class RectangleSchemaModel extends SchemaModel<Rectangle> {
  RectangleSchemaModel._internal(ObjectSchema this.schema);

  factory RectangleSchemaModel() {
    return RectangleSchemaModel._internal(rectangleSchema);
  }

  RectangleSchemaModel._withSchema(ObjectSchema customSchema)
      : schema = customSchema;

  @override
  final ObjectSchema schema;

  @override
  Rectangle createFromMap(Map<String, dynamic> map) {
    return Rectangle(
      width: map['width'] as double,
      height: map['height'] as double,
    );
  }

  /// Returns a new schema with the specified description.
  RectangleSchemaModel describe(String description) {
    final newSchema = schema.copyWith(description: description);
    return RectangleSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with the specified default value.
  RectangleSchemaModel withDefault(Map<String, dynamic> defaultValue) {
    final newSchema = schema.copyWith(defaultValue: defaultValue);
    return RectangleSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with nullable flag set to the specified value.
  RectangleSchemaModel nullable([bool value = true]) {
    final newSchema = schema.copyWith(isNullable: value);
    return RectangleSchemaModel._withSchema(newSchema);
  }
}
