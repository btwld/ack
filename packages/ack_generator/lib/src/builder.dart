import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'generator.dart';

/// Creates the builder for ack_generator
Builder ackGenerator(BuilderOptions options) {
  return SharedPartBuilder(
    [AckSchemaGenerator()],
    'ack',
    formatOutput: (generated, version) => generated.replaceAll(RegExp(r'//.*\n'), ''),
  );
}
