/// Small schemas and values. See `harness.dart` for how to run.
library;

import 'package:ack/ack.dart';

import 'harness.dart';

void main() {
  final string = Ack.string();
  final object = Ack.object({
    'a': Ack.string(),
    'b': Ack.string(),
    'c': Ack.string(),
  });
  final anything = Ack.fromJsonSchema(true);
  final flat = Ack.fromJsonSchema({
    r'$schema': draft,
    'type': 'object',
    'properties': {
      for (var i = 0; i < 8; i++)
        'p$i': {'type': 'string', 'minLength': 1, 'pattern': r'^[a-z]+$'},
    },
  });
  final flatValue = {for (var i = 0; i < 8; i++) 'p$i': 'abc'};
  final nested = Ack.fromJsonSchema({
    r'$schema': draft,
    'type': 'object',
    'properties': {
      'items': {
        'type': 'array',
        'items': {
          'type': 'object',
          'required': ['id', 'tags'],
          'properties': {
            'id': {'type': 'string'},
            'tags': {
              'type': 'array',
              'items': {'type': 'string'},
            },
          },
        },
      },
    },
  });
  final nestedValue = {
    'items': [
      for (var i = 0; i < 50; i++)
        {
          'id': 'x$i',
          'tags': ['a', 'b', 'c'],
        },
    ],
  };
  const objectValue = {'a': 'x', 'b': 'y', 'c': 'z'};
  check('string', string.safeParse('x').isOk);
  check('object', object.safeParse(objectValue).isOk);
  check('anything', anything.safeParse('x').isOk);
  check('flat', flat.safeParse(flatValue).isOk);
  check('nested', nested.safeParse(nestedValue).isOk);

  report('Ack.string()', () => string.safeParse('x'));
  report('Ack.object, 3 string fields', () => object.safeParse(objectValue));
  report('fromJsonSchema(true)', () => anything.safeParse('x'));
  report('imported, 8 properties', () => flat.safeParse(flatValue));
  report('imported, 8 properties (encode)', () => flat.safeEncode(flatValue));
  report('imported, 50 nested items', () => nested.safeParse(nestedValue));
  report(
    'imported, 50 nested items (encode)',
    () => nested.safeEncode(nestedValue),
  );
}
