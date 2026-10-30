import 'package:ack/ack.dart';
import 'package:ack_generator/ack_generator.dart';
import 'package:test/test.dart';

void main() {
  final standard = Uri.parse('https://json-schema.org/draft/2020-12/schema');
  final draft7 = Uri.parse('http://json-schema.org/draft-07/schema');
  final alias = Uri.parse('https://example.test/meta.json');
  Map<String, Object?> meta(Uri id) => {
    r'$id': id.toString(),
    r'$schema': standard.toString(),
    r'$vocabulary': {'https://json-schema.org/draft/2020-12/vocab/core': true},
  };

  for (final (name, dialect, retrievalUri, resource, declared) in [
    ('standard retrieval URI', standard, standard, meta(standard), true),
    ('implicit standard dialect', standard, standard, meta(standard), false),
    ('Draft-7 resource ID', draft7, alias, meta(draft7), true),
    (
      'bundled standard resource',
      standard,
      alias,
      {
        r'$defs': {'Meta': meta(standard)},
      },
      true,
    ),
    (
      'relative standard resource ID',
      standard,
      Uri.parse('https://json-schema.org/draft/2020-12/bundle'),
      {
        r'$defs': {
          'Meta': {...meta(standard), r'$id': 'schema'},
        },
      },
      true,
    ),
  ]) {
    test('supplied vocabularies override $name', () {
      final documentUri = Uri.parse('https://example.test/model.schema.json');
      final document = <String, Object?>{
        if (declared) r'$schema': dialect.toString(),
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
      final documents = <Uri, Object>{retrievalUri: resource};
      final oracle = Ack.fromJsonSchema(
        {r'$ref': documentUri.replace(fragment: r'/$defs/Model').toString()},
        documents: {...documents, documentUri: document},
      );
      for (final value in [
        42,
        null,
        {'name': 42},
      ]) {
        expect(oracle.safeParse(value).isOk, isTrue);
      }
      final library = generateAckSchemaLibrary(
        document: document,
        documentUri: documentUri,
        partStem: 'model.schema',
        documents: documents,
        includeParts: false,
      );
      expect(library.source, contains('Ack.fromJsonSchema'));
      expect(library.source, contains('final class Model'));
    });
  }

  test('unrelated custom vocabularies retain standard typed models', () {
    final document = <String, Object?>{
      r'$schema': standard.toString(),
      r'$defs': {
        'Model': {'type': 'string'},
      },
    };
    final library = generateAckSchemaLibrary(
      document: document,
      documentUri: Uri.parse('https://example.test/model.schema.json'),
      partStem: 'model.schema',
      documents: {alias: meta(alias)},
      includeParts: false,
    );
    expect(library.source, contains('Ack.string()'));
    expect(library.source, isNot(contains('Ack.fromJsonSchema')));
  });
}
