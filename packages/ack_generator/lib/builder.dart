import 'package:build/build.dart';

import 'src/schema_model_builder.dart';

/// Builds SchemaModel-based schema classes for model classes
Builder schemaModelBuilder(BuilderOptions options) =>
    SchemaModelBuilder(options);

/// Factory function for use with build_runner as configured in pubspec.yaml
Builder ackSchemaBuilder(BuilderOptions options) => SchemaModelBuilder(options);
