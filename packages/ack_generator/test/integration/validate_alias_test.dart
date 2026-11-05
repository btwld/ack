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
  test('Validate constructors return the rule annotations', () {
    // Each old constructor, the rule it returns (null when the rule keeps the
    // old kind), and the deprecated kind and value it exposed before 2.0.
    const cases = <(Validate, AckRule?, String, Object?)>[
      (Validate.optional(), IsOptional(), 'optional', null),
      (Validate.required(), IsRequired(), 'required', null),
      (Validate.notNull(), IsNotNull(), 'notNull', null),
      (Validate.min(1), HasMin(1), 'min', 1),
      (Validate.max(9.5), HasMax(9.5), 'max', 9.5),
      (Validate.multipleOf(2), IsMultipleOf(2), 'multipleOf', 2),
      (Validate.positive(), IsPositive(), 'positive', null),
      (Validate.negative(), IsNegative(), 'negative', null),
      (Validate.minLength(1), HasMinLength(1), 'minLength', 1),
      (Validate.maxLength(9), HasMaxLength(9), 'maxLength', 9),
      (Validate.matches('^a'), HasMatch('^a'), 'matches', '^a'),
      (Validate.notEmpty(), IsNotEmpty(), 'notEmpty', null),
      (Validate.email(), IsEmail(), 'email', null),
      (Validate.url(), IsUrl(), 'url', null),
      (Validate.uri(), IsUri(), 'uri', null),
      (Validate.uuid(), IsUuid(), 'uuid', null),
      (Validate.date(), IsDate(), 'date', null),
      (Validate.dateTime(), IsDateTime(), 'dateTime', null),
      (Validate.ip(), IsIp(), 'ip', null),
      (Validate.ip(version: 4), IsIp(version: 4), 'ip', 4),
      (Validate.ipv4(), null, 'ipv4', null),
      (Validate.ipv6(), null, 'ipv6', null),
      (Validate.minItems(1), HasMinItems(1), 'minItems', 1),
      (Validate.maxItems(5), HasMaxItems(5), 'maxItems', 5),
      (Validate.uniqueItems(), HasUniqueItems(), 'uniqueItems', null),
    ];

    for (final (old, rule, kind, value) in cases) {
      if (rule != null) expect(identical(old, rule), isTrue, reason: kind);
      expect((old.kind, old.value), (kind, value));
    }
    expect(const Validate.ipv4(), isA<IsIp>().having((r) => r.version, 'v', 4));
    expect(const Validate.ipv6(), isA<IsIp>().having((r) => r.version, 'v', 6));
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
