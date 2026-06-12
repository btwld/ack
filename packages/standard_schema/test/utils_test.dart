import 'package:standard_schema/standard_schema.dart';
import 'package:standard_schema/utils.dart';
import 'package:test/test.dart';

void main() {
  group('getDotPath', () {
    test('returns null when the issue has no path', () {
      expect(getDotPath(StandardIssue(message: 'm')), isNull);
      expect(getDotPath(StandardIssue(message: 'm', path: [])), isNull);
    });

    test('returns null when a segment is not a string or number', () {
      // `true` stands in for any non-string/number segment (the spec's symbol
      // form); `getDotPath` bails out rather than rendering it.
      expect(getDotPath(StandardIssue(message: 'm', path: [true])), isNull);
    });

    test('joins string and number segments with dots', () {
      expect(getDotPath(StandardIssue(message: 'm', path: ['a', 'b'])), 'a.b');
      expect(
        getDotPath(StandardIssue(message: 'm', path: ['a', 0, 'b'])),
        'a.0.b',
      );
      expect(
        getDotPath(
          StandardIssue(message: 'm', path: ['nested', 0, 'dot', 0, 'path']),
        ),
        'nested.0.dot.0.path',
      );
    });

    test('joins path segment objects by their keys', () {
      expect(
        getDotPath(
          StandardIssue(
            message: 'm',
            path: [
              StandardPathSegment(key: 'items'),
              StandardPathSegment(key: 1),
              'name',
            ],
          ),
        ),
        'items.1.name',
      );
    });

    test(
      'returns null when a path segment object key is not string or number',
      () {
        expect(
          getDotPath(
            StandardIssue(
              message: 'm',
              path: [StandardPathSegment(key: #field)],
            ),
          ),
          isNull,
        );
      },
    );
  });

  group('StandardSchemaError', () {
    test('wraps issues and exposes the first issue message', () {
      final issues = [
        StandardIssue(message: 'first', path: ['a']),
        StandardIssue(message: 'second'),
      ];
      final error = StandardSchemaError(issues);

      expect(error, isA<Exception>());
      expect(error.issues, issues);
      expect(error.message, 'first');
      expect(error.toString(), 'StandardSchemaError: first');
    });

    test('stores issues as an unmodifiable snapshot', () {
      final issues = [StandardIssue(message: 'first')];
      final error = StandardSchemaError(issues);

      issues.add(StandardIssue(message: 'second'));

      expect(error.issues, hasLength(1));
      expect(error.issues.single.message, 'first');
      expect(
        () => error.issues.add(StandardIssue(message: 'third')),
        throwsUnsupportedError,
      );
    });

    test('accepts iterable issues', () {
      Iterable<StandardIssue> issues() sync* {
        yield StandardIssue(message: 'first');
      }

      final error = StandardSchemaError(issues());

      expect(error.issues.single.message, 'first');
      expect(
        () => error.issues.add(StandardIssue(message: 'second')),
        throwsUnsupportedError,
      );
    });

    test('throws when constructed with no issues', () {
      expect(() => StandardSchemaError(const []), throwsArgumentError);
    });
  });
}
