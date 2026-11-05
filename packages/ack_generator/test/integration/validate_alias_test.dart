// The only test of the deprecated `Validate` alias. Delete it with `Validate`.
// ignore_for_file: deprecated_member_use

import 'package:ack/annotations.dart';
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

/// Builds [source] as `lib/model.dart`, which must fail, and returns the
/// build errors.
Future<List<String>> _errors(String source) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  final result = await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {'test_pkg|lib/model.dart': source},
    generateFor: const {'test_pkg|lib/model.dart'},
    readerWriter: readerWriter,
  );
  expect(result.succeeded, isFalse);

  return result.errors.toList();
}

/// One model that uses every rule, written with [rule] for each annotation.
String _model(String Function(String oldName, String newName) rule) =>
    '''
import 'package:ack/ack.dart';

part 'model.g.dart';

@Schemable()
final class Profile with _\$ProfileAck {
  const Profile({
    required this.nickname,
    this.bio,
    this.title = 'none',
    required this.score,
    required this.ratio,
    required this.debt,
    required this.handle,
    required this.code,
    required this.email,
    required this.website,
    required this.resource,
    required this.id,
    required this.birthDate,
    required this.createdAt,
    required this.anyIp,
    required this.clientIp,
    required this.v4,
    required this.v6,
    required this.tags,
    required this.labels,
    ${rule('Validate.minLength(1)', 'HasMinLength(1)')} required this.alias,
  });

  ${rule('Validate.required()', 'IsRequired()')}
  final String? nickname;

  ${rule('Validate.notNull()', 'IsNotNull()')}
  final String? bio;

  ${rule('Validate.optional()', 'IsOptional()')}
  final String title;

  ${rule('Validate.min(0)', 'HasMin(0)')}
  ${rule('Validate.max(100)', 'HasMax(100)')}
  ${rule('Validate.multipleOf(5)', 'IsMultipleOf(5)')}
  ${rule('Validate.positive()', 'IsPositive()')}
  final int score;

  ${rule('Validate.min(0.5)', 'HasMin(0.5)')}
  ${rule('Validate.max(1.5)', 'HasMax(1.5)')}
  final double ratio;

  ${rule('Validate.negative()', 'IsNegative()')}
  final num debt;

  ${rule('Validate.minLength(2)', 'HasMinLength(2)')}
  ${rule('Validate.maxLength(20)', 'HasMaxLength(20)')}
  final String handle;

  ${rule('Validate.notEmpty()', 'IsNotEmpty()')}
  ${rule("Validate.matches('[A-Z]+')", "HasMatch('[A-Z]+')")}
  final String code;

  ${rule('Validate.email()', 'IsEmail()')}
  final String email;

  ${rule('Validate.url()', 'IsUrl()')}
  final String website;

  ${rule('Validate.uri()', 'IsUri()')}
  final String resource;

  ${rule('Validate.uuid()', 'IsUuid()')}
  final String id;

  ${rule('Validate.date()', 'IsDate()')}
  final String birthDate;

  ${rule('Validate.dateTime()', 'IsDateTime()')}
  final String createdAt;

  ${rule('Validate.ip()', 'IsIp()')}
  final String anyIp;

  ${rule('Validate.ip(version: 6)', 'IsIp(version: 6)')}
  final String clientIp;

  ${rule('Validate.ipv4()', 'IsIp(version: 4)')}
  final String v4;

  ${rule('Validate.ipv6()', 'IsIp(version: 6)')}
  final String v6;

  ${rule('Validate.notEmpty()', 'IsNotEmpty()')}
  ${rule('Validate.minItems(1)', 'HasMinItems(1)')}
  ${rule('Validate.maxItems(5)', 'HasMaxItems(5)')}
  ${rule('Validate.uniqueItems()', 'HasUniqueItems()')}
  ${rule('Validate.email()', 'IsEmail()')}
  final List<String> tags;

  ${rule('Validate.minItems(1)', 'HasMinItems(1)')}
  final Set<String> labels;

  final String alias;
}
''';

void main() {
  test('Validate constructors return the matching rule annotations', () {
    expect(identical(const Validate.optional(), const IsOptional()), isTrue);
    expect(identical(const Validate.required(), const IsRequired()), isTrue);
    expect(identical(const Validate.notNull(), const IsNotNull()), isTrue);
    expect(identical(const Validate.min(1), const HasMin(1)), isTrue);
    expect(identical(const Validate.max(9.5), const HasMax(9.5)), isTrue);
    expect(
      identical(const Validate.multipleOf(2), const IsMultipleOf(2)),
      isTrue,
    );
    expect(identical(const Validate.positive(), const IsPositive()), isTrue);
    expect(identical(const Validate.negative(), const IsNegative()), isTrue);
    expect(
      identical(const Validate.minLength(1), const HasMinLength(1)),
      isTrue,
    );
    expect(
      identical(const Validate.maxLength(9), const HasMaxLength(9)),
      isTrue,
    );
    expect(
      identical(const Validate.matches('^a'), const HasMatch('^a')),
      isTrue,
    );
    expect(identical(const Validate.notEmpty(), const IsNotEmpty()), isTrue);
    expect(identical(const Validate.email(), const IsEmail()), isTrue);
    expect(identical(const Validate.url(), const IsUrl()), isTrue);
    expect(identical(const Validate.uri(), const IsUri()), isTrue);
    expect(identical(const Validate.uuid(), const IsUuid()), isTrue);
    expect(identical(const Validate.date(), const IsDate()), isTrue);
    expect(identical(const Validate.dateTime(), const IsDateTime()), isTrue);
    expect(identical(const Validate.ip(), const IsIp()), isTrue);
    expect(
      identical(const Validate.ip(version: 4), const IsIp(version: 4)),
      isTrue,
    );
    expect(identical(const Validate.minItems(1), const HasMinItems(1)), isTrue);
    expect(identical(const Validate.maxItems(5), const HasMaxItems(5)), isTrue);
    expect(
      identical(const Validate.uniqueItems(), const HasUniqueItems()),
      isTrue,
    );

    // ipv4() and ipv6() have no rule class of their own.
    expect(
      const Validate.ipv4(),
      isA<IsIp>().having((rule) => rule.version, 'version', 4),
    );
    expect(
      const Validate.ipv6(),
      isA<IsIp>().having((rule) => rule.version, 'version', 6),
    );

    // The deprecated fields still describe the rule.
    const minLength = Validate.minLength(3);
    expect((minLength.kind, minLength.value), ('minLength', 3));
    const ipv4 = Validate.ipv4();
    expect((ipv4.kind, ipv4.value), ('ip', 4));
  });

  test('old and new annotations generate identical code', () async {
    final legacy = await _generate(_model((oldName, _) => '@$oldName'));
    final current = await _generate(_model((_, newName) => '@$newName'));

    expect(legacy, current);
    expect(legacy, isNot(contains(RegExp(r'\bValidate\b'))));
    expect(legacy, contains('.ip(version: 4)'));
  });

  test('a misplaced old annotation reports the new name', () async {
    final errors = await _errors(r'''
import 'package:ack/ack.dart';

part 'model.g.dart';

@Schemable()
final class Profile with _$ProfileAck {
  const Profile(this.age);

  @Validate.minLength(2)
  final int age;
}
''');

    expect(
      errors,
      contains(
        contains('Profile.age has @HasMinLength on int; use @HasMin instead.'),
      ),
    );
  });
}
