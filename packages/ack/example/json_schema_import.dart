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

  // Partial conversion requires an explicit opt-in and a diagnostic report.
  final JsonSchemaImportResult report = importJsonSchema({
    'type': 'string',
    'format': 'email',
  }, allowUnsupported: true);
  print(report.diagnostics);
  final AckSchema<Object, Object> partial = report.schema;
  print(partial.parse('A string, not necessarily an email'));
}
