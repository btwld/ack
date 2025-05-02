import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  group('Schema parse methods', () {
    final builder = schemaModelBuilder(BuilderOptions.empty);

    test('generated schema includes parse methods in generated code', () async {
      const userModel = '''
import 'package:ack_generator/ack_generator.dart';

@Schema(
  description: 'A test user model',
)
class User {
  @IsNotEmpty()
  final String name;
  
  @Min(18)
  final int age;
  
  User({
    required this.name,
    required this.age,
  });
}
''';

      await testBuilder(
        builder,
        {
          'a|lib/user_model.dart': userModel,
        },
        outputs: {
          'a|lib/user_model.g.dart': decodedMatches(
            allOf([
              contains('class UserSchema extends SchemaModel<User>'),
              // Check for parse method components
              contains('User parse(Object? input, {String? debugName})'),
              contains('Throws an [AckException] if validation fails'),
              contains('result.isOk ? toModel() : null'),
              contains('tryParse(Object? input, {String? debugName})'),
              contains(
                'Attempts to parse the input and returns a User instance',
              ),
            ]),
          ),
        },
        reader: await PackageAssetReader.currentIsolate(),
      );
    });
  });
}
