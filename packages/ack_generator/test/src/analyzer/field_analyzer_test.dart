import 'package:ack_annotations/ack_annotations.dart';
import 'package:ack_generator/src/analyzer/field_analyzer.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../../test_utils/test_assets.dart';

void main() {
  group('FieldAnalyzer', () {
    late FieldAnalyzer analyzer;

    setUp(() {
      analyzer = FieldAnalyzer();
    });

    test(
      'extracts SchemaKey and requiredness from constructor parameters',
      () async {
        final assets = {
          ...allAssets,
          'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable()
class User {
  final String name;
  final String? nickname;

  const User({
    @SchemaKey('user_name') required this.name,
    this.nickname,
  });
}
''',
        };

        await resolveSources(assets, (resolver) async {
          final library = await resolver.libraryFor(
            AssetId('test_pkg', 'lib/model.dart'),
          );
          final classElement = library.classes.firstWhere(
            (e) => e.name3 == 'User',
          );
          final constructor = classElement.constructors2.firstWhere(
            (c) => c.name3 == 'new',
          );

          final nameParameter = constructor.formalParameters.firstWhere(
            (p) => p.name3 == 'name',
          );
          final nicknameParameter = constructor.formalParameters.firstWhere(
            (p) => p.name3 == 'nickname',
          );

          final nameInfo = analyzer.analyze(
            nameParameter,
            caseStyle: CaseStyle.none,
          );
          final nicknameInfo = analyzer.analyze(
            nicknameParameter,
            caseStyle: CaseStyle.none,
          );

          expect(nameInfo.name, equals('name'));
          expect(nameInfo.jsonKey, equals('user_name'));
          expect(nameInfo.isRequired, isTrue);
          expect(nameInfo.isNullable, isFalse);
          expect(nicknameInfo.isRequired, isFalse);
          expect(nicknameInfo.isNullable, isTrue);
        });
      },
    );

    test('applies caseStyle when SchemaKey is not present', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable(caseStyle: CaseStyle.snakeCase)
class ApiPayload {
  final String userId;

  const ApiPayload({required this.userId});
}
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/model.dart'),
        );
        final classElement = library.classes.firstWhere(
          (e) => e.name3 == 'ApiPayload',
        );
        final constructor = classElement.constructors2.firstWhere(
          (c) => c.name3 == 'new',
        );
        final parameter = constructor.formalParameters.single;

        final fieldInfo = analyzer.analyze(
          parameter,
          caseStyle: CaseStyle.snakeCase,
        );

        expect(fieldInfo.jsonKey, equals('user_id'));
      });
    });

    test(
      'reads decorator constraints and descriptions from parameters',
      () async {
        final assets = {
          ...allAssets,
          'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable()
class Signup {
  final String email;
  final String? displayName;
  final int age;

  const Signup({
    @Description('Primary email address')
    @Email()
    required this.email,
    @MinLength(3)
    @MaxLength(20)
    this.displayName,
    @Min(13)
    @Max(120)
    required this.age,
  });
}
''',
        };

        await resolveSources(assets, (resolver) async {
          final library = await resolver.libraryFor(
            AssetId('test_pkg', 'lib/model.dart'),
          );
          final classElement = library.classes.firstWhere(
            (e) => e.name3 == 'Signup',
          );
          final constructor = classElement.constructors2.firstWhere(
            (c) => c.name3 == 'new',
          );

          final emailParameter = constructor.formalParameters.firstWhere(
            (p) => p.name3 == 'email',
          );
          final displayNameParameter = constructor.formalParameters.firstWhere(
            (p) => p.name3 == 'displayName',
          );
          final ageParameter = constructor.formalParameters.firstWhere(
            (p) => p.name3 == 'age',
          );

          final emailInfo = analyzer.analyze(
            emailParameter,
            caseStyle: CaseStyle.none,
          );
          final displayNameInfo = analyzer.analyze(
            displayNameParameter,
            caseStyle: CaseStyle.none,
          );
          final ageInfo = analyzer.analyze(
            ageParameter,
            caseStyle: CaseStyle.none,
          );

          expect(emailInfo.description, equals('Primary email address'));
          expect(emailInfo.constraints.map((c) => c.name), contains('email'));
          expect(
            displayNameInfo.constraints.map((c) => c.name),
            containsAll(['minLength', 'maxLength']),
          );
          expect(
            ageInfo.constraints.map((c) => c.name),
            containsAll(['min', 'max']),
          );
        });
      },
    );

    test(
      'marks defaulted named parameters as optional and non-nullable',
      () async {
        final assets = {
          ...allAssets,
          'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable()
class RetryPolicy {
  final int retries;

  const RetryPolicy({this.retries = 3});
}
''',
        };

        await resolveSources(assets, (resolver) async {
          final library = await resolver.libraryFor(
            AssetId('test_pkg', 'lib/model.dart'),
          );
          final classElement = library.classes.firstWhere(
            (e) => e.name3 == 'RetryPolicy',
          );
          final constructor = classElement.constructors2.firstWhere(
            (c) => c.name3 == 'new',
          );
          final retriesParameter = constructor.formalParameters.single;

          final fieldInfo = analyzer.analyze(
            retriesParameter,
            caseStyle: CaseStyle.none,
          );

          expect(fieldInfo.isRequired, isFalse);
          expect(fieldInfo.isNullable, isFalse);
        });
      },
    );
  });
}
