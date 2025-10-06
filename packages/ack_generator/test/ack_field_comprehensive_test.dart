import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'test_utils/test_assets.dart';

void main() {
  group('AckField Annotation Comprehensive Tests', () {
    group('Basic AckField Usage', () {
      test('should handle required field annotation', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/required_fields.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class RequiredFieldsModel {
  @AckField(required: true)
  final String mandatoryField;
  
  @AckField(required: false)
  final String? optionalField;
  
  final String defaultField; // No annotation
  
  RequiredFieldsModel({
    required this.mandatoryField,
    this.optionalField,
    required this.defaultField,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/required_fields.g.dart': decodedMatches(
              allOf([
                contains('final requiredFieldsModelSchema = Ack.object({'),
                contains("'mandatoryField': Ack.string()"),
                contains("'optionalField': Ack.string().optional().nullable()"),
                contains("'defaultField': Ack.string()"),
              ]),
            ),
          },
        );
      });

      test('should handle custom jsonKey annotation', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/json_key.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class JsonKeyModel {
  @AckField(jsonKey: 'user_name')
  final String userName;
  
  @AckField(jsonKey: 'email_address')
  final String email;
  
  @AckField(jsonKey: 'phone-number')
  final String phone;
  
  JsonKeyModel({
    required this.userName,
    required this.email,
    required this.phone,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/json_key.g.dart': decodedMatches(
              allOf([
                contains('final jsonKeyModelSchema = Ack.object({'),
                contains("'user_name': Ack.string()"),
                contains("'email_address': Ack.string()"),
                contains("'phone-number': Ack.string()"),
              ]),
            ),
          },
        );
      });

      test('should handle field description annotation', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/field_descriptions.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class FieldDescriptionsModel {
  @AckField(description: 'The user\\'s full name')
  final String name;
  
  @AckField(description: 'Age in years')
  final int age;
  
  @AckField(description: 'Optional contact email')
  final String? email;
  
  FieldDescriptionsModel({
    required this.name,
    required this.age,
    this.email,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/field_descriptions.g.dart': decodedMatches(
              allOf([
                contains('final fieldDescriptionsModelSchema = Ack.object({'),
                contains("'name': Ack.string()"),
                contains("'age': Ack.integer()"),
                contains("'email': Ack.string().optional().nullable()"),
              ]),
            ),
          },
        );
      });

      test('should handle field constraints annotation', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/field_constraints.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class FieldConstraintsModel {
  @AckField(constraints: ['min(18)', 'max(100)'])
  final int age;
  
  @AckField(constraints: ['minLength(2)', 'maxLength(50)'])
  final String name;
  
  @AckField(constraints: ['email'])
  final String email;
  
  FieldConstraintsModel({
    required this.age,
    required this.name,
    required this.email,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/field_constraints.g.dart': decodedMatches(
              allOf([
                contains('final fieldConstraintsModelSchema = Ack.object({'),
                contains("'age': Ack.integer()"),
                contains("'name': Ack.string()"),
                contains("'email': Ack.string()"),
              ]),
            ),
          },
        );
      });
    });

    group('AckField Combination Tests', () {
      test('should handle all AckField options together', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/all_options.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class AllOptionsModel {
  @AckField(
    required: true,
    jsonKey: 'user_email',
    description: 'User\\'s primary email address',
    constraints: ['email', 'notEmpty']
  )
  final String email;
  
  @AckField(
    required: false,
    jsonKey: 'display_name',
    description: 'Optional display name',
    constraints: ['minLength(1)', 'maxLength(100)']
  )
  final String? displayName;
  
  AllOptionsModel({
    required this.email,
    this.displayName,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/all_options.g.dart': decodedMatches(
              allOf([
                contains('final allOptionsModelSchema = Ack.object({'),
                contains("'user_email': Ack.string().email().notEmpty()"),
                contains("'display_name': Ack.string()"),
                contains('.minLength(1)'),
                contains('.maxLength(100)'),
                contains('.optional()'),
                contains('.nullable()'),
              ]),
            ),
          },
        );
      });

      test(
        'should handle AckField with complex jsonKey and constraints',
        () async {
          final builder = ackGenerator(BuilderOptions.empty);

          await testBuilder(
            builder,
            {
              ...allAssets,
              'test_pkg|lib/field_with_model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class FieldWithModelGeneration {
  @AckField(jsonKey: 'full_name', description: 'Complete name')
  final String name;

  @AckField(jsonKey: 'user_age', constraints: ['min(0)', 'max(150)'])
  final int age;

  FieldWithModelGeneration({
    required this.name,
    required this.age,
  });
}
''',
            },
            outputs: {
              'test_pkg|lib/field_with_model.g.dart': decodedMatches(
                allOf([
                  // Schema generation
                  contains(
                    'final fieldWithModelGenerationSchema = Ack.object({',
                  ),
                  contains("'full_name': Ack.string()"),
                  contains("'user_age': Ack.integer().min(0).max(150)"),
                ]),
              ),
            },
          );
        },
      );
    });

    group('AckField Edge Cases', () {
      test('should handle empty constraints list', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/empty_constraints.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class EmptyConstraintsModel {
  @AckField(constraints: [])
  final String emptyConstraints;
  
  @AckField(constraints: [''])
  final String emptyStringConstraint;
  
  EmptyConstraintsModel({
    required this.emptyConstraints,
    required this.emptyStringConstraint,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/empty_constraints.g.dart': decodedMatches(
              allOf([
                contains('final emptyConstraintsModelSchema = Ack.object({'),
                contains("'emptyConstraints': Ack.string()"),
                contains("'emptyStringConstraint': Ack.string()"),
              ]),
            ),
          },
        );
      });

      test('should handle special characters in jsonKey', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/special_json_keys.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class SpecialJsonKeysModel {
  @AckField(jsonKey: 'field-with-dashes')
  final String dashedField;
  
  @AckField(jsonKey: 'field_with_underscores')
  final String underscoredField;
  
  @AckField(jsonKey: 'field.with.dots')
  final String dottedField;
  
  @AckField(jsonKey: 'field with spaces')
  final String spacedField;
  
  SpecialJsonKeysModel({
    required this.dashedField,
    required this.underscoredField,
    required this.dottedField,
    required this.spacedField,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/special_json_keys.g.dart': decodedMatches(
              allOf([
                contains('final specialJsonKeysModelSchema = Ack.object({'),
                contains("'field-with-dashes': Ack.string()"),
                contains("'field_with_underscores': Ack.string()"),
                contains("'field.with.dots': Ack.string()"),
                contains("'field with spaces': Ack.string()"),
              ]),
            ),
          },
        );
      });

      test('should handle complex constraint strings', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/complex_constraints.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class ComplexConstraintsModel {
  @AckField(constraints: ['regex(^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})'])
  final String emailRegex;
  
  @AckField(constraints: ['oneOf(active,inactive,pending)'])
  final String status;
  
  @AckField(constraints: ['custom(complex, nested, constraint)'])
  final String complexConstraint;
  
  ComplexConstraintsModel({
    required this.emailRegex,
    required this.status,
    required this.complexConstraint,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/complex_constraints.g.dart': decodedMatches(
              allOf([
                contains('final complexConstraintsModelSchema = Ack.object({'),
                contains("'emailRegex': Ack.string()"),
                contains("'status': Ack.string()"),
                contains("'complexConstraint': Ack.string()"),
              ]),
            ),
          },
        );
      });
    });

    group('AckField with Different Field Types', () {
      test('should handle AckField on various field types', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/various_types.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

enum Status { active, inactive }

@AckModel()
class VariousTypesModel {
  @AckField(jsonKey: 'text_field')
  final String textField;
  
  @AckField(jsonKey: 'number_field')
  final int numberField;
  
  @AckField(jsonKey: 'decimal_field')
  final double decimalField;
  
  @AckField(jsonKey: 'boolean_field')
  final bool booleanField;
  
  @AckField(jsonKey: 'enum_field')
  final Status enumField;
  
  @AckField(jsonKey: 'list_field')
  final List<String> listField;
  
  @AckField(jsonKey: 'nullable_field')
  final String? nullableField;
  
  VariousTypesModel({
    required this.textField,
    required this.numberField,
    required this.decimalField,
    required this.booleanField,
    required this.enumField,
    required this.listField,
    this.nullableField,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/various_types.g.dart': decodedMatches(
              allOf([
                contains('final variousTypesModelSchema = Ack.object({'),
                contains("'text_field': Ack.string()"),
                contains("'number_field': Ack.integer()"),
                contains("'decimal_field': Ack.double()"),
                contains("'boolean_field': Ack.boolean()"),
                contains(
                  "'enum_field': Ack.string().enumString(['active', 'inactive'])",
                ),
                contains("'list_field': Ack.list(Ack.string())"),
                contains(
                  "'nullable_field': Ack.string().optional().nullable()",
                ),
              ]),
            ),
          },
        );
      });
    });
  });
}
