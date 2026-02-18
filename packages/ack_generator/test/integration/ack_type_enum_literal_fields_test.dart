import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('@AckType with enumString, literal, and enumValues fields', () {
    test('enumString field generates String getter', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final reviewSchema = Ack.object({
  'file': Ack.string(),
  'severity': Ack.enumString(['error', 'warning', 'info']),
  'message': Ack.string(),
});
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('extension type ReviewType(Map<String, Object?> _data)'),
              contains('String get file'),
              contains("_data['file'] as String"),
              contains('String get severity'),
              contains("_data['severity'] as String"),
              contains('String get message'),
              contains("_data['message'] as String"),
            ]),
          ),
        },
      );
    });

    test('literal field generates String getter', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final eventSchema = Ack.object({
  'type': Ack.literal('click'),
  'target': Ack.string(),
});
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('extension type EventType(Map<String, Object?> _data)'),
              contains('String get type'),
              contains("_data['type'] as String"),
              contains('String get target'),
              contains("_data['target'] as String"),
            ]),
          ),
        },
      );
    });

    test('enumValues<T> field generates enum type getter', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

enum UserRole { admin, editor, viewer }

@AckType()
final userSchema = Ack.object({
  'name': Ack.string(),
  'role': Ack.enumValues<UserRole>(UserRole.values),
});
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('extension type UserType(Map<String, Object?> _data)'),
              contains('String get name'),
              contains('UserRole get role'),
              contains("_data['role'] as UserRole"),
            ]),
          ),
        },
      );
    });

    test(
      'enumString with optional().nullable() generates String? getter',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final formSchema = Ack.object({
  'title': Ack.string(),
  'priority': Ack.enumString(['low', 'medium', 'high']).optional().nullable(),
});
''',
          },
          outputs: {
            'test_pkg|lib/schema.g.dart': decodedMatches(
              allOf([
                contains('extension type FormType(Map<String, Object?> _data)'),
                contains('String get title'),
                contains('String? get priority'),
                contains("_data['priority'] as String?"),
              ]),
            ),
          },
        );
      },
    );

    test('enumValues<T> with optional() generates T? getter', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

enum Priority { low, medium, high, critical }

@AckType()
final taskSchema = Ack.object({
  'title': Ack.string(),
  'priority': Ack.enumValues<Priority>(Priority.values).optional(),
});
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('extension type TaskType(Map<String, Object?> _data)'),
              contains('String get title'),
              contains('Priority? get priority'),
              contains("_data['priority'] as Priority?"),
            ]),
          ),
        },
      );
    });

    test('Ack.list(Ack.enumString()) generates List<String> getter', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final configSchema = Ack.object({
  'name': Ack.string(),
  'tags': Ack.list(Ack.enumString(['a', 'b', 'c'])),
});
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('extension type ConfigType(Map<String, Object?> _data)'),
              contains('String get name'),
              contains('List<String> get tags'),
              contains("_\$ackListCast<String>(_data['tags'])"),
            ]),
          ),
        },
      );
    });

    test('Ack.list(Ack.enumValues<T>()) generates List<T> getter', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

enum UserRole { admin, editor, viewer }

@AckType()
final teamSchema = Ack.object({
  'name': Ack.string(),
  'roles': Ack.list(Ack.enumValues<UserRole>(UserRole.values)),
});
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('extension type TeamType(Map<String, Object?> _data)'),
              contains('String get name'),
              contains('List<UserRole> get roles'),
              contains("_\$ackListCast<UserRole>(_data['roles'])"),
            ]),
          ),
        },
      );
    });

    test(
      'enumValues with imported prefixed enum keeps prefixed field type',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/enums.dart': '''
enum UserRole { admin, editor, viewer }
''',
            'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'enums.dart' as models;

@AckType()
final userSchema = Ack.object({
  'role': Ack.enumValues(models.UserRole.values),
});
''',
          },
          outputs: {
            'test_pkg|lib/schema.g.dart': decodedMatches(
              allOf([
                contains('extension type UserType(Map<String, Object?> _data)'),
                contains('models.UserRole get role'),
                contains("_data['role'] as models.UserRole"),
                contains('models.UserRole? role'),
              ]),
            ),
          },
        );
      },
    );

    test(
      'top-level list enumValues preserves imported prefixed enum type',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/enums.dart': '''
enum UserRole { admin, editor, viewer }
''',
            'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'enums.dart' as models;

@AckType()
final roleListSchema = Ack.list(Ack.enumValues(models.UserRole.values));
''',
          },
          outputs: {
            'test_pkg|lib/schema.g.dart': decodedMatches(
              allOf([
                contains(
                  'extension type RoleListType(List<models.UserRole> _value)',
                ),
                contains('implements List<models.UserRole>'),
                contains('RoleListType(validated as List<models.UserRole>)'),
              ]),
            ),
          },
        );
      },
    );

    test(
      'list enumValues with imported prefixed enum keeps prefixed copyWith type',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/enums.dart': '''
enum UserRole { admin, editor, viewer }
''',
            'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'enums.dart' as models;

@AckType()
final teamSchema = Ack.object({
  'roles': Ack.list(Ack.enumValues(models.UserRole.values)),
});
''',
          },
          outputs: {
            'test_pkg|lib/schema.g.dart': decodedMatches(
              allOf([
                contains('List<models.UserRole> get roles'),
                contains('List<models.UserRole>? roles'),
              ]),
            ),
          },
        );
      },
    );

    test(
      'mixed schema with literal, enumString, enumValues, and string fields',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

enum Color { red, green, blue }

@AckType()
final widgetSchema = Ack.object({
  'type': Ack.literal('button'),
  'label': Ack.string(),
  'color': Ack.enumValues<Color>(Color.values),
  'style': Ack.enumString(['solid', 'outline', 'ghost']),
});
''',
          },
          outputs: {
            'test_pkg|lib/schema.g.dart': decodedMatches(
              allOf([
                contains(
                  'extension type WidgetType(Map<String, Object?> _data)',
                ),
                contains('String get type'),
                contains("_data['type'] as String"),
                contains('String get label'),
                contains("_data['label'] as String"),
                contains('Color get color'),
                contains("_data['color'] as Color"),
                contains('String get style'),
                contains("_data['style'] as String"),
              ]),
            ),
          },
        );
      },
    );

    test(
      'enumValues infers enum type from variable and property inputs',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

enum UserRole { admin, editor, viewer }

final roleValues = UserRole.values;

class RoleHolder {
  const RoleHolder(this.values);
  final List<UserRole> values;
}

const holder = RoleHolder(UserRole.values);

@AckType()
final userSchema = Ack.object({
  'roleFromVar': Ack.enumValues(roleValues),
  'roleFromProp': Ack.enumValues(holder.values),
});
''',
          },
          outputs: {
            'test_pkg|lib/schema.g.dart': decodedMatches(
              allOf([
                contains('UserRole get roleFromVar'),
                contains("_data['roleFromVar'] as UserRole"),
                contains('UserRole get roleFromProp'),
                contains("_data['roleFromProp'] as UserRole"),
              ]),
            ),
          },
        );
      },
    );
  });
}
