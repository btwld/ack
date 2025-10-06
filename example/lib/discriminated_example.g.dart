// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

// // GENERATED CODE - DO NOT MODIFY BY HAND

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
final catSchema = Ack.object({
  'type': Ack.literal('cat'),
  'meow': Ack.boolean(),
  'lives': Ack.integer(),
});

/// Generated schema for Dog
final dogSchema = Ack.object({
  'type': Ack.literal('dog'),
  'bark': Ack.boolean(),
  'breed': Ack.string(),
});

/// Generated schema for Bird
final birdSchema = Ack.object({
  'type': Ack.literal('bird'),
  'canFly': Ack.boolean(),
  'wingspan': Ack.double(),
});

/// Generated schema for Circle
final circleSchema = Ack.object({
  'kind': Ack.literal('circle'),
  'radius': Ack.double(),
});

/// Generated schema for Rectangle
final rectangleSchema = Ack.object({
  'kind': Ack.literal('rectangle'),
  'width': Ack.double(),
  'height': Ack.double(),
});
