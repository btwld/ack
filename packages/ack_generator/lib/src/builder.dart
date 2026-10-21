import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'json_schema/json_schema_builder.dart';
import 'json_schema/json_schema_library.dart';
import 'model_generator.dart';

/// Creates the shared `.g.dart` part builder for `@Schemable` models.
Builder ackGenerator(BuilderOptions options) {
  return SharedPartBuilder([AckModelGenerator()], 'ack');
}

/// Creates a direct `.g.dart` part builder for single-step unit tests.
Builder ackModelBuilder(BuilderOptions options) {
  return PartBuilder([AckModelGenerator()], '.g.dart', options: options);
}

/// Creates the opt-in builder that generates `@Schemable` schema declarations
/// from `*.schema.json` JSON Schema bundles.
///
/// Enable it in a consumer's `build.yaml` as `ack_generator:ack_json_schema`.
Builder ackJsonSchemaBuilder(BuilderOptions options) => AckJsonSchemaBuilder(
  AckJsonSchemaLibraryOptions.fromConfig(options.config),
);
