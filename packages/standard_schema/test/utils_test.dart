import 'package:standard_schema/standard_schema.dart';
import 'package:standard_schema/utils.dart';
import 'package:test/test.dart';

void main() {
  group('getDotPath', () {
    test('returns null when the issue has no path', () {
      expect(getDotPath(const StandardIssue(message: 'm')), isNull);
      expect(getDotPath(const StandardIssue(message: 'm', path: [])), isNull);
    });

    test('returns null when a segment is not a string or number', () {
      // `true` stands in for any non-string/number segment (the spec's symbol
      // form); `getDotPath` bails out rather than rendering it.
      expect(
        getDotPath(const StandardIssue(message: 'm', path: [true])),
        isNull,
      );
    });

    test('joins string and number segments with dots', () {
      expect(
        getDotPath(const StandardIssue(message: 'm', path: ['a', 'b'])),
        'a.b',
      );
      expect(
        getDotPath(const StandardIssue(message: 'm', path: ['a', 0, 'b'])),
        'a.0.b',
      );
      expect(
        getDotPath(
          const StandardIssue(
            message: 'm',
            path: ['nested', 0, 'dot', 0, 'path'],
          ),
        ),
        'nested.0.dot.0.path',
      );
    });
  });

  group('StandardSchemaError', () {
    test('wraps issues and exposes the first issue message', () {
      const issues = [
        StandardIssue(message: 'first', path: ['a']),
        StandardIssue(message: 'second'),
      ];
      final error = StandardSchemaError(issues);

      expect(error, isA<Exception>());
      expect(error.issues, same(issues));
      expect(error.message, 'first');
      expect(error.toString(), 'StandardSchemaError: first');
    });

    test('throws when constructed with no issues', () {
      expect(() => StandardSchemaError(const []), throwsArgumentError);
    });
  });
}
