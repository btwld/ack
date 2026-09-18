import 'package:ack/ack.dart';

void main() {
  // Source documents are decoded maps or booleans, not JSON strings.
  final AckSchema<Object, Object> validator = Ack.fromJsonSchema(
    {r'$ref': 'types.json'},
    baseUri: Uri.parse('https://example.test/root.json'),
    documents: {
      Uri.parse('types.json'): {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
        },
        'required': ['name'],
      },
    },
  );
  print(validator.parse({'name': 'Ada'}));
  print(validator.toJsonSchema());
}
