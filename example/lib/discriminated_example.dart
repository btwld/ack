import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'discriminated_example.g.dart';

// Base discriminated class for animals
@AckModel(discriminatedKey: 'type')
abstract class Animal {
  String get type;
}

// Concrete implementations with discriminator values
@AckModel(discriminatedValue: 'cat')
class Cat extends Animal {
  @override
  String get type => 'cat';

  final bool meow;
  final int lives;

  Cat({required this.meow, this.lives = 9});
}

@AckModel(discriminatedValue: 'dog')
class Dog extends Animal {
  @override
  String get type => 'dog';

  final bool bark;
  final String breed;

  Dog({required this.bark, required this.breed});
}

@AckModel(discriminatedValue: 'bird')
class Bird extends Animal {
  @override
  String get type => 'bird';

  final bool canFly;
  final double wingspan;

  Bird({required this.canFly, required this.wingspan});
}

// Another discriminated hierarchy for shapes
@AckModel(discriminatedKey: 'kind')
abstract class Shape {
  String get kind;
  double get area;
}

@AckModel(discriminatedValue: 'circle')
class Circle extends Shape {
  @override
  String get kind => 'circle';

  final double radius;

  Circle({required this.radius});

  @override
  double get area => 3.14159 * radius * radius;
}

@AckModel(discriminatedValue: 'rectangle')
class Rectangle extends Shape {
  @override
  String get kind => 'rectangle';

  final double width;
  final double height;

  Rectangle({required this.width, required this.height});

  @override
  double get area => width * height;
}
