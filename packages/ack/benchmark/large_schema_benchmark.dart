/// Large schemas and values: `Ack.fromJsonSchema` compilation, `toJsonSchema`
/// export, and parsing with native and imported schemas. See `harness.dart`
/// for how to run.
library;

import 'dart:convert';

import 'package:ack/ack.dart';

import 'harness.dart';

const _fields = 20;

void main() {
  for (final types in [10, 100, 1000]) {
    final document = _document(types);
    final native = _native(types);
    final imported = Ack.fromJsonSchema(document);
    final value = _rootValue(types);
    check('imported root', imported.safeParse(value).isOk);
    check('native root', native.safeParse(value).isOk);
    final docKb = jsonEncode(document).length / 1024;
    final valueKb = jsonEncode(value).length / 1024;
    print(
      '\n$types types x $_fields fields '
      '(schema ${docKb.toStringAsFixed(0)} KB, '
      'value ${valueKb.toStringAsFixed(0)} KB)',
    );
    report('fromJsonSchema compile', () => Ack.fromJsonSchema(document));
    report('imported toJsonSchema', imported.toJsonSchema);
    report('native toJsonSchema', native.toJsonSchema);
    report('imported safeParse root', () => imported.safeParse(value));
    report('native safeParse root', () => native.safeParse(value));
  }

  for (final count in [1000, 10000]) {
    final document = {
      r'$schema': draft,
      'type': 'array',
      'items': _recordDocument(),
    };
    final imported = Ack.fromJsonSchema(document);
    final native = Ack.list(_nativeRecord());
    final value = [for (var i = 0; i < count; i++) _recordValue(i)];
    check('imported list', imported.safeParse(value).isOk);
    check('native list', native.safeParse(value).isOk);
    check('imported list encode', imported.safeEncode(value).isOk);
    final text = jsonEncode(value);
    print('\n$count records (${(text.length / 1024).toStringAsFixed(0)} KB)');
    report('imported safeParse', () => imported.safeParse(value));
    report('imported safeEncode', () => imported.safeEncode(value));
    report('native safeParse', () => native.safeParse(value));
    report('jsonDecode (reference)', () => jsonDecode(text));
  }
}

/// A root object with one property per type. Type `i` has [_fields] fields
/// and, for `i > 0`, an optional `parent` that refers to type `i ~/ 2`.
Map<String, Object?> _document(int types) => {
  r'$schema': draft,
  'type': 'object',
  'additionalProperties': false,
  'required': [for (var i = 0; i < types; i++) 't$i'],
  'properties': {
    for (var i = 0; i < types; i++) 't$i': {r'$ref': '#/\$defs/T$i'},
  },
  r'$defs': {
    for (var i = 0; i < types; i++)
      'T$i': _recordDocument(parent: i == 0 ? null : '#/\$defs/T${i ~/ 2}'),
  },
};

Map<String, Object?> _recordDocument({String? parent}) => {
  'type': 'object',
  'additionalProperties': false,
  'required': [for (var f = 0; f < _fields; f++) 'f$f'],
  'properties': {
    for (var f = 0; f < _fields; f++) 'f$f': _fieldDocument(f),
    if (parent != null) 'parent': {r'$ref': parent},
  },
};

Map<String, Object?> _fieldDocument(int f) => switch (f % 5) {
  0 => {'type': 'string', 'minLength': 1, 'pattern': r'^[a-z0-9]+$'},
  1 => {'type': 'integer', 'minimum': 0, 'maximum': 1000000},
  2 => {
    'type': 'string',
    'enum': ['a', 'b', 'c'],
  },
  3 => {'type': 'boolean'},
  _ => {
    'type': 'array',
    'maxItems': 10,
    'items': {'type': 'string'},
  },
};

AckSchema<Object, Object> _native(int types) {
  final records = <ObjectSchema>[];
  for (var i = 0; i < types; i++) {
    records.add(_nativeRecord(parent: i == 0 ? null : records[i ~/ 2]));
  }
  return Ack.object({for (var i = 0; i < types; i++) 't$i': records[i]});
}

ObjectSchema _nativeRecord({ObjectSchema? parent}) => Ack.object({
  for (var f = 0; f < _fields; f++) 'f$f': _nativeField(f),
  'parent': ?parent?.optional(),
});

AckSchema<Object, Object> _nativeField(int f) => switch (f % 5) {
  0 => Ack.string().minLength(1).matches(r'^[a-z0-9]+$'),
  1 => Ack.integer().min(0).max(1000000),
  2 => Ack.enumString(['a', 'b', 'c']),
  3 => Ack.boolean(),
  _ => Ack.list(Ack.string()).maxItems(10),
};

/// Fills every type, including its full `parent` chain.
Map<String, Object?> _rootValue(int types) {
  Map<String, Object?> record(int i) => {
    ..._recordValue(i),
    if (i > 0) 'parent': record(i ~/ 2),
  };
  return {for (var i = 0; i < types; i++) 't$i': record(i)};
}

Map<String, Object?> _recordValue(int i) => {
  for (var f = 0; f < _fields; f++)
    'f$f': switch (f % 5) {
      0 => 'v$i',
      1 => i,
      2 => 'b',
      3 => i.isEven,
      _ => ['x', 'y', 'z'],
    },
};
