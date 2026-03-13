import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('@Schemable cross-file type resolution', () {
    test('resolves nested schemable types imported with a prefix', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/remote_models.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable()
class Address {
  final String city;

  const Address({required this.city});
}
''',
          'test_pkg|lib/shipment.dart': '''
import 'package:ack_annotations/ack_annotations.dart';
import 'remote_models.dart' as remote;

@Schemable()
class Shipment {
  final remote.Address destination;

  const Shipment({required this.destination});
}
''',
        },
        outputs: {
          'test_pkg|lib/remote_models.g.dart': decodedMatches(
            contains('final addressSchema = Ack.object('),
          ),
          'test_pkg|lib/shipment.g.dart': decodedMatches(
            allOf([
              contains('final shipmentSchema = Ack.object('),
              contains("'destination': remote.addressSchema"),
            ]),
          ),
        },
      );
    });

    test(
      'keeps prefixed nested types distinct from same-named local schemables',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/remote_models.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable()
class Address {
  final String city;

  const Address({required this.city});
}
''',
            'test_pkg|lib/shipment.dart': '''
import 'package:ack_annotations/ack_annotations.dart';
import 'remote_models.dart' as remote;

@Schemable(schemaName: 'LocalAddressSchema')
class Address {
  final String street;

  const Address({required this.street});
}

@Schemable()
class Shipment {
  final Address origin;
  final remote.Address destination;

  const Shipment({
    required this.origin,
    required this.destination,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/remote_models.g.dart': decodedMatches(
              contains('final addressSchema = Ack.object('),
            ),
            'test_pkg|lib/shipment.g.dart': decodedMatches(
              allOf([
                contains('final localAddressSchema = Ack.object('),
                contains("'origin': localAddressSchema"),
                contains("'destination': remote.addressSchema"),
              ]),
            ),
          },
        );
      },
    );
  });
}
