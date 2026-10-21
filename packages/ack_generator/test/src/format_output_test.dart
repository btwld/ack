import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  test('restoring augment names a class that is neither final nor sealed', () {
    final builder = ackModelBuilder(BuilderOptions.empty) as PartBuilder;

    expect(
      () =>
          builder.formatOutput('augment class Product {}\n', Version(3, 14, 0)),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Product'),
        ),
      ),
    );
  });
}
