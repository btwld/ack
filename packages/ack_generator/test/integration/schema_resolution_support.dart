import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

const _head = '''
import 'package:ack/ack.dart';
import 'types.dart';

part 'model.g.dart';
''';

const _types = r'''
import 'package:ack/ack.dart';

final class Slot {
  const Slot(this.id);
  final String id;

  static final schema = Ack.string().codec<Slot>(
    decode: Slot.new,
    encode: (slot) => slot.id,
  );
}

final class Token {
  const Token(this.value);
  final String value;

  static AckSchema<String, Token> get schema => Ack.string().codec<Token>(
    decode: Token.new,
    encode: (token) => token.value,
  );
}

extension type const WidgetId(String value) implements Object {
  static final schema = Ack.string().codec<WidgetId>(
    decode: WidgetId.new,
    encode: (id) => id.value,
  );
}

enum CompletionAction { complete, skip }

final class Invoke<A extends Object> {
  const Invoke(this.action);
  final A action;

  static AckSchema<String, Invoke<A>> schema<A extends Object>(
    List<A> actions,
  ) => throw UnimplementedError();
}

final class Trigger<A> {
  const Trigger(this.name);
  final String name;

  static AckSchema<String, Trigger<A>> schema<A>() =>
      Ack.string().codec<Trigger<A>>(
        decode: Trigger<A>.new,
        encode: (trigger) => trigger.name,
      );
}

final class Box<A extends Object> {
  const Box(this.value);
  final A value;

  static AckSchema<Object, Box<A>> schema<A extends Object>(
    AckSchema<Object, A> value,
  ) => value.codec<Box<A>>(decode: Box<A>.new, encode: (box) => box.value);
}

final class Pair<A extends Object, B extends Object> {
  const Pair(this.first, this.second);
  final A first;
  final B second;

  static AckSchema<Object, Pair<A, B>> schema<A extends Object, B extends Object>(
    AckSchema<Object, A> first,
  ) => throw UnimplementedError();
}

final class Command<A extends Object> {
  const Command(this.name);
  final String name;

  static AckSchema<String, Command<A>> schema<A extends Object>() =>
      Ack.string().codec<Command<A>>(
        decode: Command<A>.new,
        encode: (command) => command.name,
      );
}
''';

/// Compares generated code without formatter whitespace or trailing commas.
Matcher containsCode(String code) => predicate<String>(
  (output) => _compact(output).contains(_compact(code)),
  'contains code `$code`',
);

String _compact(String code) =>
    code.replaceAll(RegExp(r'\s+'), '').replaceAll(',)', ')');

Future<void> expectOutput(
  String body,
  Matcher matcher, {
  String head = _head,
  String types = _types,
}) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {
      'test_pkg|lib/model.dart': '$head\n$body',
      'test_pkg|lib/types.dart': types,
    },
    generateFor: const {'test_pkg|lib/model.dart'},
    readerWriter: readerWriter,
    outputs: {'test_pkg|lib/model.g.dart': decodedMatches(matcher)},
  );
}

Future<List<String>> generationErrors(
  String body, {
  String head = _head,
  String types = _types,
}) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  final errors = <String>[];
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {
      'test_pkg|lib/model.dart': '$head\n$body',
      'test_pkg|lib/types.dart': types,
    },
    generateFor: const {'test_pkg|lib/model.dart'},
    readerWriter: readerWriter,
    outputs: const {},
    onLog: (LogRecord log) {
      if (log.level == Level.SEVERE) errors.add(log.message);
    },
  );
  return errors;
}
