import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'test_utils/test_assets.dart';

void main() {
  group('Enum Support Tests', () {
    test('should generate schema for simple enum field', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

enum Status { active, inactive, pending }

@AckModel()
class User {
  final String name;
  final Status status;
  
  User({required this.name, required this.status});
}
''',
        },
        outputs: {
          'test_pkg|lib/model.g.dart': decodedMatches(
            allOf([
              contains('final userSchema = Ack.object('),
              contains("'name': Ack.string()"),
              contains(
                "'status': Ack.string().enumString(['active', 'inactive', 'pending'])",
              ),
            ]),
          ),
        },
      );
    });

    test('should handle nullable enum fields', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

enum Priority { low, medium, high }

@AckModel()
class Task {
  final String title;
  final Priority? priority;
  
  Task({required this.title, this.priority});
}
''',
        },
        outputs: {
          'test_pkg|lib/model.g.dart': decodedMatches(
            allOf([
              contains('final taskSchema = Ack.object('),
              contains("'title': Ack.string()"),
              contains("'priority': Ack.string()"),
              contains(".enumString(['low', 'medium', 'high'])"),
              contains('.optional()'),
              contains('.nullable()'),
            ]),
          ),
        },
      );
    });
  });
}
