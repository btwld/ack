part of 'json_schema_library.dart';

String _emit(
  _Translator translator, {
  required Uri documentUri,
  required String partStem,
  required bool includeParts,
}) {
  final source = documentUri.pathSegments.isEmpty
      ? '$documentUri'
      : documentUri.pathSegments.last;
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('// dart format width=80')
    ..writeln('// ignore_for_file: type=lint')
    ..writeln('// coverage:ignore-file')
    ..writeln('//')
    ..writeln('// Generated from $source by ack_generator:ack_json_schema.');
  if (translator.widened.isNotEmpty) {
    buffer.writeln('// unknown_properties: preserve widened these objects:');
    for (final pointer in translator.widened) {
      buffer.writeln('// - ${_commentText(pointer)}');
    }
  }
  buffer
    ..writeln()
    ..writeln("import 'package:ack/ack.dart' as ack;")
    ..writeln();
  if (includeParts) {
    buffer
      ..writeln("part '$partStem.g.dart';")
      ..writeln();
  }
  for (final declaration in translator.declarations) {
    buffer
      ..writeln('@ack.Schemable(name: ${dartStringLiteral(declaration.name)})')
      ..writeln('final ${_variable(declaration.name)} = ${declaration.code};')
      ..writeln();
  }
  return buffer.toString();
}

String _emitFallback(
  Map<String, Object?> document, {
  required Uri documentUri,
  required Map<Uri, Object> documents,
  required bool assertFormats,
  required List<String> widened,
}) {
  final defs = document[r'$defs'] as Map<String, Object?>? ?? const {};
  const rootAnnotations = {
    r'$schema',
    r'$defs',
    r'$comment',
    'title',
    'description',
  };
  final hasRootModel =
      defs.isEmpty ||
      document.keys.any((key) => !rootAnnotations.contains(key));
  final names = <String>{};
  String uniqueName(String key) {
    final words = key
        .split(RegExp(r'[^A-Za-z0-9]+'))
        .where((word) => word.isNotEmpty)
        .toList();
    var base = words.isEmpty
        ? 'Definition'
        : words
              .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
              .join();
    if (RegExp(r'^[0-9]').hasMatch(base)) base = 'Definition$base';
    if (_reservedModelNames.contains(base)) base = '${base}Model';
    var name = base;
    var suffix = 2;
    while (!names.add(name)) {
      name = '$base${suffix++}';
    }
    return name;
  }

  final definitions = <(String, String)>[
    for (final key in defs.keys) (uniqueName(key), key),
  ];
  final rootName = hasRootModel
      ? uniqueName(names.contains('Root') ? 'DocumentRoot' : 'Root')
      : null;
  final models = <(String, String?)>[
    if (rootName != null) (rootName, null),
    ...definitions,
  ];
  final uri = dartStringLiteral(documentUri.toString());
  final lookupUri = dartStringLiteral(
    documentUri.resolve('__ack_json_schema_generated__.json').toString(),
  );
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('// dart format width=80')
    ..writeln('// ignore_for_file: type=lint')
    ..writeln('// coverage:ignore-file')
    ..writeln('//')
    ..writeln('// Draft 2020-12 value models retain source-schema validation.')
    ..writeln(
      '// Complex shapes use Object? values, not inferred typed fields.',
    );
  if (widened.isNotEmpty) {
    buffer.writeln('// unknown_properties: preserve widened these objects:');
    for (final pointer in widened) {
      buffer.writeln('// - ${_commentText(pointer)}');
    }
  }
  buffer
    ..writeln()
    ..writeln("import 'dart:convert';")
    ..writeln("import 'package:ack/ack.dart' as ack;")
    ..writeln()
    ..writeln('// dart format off')
    ..writeln('final Object _jsonSchemaDocument =')
    ..writeln(
      '    jsonDecode(${dartStringLiteral(jsonEncode(document))}) as Object;',
    )
    ..writeln('final Map<Uri, Object> _jsonSchemaDocuments = {')
    ..writeln('  Uri.parse($uri): _jsonSchemaDocument,');
  for (final entry in documents.entries) {
    buffer.writeln(
      '  Uri.parse(${dartStringLiteral(entry.key.toString())}): '
      'jsonDecode(${dartStringLiteral(jsonEncode(entry.value))}) as Object,',
    );
  }
  buffer
    ..writeln('};')
    ..writeln('// dart format on')
    ..writeln();
  for (final (name, definition) in models) {
    final variable = _variable(name);
    final formatOption = assertFormats ? ', assertFormats: true' : '';
    final schemaExpression = definition == null
        ? 'ack.Ack.fromJsonSchema(_jsonSchemaDocument, '
              'baseUri: Uri.parse($uri), documents: {'
              'for (final entry in _jsonSchemaDocuments.entries) '
              'if (entry.key != Uri.parse($uri)) entry.key: entry.value}'
              '$formatOption)'
        : 'ack.Ack.fromJsonSchema('
              "{r'\$ref': ${dartStringLiteral(documentUri.replace(fragment: '/\$defs/${_token(definition)}').toString())}}, "
              'baseUri: Uri.parse($lookupUri), '
              'documents: _jsonSchemaDocuments$formatOption)';
    buffer
      ..writeln('final $variable = $schemaExpression;')
      ..writeln()
      ..writeln('/// A validated Draft 2020-12 value model.')
      ..writeln('final class $name {')
      ..writeln('  const $name._(this.value);')
      ..writeln()
      ..writeln('  /// The parsed, immutable JSON value.')
      ..writeln('  final Object? value;')
      ..writeln()
      ..writeln('  /// The exact source-schema validator for this model.')
      ..writeln(
        '  static ack.AckSchema<Object, Object> get schema => $variable;',
      )
      ..writeln()
      ..writeln('  static $name parse(Object? value) =>')
      ..writeln('      safeParse(value).getOrThrow()!;')
      ..writeln()
      ..writeln('  static ack.SchemaResult<$name> safeParse(Object? value) =>')
      ..writeln(
        '      schema.safeParse(value).map((parsed) => $name._(parsed));',
      )
      ..writeln()
      ..writeln('  static Object? encode($name model) =>')
      ..writeln('      safeEncode(model).getOrThrow();')
      ..writeln()
      ..writeln('  static ack.SchemaResult<Object> safeEncode($name model) =>')
      ..writeln('      schema.safeEncode(model.value);')
      ..writeln()
      ..writeln('  Object? toJson() => encode(this);')
      ..writeln()
      ..writeln('  static Map<String, Object?> toJsonSchema() =>')
      ..writeln('      schema.toJsonSchema();')
      ..writeln('}')
      ..writeln();
  }
  return buffer.toString();
}

String _variable(String modelName) =>
    '${modelName[0].toLowerCase()}${modelName.substring(1)}Schema';

String _commentText(String value) => value
    .replaceAll('\\', r'\\')
    .replaceAll('\r', r'\r')
    .replaceAll('\n', r'\n')
    .replaceAll('\t', r'\t')
    .replaceAll('\u2028', r'\u2028')
    .replaceAll('\u2029', r'\u2029');
