import 'dart:convert';
import 'dart:io';

import 'package:ack/ack.dart';
import 'package:ack_generator/ack_generator.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

enum _MapKind { string, dynamicKeys, objectKeys }

Object? _represent(Object? value, _MapKind kind) => switch (value) {
  final Map<String, Object?> map => switch (kind) {
    _MapKind.string => <String, Object?>{
      for (final entry in map.entries) entry.key: _represent(entry.value, kind),
    },
    _MapKind.dynamicKeys => <dynamic, dynamic>{
      for (final entry in map.entries) entry.key: _represent(entry.value, kind),
    },
    _MapKind.objectKeys => <Object?, Object?>{
      for (final entry in map.entries) entry.key: _represent(entry.value, kind),
    },
  },
  final List<Object?> list => [for (final item in list) _represent(item, kind)],
  _ => value,
};

Map<String, Object?> _object(String keyword, {bool preserve = false}) => {
  'type': 'object',
  'properties': <String, Object?>{
    'name': {'type': 'string'},
  },
  'required': ['name'],
  keyword: preserve,
};

void main() {
  test('preserve mode copies and widens every supported resource map', () async {
    final temporary = await Directory.systemTemp.createTemp('ack_preserve_');
    addTearDown(() => temporary.delete(recursive: true));
    final externalUri = Uri.parse('https://example.test/external.json');
    final bundleUri = Uri.parse('https://example.test/bundle.json');
    final documentUri = Uri.parse('https://example.test/model.schema.json');
    final values = <Object?>[
      {'name': 'ok', 'extra': 42},
      {
        'name': 'ok',
        'profile': {'name': 'nested', 'extra': 42},
        'extra': 42,
      },
      {'name': 42, 'extra': 42},
      <String, Object?>{},
      {'name': 'ok'},
    ];
    final imports = <String>[];
    final probes = <String>[];
    final expected = <String, Object?>{};
    final widenings = <String, List<String>>{};
    final expectedWidenings = <String, List<String>>{};

    for (final kind in _MapKind.values) {
      for (final keyword in ['additionalProperties', 'unevaluatedProperties']) {
        for (final bundled in [false, true]) {
          for (final mode in AckUnknownPropertiesMode.values) {
            final preserve = mode == AckUnknownPropertiesMode.preserve;
            final label = '${kind.name}/$keyword/bundle=$bundled/${mode.name}';
            final schema = _object(keyword);
            (schema['properties']! as Map<String, Object?>)['profile'] =
                _object(keyword);
            final resource = _represent(
              bundled
                  ? {
                      r'$defs': {
                        'Inner': {r'$id': externalUri.toString(), ...schema},
                      },
                    }
                  : schema,
              kind,
            )!;
            final before = jsonEncode(resource);
            final retrievalUri = bundled ? bundleUri : externalUri;
            final document = <String, Object?>{
              r'$defs': {
                'Model': {r'$ref': externalUri.toString()},
              },
            };
            final library = generateAckSchemaLibrary(
              document: document,
              documentUri: documentUri,
              partStem: 'model.schema',
              documents: {retrievalUri: resource},
              includeParts: false,
              options: AckJsonSchemaLibraryOptions(unknownProperties: mode),
            );
            expect(
              jsonEncode(resource),
              before,
              reason: '$label mutated input',
            );
            final pointer = bundled
                ? '$bundleUri#/\$defs/Inner'
                : '$externalUri#';
            widenings[label] = library.widenedPointers;
            expectedWidenings[label] = [
              if (preserve) ...[pointer, '$pointer/properties/profile'],
            ];

            final widened = _object(keyword, preserve: preserve);
            (widened['properties']! as Map<String, Object?>)['profile'] =
                _object(keyword, preserve: preserve);
            final oracle = Ack.fromJsonSchema(widened);
            expected[label] = [
              for (final value in values)
                {
                  'parse': oracle.safeParse(value).isOk,
                  'encode': oracle.safeEncode(value).isOk,
                  'parsed': oracle.safeParse(value).getOrNull(),
                  'encoded': oracle.safeEncode(value).getOrNull(),
                },
            ];
            final prefix = 'variant${imports.length}';
            await File(
              p.join(temporary.path, '$prefix.dart'),
            ).writeAsString(library.source);
            imports.add("import '$prefix.dart' as $prefix;");
            probes.add(
              '${jsonEncode(label)}: [for (final value in values) '
              'inspect($prefix.modelSchema, value)],',
            );
          }
        }
      }
    }

    final probe = File(p.join(temporary.path, 'probe.dart'));
    await probe.writeAsString('''
import 'dart:convert';
import 'package:ack/ack.dart' as ack;
${imports.join('\n')}

Object inspect(ack.AckSchema<Object, Object> schema, Object? value) {
  final parsed = schema.safeParse(value);
  final encoded = schema.safeEncode(value);
  return {
    'parse': parsed.isOk,
    'encode': encoded.isOk,
    'parsed': parsed.getOrNull(),
    'encoded': encoded.getOrNull(),
  };
}

void main() {
  final values = jsonDecode(${jsonEncode(jsonEncode(values))}) as List;
  print(jsonEncode({${probes.join('\n')}}));
}
''');
    var repository = Directory.current;
    while (!File(
      p.join(repository.path, '.dart_tool', 'package_config.json'),
    ).existsSync()) {
      repository = repository.parent;
    }
    final result = await Process.run(Platform.resolvedExecutable, [
      '--packages=${p.join(repository.path, '.dart_tool', 'package_config.json')}',
      probe.path,
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(jsonDecode(result.stdout as String), expected);
    expect(widenings, expectedWidenings);
  });

  test('preserve mode still diagnoses non-string resource keys', () {
    final externalUri = Uri.parse('https://example.test/external.json');
    expect(
      () => generateAckSchemaLibrary(
        document: {r'$ref': externalUri.toString()},
        documentUri: Uri.parse('https://example.test/model.schema.json'),
        partStem: 'model.schema',
        documents: {
          externalUri: <Object?, Object?>{42: 'invalid JSON key'},
        },
        options: const AckJsonSchemaLibraryOptions(
          unknownProperties: AckUnknownPropertiesMode.preserve,
        ),
      ),
      throwsA(isA<AckJsonSchemaGenerationException>()),
    );
  });
}
