import 'package:ack/ack.dart';
import 'package:ack/annotations.dart' as annotations;
import 'package:test/test.dart';

void main() {
  test('package:ack/ack.dart leaves dart:core Pattern visible', () {
    final Pattern pattern = RegExp('a');

    expect(pattern.allMatches('banana'), hasLength(3));
  });

  test('package:ack/ack.dart exports the generation annotations', () {
    const values = <Object>[
      Schemable(),
      AckField(description: 'id'),
      Required(),
      Optional(),
      NotNull(),
      Matches('^a'),
      MinLength(1),
      UniqueItems(),
      JsonKey(name: 'id'),
    ];

    expect(values, hasLength(9));
    expect(const Matches('^a').pattern, '^a');
  });

  test('the deprecated Pattern spelling creates a Matches annotation', () {
    // ignore: deprecated_member_use_from_same_package
    const annotation = annotations.Pattern('^a');

    expect(annotation, isA<Matches>());
    expect(annotation.pattern, '^a');
  });
}
