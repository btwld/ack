import 'package:test/test.dart';
import 'package:build_test/build_test.dart';
import 'package:ack_generator/builder.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('Simple Model Integration Tests', () {
    test('generates schema for simple model with primitive fields', () async {
      final builder = ackGenerator(BuilderOptions.empty);
      
      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/user.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class User {
  final String name;
  final int age;
  final String? email;
  
  User({required this.name, required this.age, this.email});
}
''',
        },
        outputs: {
          'test_pkg|lib/user.ack.g.part': allOf([
            contains('class UserSchema extends SchemaModel'),
            contains('const UserSchema()'),
            contains('const UserSchema._valid(Map<String, Object?> data)'),
            contains('@override\n  UserSchema parse(Object? input)'),
            contains('return super.parse(input) as UserSchema;'),
            contains('@override\n  UserSchema? tryParse(Object? input)'),
            contains('return super.tryParse(input) as UserSchema?;'),
            contains("'name': Ack.string"),
            contains("'age': Ack.integer"),
            contains("'email': Ack.string.nullable()"),
            contains("required: ['name', 'age']"),
            contains('String get name => getValue<String>(\'name\')'),
            contains('int get age => getValue<int>(\'age\')'),
            contains('String? get email => getValueOrNull<String>(\'email\')'),
          ]),
        },
      );
    });

    test('generates schema with custom schema name', () async {
      final builder = ackGenerator(BuilderOptions.empty);
      
      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(schemaName: 'CustomUserSchema', description: 'A custom user schema')
class User {
  final String id;
  
  User({required this.id});
}
''',
        },
        outputs: {
          'test_pkg|lib/model.ack.g.part': allOf([
            contains('class CustomUserSchema extends SchemaModel'),
            contains('/// Generated schema for User'),
            contains('/// A custom user schema'),
          ]),
        },
      );
    });

    test('handles all primitive types correctly', () async {
      final builder = ackGenerator(BuilderOptions.empty);
      
      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/primitives.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class AllPrimitives {
  final String text;
  final int count;
  final double price;
  final num number;
  final bool active;
  
  AllPrimitives({
    required this.text,
    required this.count,
    required this.price,
    required this.number,
    required this.active,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/primitives.ack.g.part': allOf([
            contains("'text': Ack.string"),
            contains("'count': Ack.integer"),
            contains("'price': Ack.double"),
            contains("'number': Ack.number"),
            contains("'active': Ack.boolean"),
            contains('String get text'),
            contains('int get count'),
            contains('double get price'),
            contains('num get number'),
            contains('bool get active'),
          ]),
        },
      );
    });
  });
}
