import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

Future<void> _build(
  String source, {
  Map<String, Object>? outputs,
  void Function(LogRecord log)? onLog,
}) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {'test_pkg|lib/schema.dart': source},
    generateFor: const {'test_pkg|lib/schema.dart'},
    readerWriter: readerWriter,
    outputs: outputs,
    onLog: onLog,
  );
}

void main() {
  test(
    'builder writes a dedicated source part from workspace packages',
    () async {
      await _build(
        '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part 'schema.g.dart';

@Schemable()
final userSchema = Ack.object({'name': Ack.string()});
''',
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('// GENERATED CODE - DO NOT MODIFY BY HAND'),
              contains("part of 'schema.dart';"),
              contains('final class User'),
            ]),
          ),
        },
      );
    },
  );

  test('does not emit output without Schemable declarations', () async {
    await _build('final value = 1;', outputs: const {});
  });

  test('reports the exact required part directive', () async {
    var sawError = false;
    await _build(
      '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

@Schemable()
final userSchema = Ack.string();
''',
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE' &&
            log.message.contains("part 'schema.g.dart';")) {
          sawError = true;
        }
      },
    );
    expect(sawError, isTrue);
  });

  test('reports the required part directive for Schemable classes', () async {
    var sawError = false;
    await _build(
      '''
import 'package:ack/annotations.dart';

@Schemable()
final class User with _\$UserAck {
  const User({required this.name});

  final String name;
}
''',
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE' &&
            log.message.contains("part 'schema.g.dart';")) {
          sawError = true;
        }
      },
    );
    expect(sawError, isTrue);
  });

  test('rejects legacy .ack.dart part directive without .g.dart', () async {
    var sawError = false;
    await _build(
      '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part 'schema.ack.dart';

@Schemable()
final userSchema = Ack.string();
''',
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE' &&
            log.message.contains("part 'schema.g.dart';")) {
          sawError = true;
        }
      },
    );
    expect(sawError, isTrue);
  });

  test('does not reject part directives with a leading ./', () async {
    var sawOurPartError = false;
    await _build(
      '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part './schema.g.dart';

@Schemable()
final userSchema = Ack.object({'name': Ack.string()});
''',
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE' &&
            log.message.contains('Ack model generation requires')) {
          sawOurPartError = true;
        }
      },
    );
    expect(sawOurPartError, isFalse);
  });

  test(
    'rejects a part directive that points at a nested relative path',
    () async {
      var sawError = false;
      await _build(
        '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part 'sub/schema.g.dart';

@Schemable()
final userSchema = Ack.string();
''',
        outputs: const {},
        onLog: (log) {
          if (log.level.name == 'SEVERE' &&
              log.message.contains("part 'schema.g.dart';")) {
            sawError = true;
          }
        },
      );
      expect(sawError, isTrue);
    },
  );

  test('rejects a part that does not match the basename', () async {
    var sawError = false;
    await _build(
      '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part 'other.g.dart';

@Schemable()
final userSchema = Ack.string();
''',
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE' &&
            log.message.contains("part 'schema.g.dart';")) {
          sawError = true;
        }
      },
    );
    expect(sawError, isTrue);
  });

  test('rejects Schemable on enums', () async {
    var sawError = false;
    await _build(
      '''
import 'package:ack/annotations.dart';

@Schemable()
enum InvalidTarget { a, b }
''',
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE' &&
            log.message.contains(
              '@Schemable can only be applied to classes or top-level schema',
            )) {
          sawError = true;
        }
      },
    );
    expect(sawError, isTrue);
  });
}
