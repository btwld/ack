import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:ack_generator/src/json_schema/json_schema_library.dart';
import 'package:test/test.dart';

import 'fixture_library.dart';
import 'fixtures/mapping.schema.dart' as schema_mode;
import 'fixtures/mapping_preserve.schema.dart' as preserve_mode;
import 'instance_corpus.dart';

/// Checks acceptance criterion 1: over a generated instance corpus, each
/// generated schema accepts exactly what `Ack.fromJsonSchema` accepts for the
/// effective document.
void main() {
  final cases = {
    AckUnknownPropertiesMode.schema: {
      'Listing': schema_mode.listingSchema,
      'Photo': schema_mode.photoSchema,
    },
    AckUnknownPropertiesMode.preserve: {
      'Listing': preserve_mode.listingSchema,
      'Photo': preserve_mode.photoSchema,
    },
  };

  for (final MapEntry(key: mode, value: generated) in cases.entries) {
    group('unknown_properties: ${mode.name}', () {
      final effective = generateFixture(
        'mapping',
        unknownProperties: mode,
      ).effectiveDocument;
      final corpus = InstanceCorpus(effective);
      final uri = fixtureUri('mapping');

      for (final MapEntry(key: name, value: schema) in generated.entries) {
        test('$name agrees with Ack.fromJsonSchema', () {
          final oracle = Ack.fromJsonSchema(
            {r'$ref': '$uri#/\$defs/$name'},
            baseUri: uri.resolve('__oracle__.json'),
            documents: {uri: effective},
          );
          final instances = corpus.instancesFor(name);
          final mismatches = [
            for (final instance in instances)
              if (oracle.safeParse(instance).isOk !=
                  schema.safeParse(instance).isOk)
                'importer ${oracle.safeParse(instance).isOk ? 'accepts' : 'rejects'}, '
                    'generated ${schema.safeParse(instance).isOk ? 'accepts' : 'rejects'}: '
                    '${jsonEncode(instance)}',
          ];
          final properties =
              ((effective[r'$defs']! as Map)[name]! as Map)['properties']!
                  as Map;
          final accepted = instances.where((i) => oracle.safeParse(i).isOk);
          // A broken corpus would pass trivially; require real coverage of
          // both outcomes and at least ten probes per declared property.
          expect(
            instances.length,
            greaterThanOrEqualTo(10 * properties.length),
          );
          expect(accepted, isNotEmpty);
          expect(accepted.length, lessThan(instances.length));
          expect(mismatches, isEmpty);
          printOnFailure(
            '$name: ${instances.length} instances, ${accepted.length} valid',
          );
        });
      }
    });
  }
}
