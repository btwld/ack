import 'package:ack/ack.dart';
import 'package:ack_generator/ack_generator.dart';
import 'package:test/test.dart';

void main() {
  for (final vocabularies in [
    <String>[],
    ['validation'],
    ['applicator'],
  ]) {
    test('custom dialect preserves vocabularies $vocabularies', () {
      final dialectUri = Uri.parse('https://example.test/meta/custom');
      final documentUri = Uri.parse('https://example.test/model.schema.json');
      final documents = <Uri, Object>{
        dialectUri: {
          r'$id': dialectUri.toString(),
          r'$schema': 'https://json-schema.org/draft/2020-12/schema',
          r'$vocabulary': {
            'https://json-schema.org/draft/2020-12/vocab/core': true,
            for (final vocabulary in vocabularies)
              'https://json-schema.org/draft/2020-12/vocab/$vocabulary': true,
          },
        },
      };
      final document = <String, Object?>{
        r'$schema': dialectUri.toString(),
        r'$defs': {
          'Model': {
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
            },
            'required': ['name'],
          },
        },
      };
      final oracle = Ack.fromJsonSchema(
        {r'$ref': '$documentUri#/\$defs/Model'},
        documents: {...documents, documentUri: document},
      );
      expect(oracle.safeParse({'name': 42}).isOk, isTrue);
      expect(oracle.safeParse(null).isOk, !vocabularies.contains('validation'));

      final library = generateAckSchemaLibrary(
        document: document,
        documentUri: documentUri,
        partStem: 'model.schema',
        documents: documents,
        includeParts: false,
      );
      expect(library.effectiveDocument, document);
      expect(library.source, contains('Ack.fromJsonSchema'));
      expect(library.source, contains('final class Model'));
    });
  }
}
