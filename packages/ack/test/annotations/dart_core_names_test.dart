import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  test('package:ack/ack.dart leaves dart:core Pattern visible', () {
    final Pattern pattern = RegExp('a');
    const annotation = Schemable(name: 'Banana');

    expect(pattern.allMatches(annotation.name!.toLowerCase()), hasLength(3));
  });
}
