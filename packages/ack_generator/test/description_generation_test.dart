import 'package:test/test.dart';
import 'package:build_test/build_test.dart';
import 'package:build/build.dart';
import 'package:ack_generator/builder.dart';

import 'test_utils/test_assets.dart';

void main() {
  group('Description Generation Tests', () {
    test('generates class-level descriptions in schema comments', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(description: 'A comprehensive user model for testing')
class User {
  final String name;
  final String email;
  
  User({required this.name, required this.email});
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(
            allOf([
              contains('Generated schema for User'),
              contains('A comprehensive user model for testing'),
              contains('final userSchema = Ack.object({'),
            ]),
          ),
        },
      );
    });

    test('generates field-level descriptions when @AckField is used', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(description: 'User model with documented fields')
class User {
  @AckField(description: 'The user\\'s full name')
  final String name;
  
  @AckField(description: 'User\\'s primary email address')
  final String email;
  
  final int age;
  
  User({required this.name, required this.email, required this.age});
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(
            allOf([
              contains('Generated schema for User'),
              contains('User model with documented fields'),
              contains('final userSchema = Ack.object({'),
              // Verify describe() is generated for fields with descriptions
              // Note: Generated code may be multi-line formatted, so check parts separately
              contains('.describe('),
              contains("The user\\'s full name"),
              contains("User\\'s primary email address"),
              // Verify fields without description don't have describe
              isNot(contains("'age': Ack.integer().describe(")),
            ]),
          ),
        },
      );
    });

    test('works with both class and field descriptions', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(
  description: 'Product model for e-commerce platform',
)
class Product {
  @AckField(description: 'Unique product identifier')
  final String id;

  @AckField(description: 'Product display name')
  final String name;

  @AckField(description: 'Current product price in USD')
  final double price;

  final String? description;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.description
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(
            allOf([
              contains('Generated schema for Product'),
              contains('Product model for e-commerce platform'),
              contains('final productSchema = Ack.object({'),
              // Verify describe() is generated for fields with descriptions
              // Note: Generated code may be multi-line formatted, so check parts separately
              contains('.describe('),
              contains('Unique product identifier'),
              contains('Product display name'),
              contains('Current product price in USD'),
              // Verify field without description doesn't have describe
              isNot(contains("'description': Ack.string().describe(")),
            ]),
          ),
        },
      );
    });

    test('handles missing descriptions gracefully', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class SimpleModel {
  final String name;
  
  SimpleModel({required this.name});
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(
            allOf([
              contains('Generated schema for SimpleModel'),
              // Should have the standard generated comment but no additional description
              isNot(
                contains('/// A'),
              ), // No additional description starting with "/// A"
              isNot(
                contains('/// This'),
              ), // No additional description starting with "/// This"
              contains('final simpleModelSchema = Ack.object({'),
              // Verify no describe() is generated when no field descriptions
              isNot(contains('.describe(')),
            ]),
          ),
        },
      );
    });

    test('extracts descriptions with special characters correctly', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(description: 'Model with "quotes" and \\special\\ characters')
class SpecialModel {
  final String name;

  SpecialModel({required this.name});
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(
            allOf([
              contains('Generated schema for SpecialModel'),
              contains('Model with "quotes" and special characters'),
              contains('final specialModelSchema = Ack.object({'),
            ]),
          ),
        },
      );
    });
  });

  group('Doc Comment Description Tests', () {
    test('generates field descriptions from doc comments', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class User {
  /// The unique identifier for the user
  final String id;

  /// User full name
  final String name;

  final int age;

  User({required this.id, required this.name, required this.age});
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(
            allOf([
              contains('final userSchema = Ack.object({'),
              // Verify describe() is generated from doc comments
              contains('.describe('),
              contains('The unique identifier for the user'),
              contains('User full name'),
              // Verify field without doc comment doesn't have describe
              isNot(contains("'age': Ack.integer().describe(")),
            ]),
          ),
        },
      );
    });

    test('generates class description from doc comment', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

/// A user model with profile information
@AckModel()
class User {
  final String name;

  User({required this.name});
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(
            allOf([
              contains('Generated schema for User'),
              contains('A user model with profile information'),
              contains('final userSchema = Ack.object({'),
            ]),
          ),
        },
      );
    });

    test('annotation description overrides doc comment for fields', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class User {
  /// Internal identifier used for database operations
  @AckField(description: 'Public user ID')
  final String id;

  User({required this.id});
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(
            allOf([
              contains('final userSchema = Ack.object({'),
              // Verify annotation description is used, not doc comment
              contains('Public user ID'),
              isNot(contains('Internal identifier used for database operations')),
            ]),
          ),
        },
      );
    });

    test('annotation description overrides doc comment for class', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

/// Internal user representation
@AckModel(description: 'Public API user model')
class User {
  final String name;

  User({required this.name});
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(
            allOf([
              contains('Generated schema for User'),
              // Verify annotation description is used, not doc comment
              contains('Public API user model'),
              isNot(contains('Internal user representation')),
            ]),
          ),
        },
      );
    });

    test('handles multi-line doc comments', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class User {
  /// The unique identifier
  /// for the user account
  final String id;

  User({required this.id});
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(
            allOf([
              contains('final userSchema = Ack.object({'),
              contains('.describe('),
              // Multi-line comments should be joined with spaces
              contains('The unique identifier for the user account'),
            ]),
          ),
        },
      );
    });

    test('handles doc comments with special characters', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class User {
  /// Full name of the user (required field)
  final String name;

  User({required this.name});
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(
            allOf([
              contains('final userSchema = Ack.object({'),
              contains('.describe('),
              contains('Full name of the user (required field)'),
            ]),
          ),
        },
      );
    });

    test('works with multiple fields having doc comments', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class Product {
  /// Product SKU code used for inventory tracking
  final String sku;

  /// Product display name shown to customers
  final String name;

  /// Current price in USD
  final double price;

  Product({required this.sku, required this.name, required this.price});
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(
            allOf([
              contains('final productSchema = Ack.object({'),
              contains('.describe('),
              contains('Product SKU code used for inventory tracking'),
              contains('Product display name shown to customers'),
              contains('Current price in USD'),
            ]),
          ),
        },
      );
    });
  });

  group('Block Comment Description Tests', () {
    test('generates field descriptions from block comments', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class User {
  /** The unique user identifier */
  final String id;

  User({required this.id});
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(
            allOf([
              contains('final userSchema = Ack.object({'),
              contains('.describe('),
              contains('The unique user identifier'),
            ]),
          ),
        },
      );
    });

    test('generates class description from block comment', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

/** A user account in the system */
@AckModel()
class User {
  final String name;

  User({required this.name});
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(
            allOf([
              contains('Generated schema for User'),
              contains('A user account in the system'),
              contains('final userSchema = Ack.object({'),
            ]),
          ),
        },
      );
    });

    test('handles multi-line block comments', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class User {
  /**
   * The unique identifier
   * for this user account
   */
  final String id;

  User({required this.id});
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(
            allOf([
              contains('final userSchema = Ack.object({'),
              contains('.describe('),
              contains('The unique identifier for this user account'),
            ]),
          ),
        },
      );
    });
  });
}
