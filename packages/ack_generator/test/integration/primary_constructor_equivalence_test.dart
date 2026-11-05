import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

/// Builds [source] as `lib/model.dart` and returns the generated part.
Future<String> _generate(String source) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  String? generated;
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {'test_pkg|lib/model.dart': source},
    generateFor: const {'test_pkg|lib/model.dart'},
    readerWriter: readerWriter,
    outputs: {
      'test_pkg|lib/model.g.dart': decodedMatches(
        predicate<String>((output) {
          generated = output;

          return true;
        }),
      ),
    },
  );

  return generated!;
}

const _header = r'''
// @dart=3.13
import 'package:ack/ack.dart';

part 'model.g.dart';
''';

/// Rule annotations, `@AckKey`, and descriptions on declaring parameters.
const _primaryModels =
    '''
$_header
@Schemable(caseStyle: AckCaseStyle.snake)
final class const Account({
  /// @description The name shown to other users.
  @AckKey('name')
  @HasMinLength(2)
  @HasMaxLength(40)
  required final String displayName,
  @IsEmail() required final String email,
  @IsOptional() @IsNotNull() final String? nickname,
  @HasMin(0) @IsMultipleOf(1) final int age = 0,
  @IsNotEmpty() @HasUniqueItems() final List<String> tags = const ['new'],
  @IsUri() final String? website,
  final JsonMaybe<String> bio = const JsonMaybe.absent(),
}) with _\$AccountAck {
  static final schema = AccountSchema.schema;
  static final fromJson = AccountSchema.fromJson;
}

@Schemable(discriminatorKey: 'type')
sealed class const Pet({@IsUuid() required final String id}) with _\$PetAck;

@Schemable(discriminatorValue: 'cat')
final class const Cat({
  required super.id,
  @HasMin(1) @HasMax(9) required final int lives,
}) extends Pet with _\$CatAck;

final class const Dog({required super.id, required final String breed})
    extends Pet with _\$DogAck;
''';

/// The same models with classic constructors and annotated fields.
const _classicModels =
    '''
$_header
@Schemable(caseStyle: AckCaseStyle.snake)
final class Account with _\$AccountAck {
  const Account({
    required this.displayName,
    required this.email,
    this.nickname,
    this.age = 0,
    this.tags = const ['new'],
    this.website,
    this.bio = const JsonMaybe.absent(),
  });

  /// @description The name shown to other users.
  @AckKey('name')
  @HasMinLength(2)
  @HasMaxLength(40)
  final String displayName;

  @IsEmail()
  final String email;

  @IsOptional()
  @IsNotNull()
  final String? nickname;

  @HasMin(0)
  @IsMultipleOf(1)
  final int age;

  @IsNotEmpty()
  @HasUniqueItems()
  final List<String> tags;

  @IsUri()
  final String? website;

  final JsonMaybe<String> bio;

  static final schema = AccountSchema.schema;
  static final fromJson = AccountSchema.fromJson;
}

@Schemable(discriminatorKey: 'type')
sealed class Pet with _\$PetAck {
  const Pet({required this.id});

  @IsUuid()
  final String id;
}

@Schemable(discriminatorValue: 'cat')
final class Cat extends Pet with _\$CatAck {
  const Cat({required super.id, required this.lives});

  @HasMin(1)
  @HasMax(9)
  final int lives;
}

final class Dog extends Pet with _\$DogAck {
  const Dog({required super.id, required this.breed});

  final String breed;
}
''';

void main() {
  test('primary and classic constructors generate identical code', () async {
    final primary = await _generate(_primaryModels);
    final classic = await _generate(_classicModels);

    expect(primary, classic);
    // The rules, wire key, and description reached the generated schema.
    final compact = primary.replaceAll(RegExp(r'\s+'), '');
    expect(
      compact,
      contains(
        "'name':Ack.string().minLength(2).maxLength(40)"
        ".describe('Thenameshowntootherusers.')",
      ),
    );
    expect(compact, contains("'email':Ack.string().email()"));
    expect(
      compact,
      contains("'nickname':Ack.string().optional().nullable(value:false)"),
    );
    expect(compact, contains("'id':Ack.string().uuid()"));
    expect(compact, contains("'lives':Ack.integer().min(1).max(9)"));
  });
}
