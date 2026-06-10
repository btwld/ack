import 'package:ack/ack.dart';
import 'package:standard_schema/utils.dart';
import 'package:test/test.dart';

void main() {
  test('getDotPath renders nested ack issue paths as spec dot-paths', () {
    final schema = Ack.object({
      'user': Ack.object({
        'tags': Ack.list(Ack.string().minLength(2)),
        'age': Ack.integer(),
      }),
    });

    final result = schema.standard.validate({
      'user': {
        'tags': ['ok', 'x'],
        'age': 'old',
      },
    });

    final failure = result as StandardFailure<JsonMap?>;

    expect(failure.issues.map(getDotPath).toList(), [
      'user.tags.1',
      'user.age',
    ]);
  });
}
