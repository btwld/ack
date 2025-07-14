import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'test_utils/test_assets.dart';

void main() {
  group('SchemaModel Generation Comprehensive Tests', () {
    group('Basic SchemaModel Generation', () {
      test('should generate SchemaModel with singleton pattern', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/user.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'user.g.dart';

@AckModel(model: true, description: 'User model with SchemaModel')
class User {
  final String name;
  final int age;
  final String? email;
  
  User({required this.name, required this.age, this.email});
}
''',
          },
          outputs: {
            'test_pkg|lib/user.g.dart': decodedMatches(allOf([
              // Schema variable
              contains('final userSchema = Ack.object({'),
              contains("'name': Ack.string()"),
              contains("'age': Ack.integer()"),
              contains("'email': Ack.string().optional()"),

              // SchemaModel class structure
              contains('/// Generated SchemaModel for [User].'),
              contains('/// User model with SchemaModel'),
              contains('class UserSchemaModel extends SchemaModel<User>'),

              // Singleton pattern
              contains('UserSchemaModel._();'),
              contains('factory UserSchemaModel() {'),
              contains('return _instance;'),
              contains('static final _instance = UserSchemaModel._();'),

              // schema property
              contains('@override'),
              contains('ObjectSchema get schema {'),
              contains('return userSchema;'),

              // createFromMap method
              contains('@override'),
              contains('User createFromMap(Map<String, dynamic> map) {'),
              contains('return User('),
              contains('name: map[\'name\'] as String,'),
              contains('age: map[\'age\'] as int,'),
              contains('email: map[\'email\'] as String?,'),
            ])),
          },
        );
      });

      test('should handle nullable and optional fields correctly', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/optional_fields.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'optional_fields.g.dart';

@AckModel(model: true)
class OptionalFieldsModel {
  final String required;
  final String? nullable;
  final int? nullableInt;
  final List<String>? nullableList;
  final bool defaulted;
  
  OptionalFieldsModel({
    required this.required,
    this.nullable,
    this.nullableInt,
    this.nullableList,
    this.defaulted = false,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/optional_fields.g.dart': decodedMatches(allOf([
              // Schema with nullable fields
              contains('final optionalFieldsModelSchema = Ack.object({'),
              contains("'required': Ack.string()"),
              contains("'nullable': Ack.string().optional().nullable()"),
              contains("'nullableInt': Ack.integer().optional().nullable()"),
              contains(
                  "'nullableList': Ack.list(Ack.string()).optional().nullable()"),
              contains("'defaulted': Ack.boolean()"),

              // createFromMap with proper nullable handling
              contains('return OptionalFieldsModel('),
              contains('required: map[\'required\'] as String,'),
              contains('nullable: map[\'nullable\'] as String?,'),
              contains('nullableInt: map[\'nullableInt\'] as int?,'),
              contains('nullableList: (map[\'nullableList\'] as List?)?.cast<String>(),'),
              contains('defaulted: map[\'defaulted\'] as bool,'),
            ])),
          },
        );
      });
    });

    group('Complex Field Types', () {
      test('should handle nested models in SchemaModel', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/nested.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'nested.g.dart';

@AckModel(model: true)
class Address {
  final String street;
  final String city;
  final String? postalCode;
  
  Address({required this.street, required this.city, this.postalCode});
}

@AckModel(model: true)
class Company {
  final String name;
  final Address headquarters;
  final List<Address> offices;
  
  Company({required this.name, required this.headquarters, required this.offices});
}
''',
          },
          outputs: {
            'test_pkg|lib/nested.g.dart': decodedMatches(allOf([
              // Address schema
              contains('final addressSchema = Ack.object({'),
              contains("'street': Ack.string()"),
              contains("'city': Ack.string()"),
              contains("'postalCode': Ack.string().optional().nullable()"),

              // Company schema with nested reference
              contains('final companySchema = Ack.object({'),
              contains("'name': Ack.string()"),
              contains("'headquarters': addressSchema"),
              contains("'offices': Ack.list(addressSchema)"),

              // Address SchemaModel createFromMap
              contains('class AddressSchemaModel extends SchemaModel<Address>'),
              contains('return Address('),
              contains('street: map[\'street\'] as String,'),
              contains('city: map[\'city\'] as String,'),
              contains('postalCode: map[\'postalCode\'] as String?,'),

              // Company SchemaModel with nested model handling
              contains('class CompanySchemaModel extends SchemaModel<Company>'),
              contains('return Company('),
              contains('name: map[\'name\'] as String,'),
              contains(
                  'headquarters: AddressSchemaModel._instance.createFromMap('),
              contains('map[\'headquarters\'] as Map<String, dynamic>'),
              contains('offices: (map[\'offices\'] as List)'),
              contains('AddressSchemaModel._instance.createFromMap('),
            ])),
          },
        );
      });

      test('should handle enums in SchemaModel', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/enum_model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'enum_model.g.dart';

enum Status { pending, approved, rejected }
enum Priority { low, medium, high }

@AckModel(model: true)
class Task {
  final String title;
  final Status status;
  final Priority? priority;
  
  Task({required this.title, required this.status, this.priority});
}
''',
          },
          outputs: {
            'test_pkg|lib/enum_model.g.dart': decodedMatches(allOf([
              // Schema with enums
              contains('final taskSchema = Ack.object({'),
              contains("'title': Ack.string()"),
              contains(
                  "'status': Ack.string().enumString(['pending', 'approved', 'rejected'])"),
              contains("'priority': Ack.string()"),
              contains(".enumString(['low', 'medium', 'high'])"),
              contains('.optional()'),
              contains('.nullable()'),

              // createFromMap with enum handling
              contains('return Task('),
              contains('title: map[\'title\'] as String,'),
              contains(
                  'status: Status.values.byName(map[\'status\'] as String),'),
              contains('priority: map[\'priority\'] != null'),
              contains('Priority.values.byName(map[\'priority\'] as String)'),
            ])),
          },
        );
      });

      test('should handle collections (List, Set, Map) in SchemaModel',
          () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/collections.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'collections.g.dart';

@AckModel(model: true)
class CollectionsModel {
  final List<String> tags;
  final Set<int> ids;
  final Map<String, String> metadata;
  final List<String>? optionalTags;
  final Set<double>? optionalScores;
  final Map<String, bool>? optionalFlags;
  
  CollectionsModel({
    required this.tags,
    required this.ids,
    required this.metadata,
    this.optionalTags,
    this.optionalScores,
    this.optionalFlags,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/collections.g.dart': decodedMatches(allOf([
              // Schema with collections
              contains('final collectionsModelSchema = Ack.object({'),
              contains("'tags': Ack.list(Ack.string())"),
              contains("'ids': Ack.list(Ack.integer()).unique()"),
              contains(
                  "'metadata': Ack.object({}, additionalProperties: true)"),
              contains(
                  "'optionalTags': Ack.list(Ack.string()).optional().nullable()"),
              contains(
                  "'optionalScores': Ack.list(Ack.double()).unique().optional().nullable()"),
              contains("'optionalFlags': Ack.object("),
              contains('additionalProperties: true'),
              contains(').optional().nullable()'),

              // createFromMap with collection handling
              contains('return CollectionsModel('),
              contains('tags: (map[\'tags\'] as List).cast<String>(),'),
              contains('ids: (map[\'ids\'] as List).cast<int>().toSet(),'),
              contains('metadata: map[\'metadata\'] as Map<String, String>,'),
              contains('optionalTags: (map[\'optionalTags\'] as List?)?.cast<String>(),'),
              contains(
                  'optionalScores: (map[\'optionalScores\'] as List?)?.cast<double>().toSet(),'),
              contains(
                  'optionalFlags: map[\'optionalFlags\'] as Map<String, bool>?,'),
            ])),
          },
        );
      });
    });

    group('Additional Properties Support', () {
      test('should handle additional properties in SchemaModel', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/additional_props.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'additional_props.g.dart';

@AckModel(
  model: true,
  additionalProperties: true,
  additionalPropertiesField: 'extraData'
)
class FlexibleModel {
  final String name;
  final int version;
  final Map<String, dynamic> extraData;
  
  FlexibleModel({
    required this.name,
    required this.version,
    required this.extraData,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/additional_props.g.dart': decodedMatches(allOf([
              // Schema with additional properties
              contains('final flexibleModelSchema = Ack.object({'),
              contains("'name': Ack.string()"),
              contains("'version': Ack.integer()"),
              contains('}, additionalProperties: true)'),

              // createFromMap with additional properties extraction
              contains('return FlexibleModel('),
              contains('name: map[\'name\'] as String,'),
              contains('version: map[\'version\'] as int,'),
              contains('extraData: extractAdditionalProperties(map, {'),
              contains("'name', 'version'"),
              contains('}),'),
            ])),
          },
        );
      });
    });

    group('Generation Order and Dependencies', () {
      test(
          'should generate schemas before SchemaModels for dependency resolution',
          () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/dependency_order.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'dependency_order.g.dart';

@AckModel(model: true)
class Department {
  final String name;
  Department({required this.name});
}

@AckModel(model: true)
class Employee {
  final String name;
  final Department department;
  Employee({required this.name, required this.department});
}

@AckModel(model: true)
class Company {
  final String name;
  final List<Department> departments;
  final List<Employee> employees;
  Company({required this.name, required this.departments, required this.employees});
}
''',
          },
          outputs: {
            'test_pkg|lib/dependency_order.g.dart': decodedMatches(allOf([
              // Verify schema variables come first (can use regex for order)
              matches(RegExp(
                r'final departmentSchema.*?'
                r'final employeeSchema.*?'
                r'final companySchema.*?'
                r'class DepartmentSchemaModel.*?'
                r'class EmployeeSchemaModel.*?'
                r'class CompanySchemaModel',
                multiLine: true,
                dotAll: true,
              )),

              // Schemas reference each other correctly
              contains("'department': departmentSchema"),
              contains("'departments': Ack.list(departmentSchema)"),
              contains("'employees': Ack.list(employeeSchema)"),

              // SchemaModels reference each other correctly
              contains('DepartmentSchemaModel._instance.createFromMap('),
              contains('EmployeeSchemaModel._instance.createFromMap('),
            ])),
          },
        );
      });
    });

    group('Error Handling in SchemaModel', () {
      test('should generate type-safe createFromMap without runtime exceptions',
          () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/type_safe.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'type_safe.g.dart';

@AckModel(model: true)
class TypeSafeModel {
  final String text;
  final int number;
  final bool flag;
  final double decimal;
  final List<String> items;
  
  TypeSafeModel({
    required this.text,
    required this.number,
    required this.flag,
    required this.decimal,
    required this.items,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/type_safe.g.dart': decodedMatches(allOf([
              // Type-safe casts without dynamic
              contains('text: map[\'text\'] as String,'),
              contains('number: map[\'number\'] as int,'),
              contains('flag: map[\'flag\'] as bool,'),
              contains('decimal: map[\'decimal\'] as double,'),
              contains('items: (map[\'items\'] as List).cast<String>(),'),

              // No dynamic types or unsafe operations
              isNot(contains('as dynamic')),
              isNot(contains('toString()')),
              isNot(contains('runtimeType')),
            ])),
          },
        );
      });
    });

    group('Custom Schema Names', () {
      test('should respect custom schema names in SchemaModel references',
          () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/custom_names.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'custom_names.g.dart';

@AckModel(schemaName: 'PersonValidationSchema', model: true)
class Person {
  final String name;
  final int age;
  Person({required this.name, required this.age});
}

@AckModel(schemaName: 'OrganizationValidationSchema', model: true)
class Organization {
  final String name;
  final Person owner;
  final List<Person> members;
  Organization({required this.name, required this.owner, required this.members});
}
''',
          },
          outputs: {
            'test_pkg|lib/custom_names.g.dart': decodedMatches(allOf([
              // Custom schema variable names
              contains('final personValidationSchema = Ack.object({'),
              contains('final organizationValidationSchema = Ack.object({'),

              // References use original schema names in object definition
              contains("'owner': personSchema"),
              contains("'members': Ack.list(personSchema)"),

              // SchemaModel schema property returns custom schema
              contains('return personValidationSchema;'),
              contains('return organizationValidationSchema;'),
            ])),
          },
        );
      });
    });
  });
}
