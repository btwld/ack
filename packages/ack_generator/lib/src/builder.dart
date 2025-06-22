import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'file_generator.dart';

/// Creates the builder for ack_generator
Builder ackGenerator(BuilderOptions options) {
  return LibraryBuilder(
    AckFileGenerator(),
    generatedExtension: '.g.dart',
  );
}
