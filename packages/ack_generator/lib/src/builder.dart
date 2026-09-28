import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'generator.dart';
import 'json/ack_json_generator.dart';
import 'model_generator.dart';

/// Header for the modern parts.
///
/// Generated code keeps consumer lint rules and coverage reports focused on
/// hand-written source, matching other Dart model generators.
const _modernPartHeader =
    '$defaultFileHeader\n'
    '// ignore_for_file: type=lint\n'
    '// coverage:ignore-file';

/// Creates the frozen legacy `.g.dart` builder for `@AckType`.
Builder ackGenerator(BuilderOptions options) {
  return LibraryBuilder(AckSchemaGenerator(), generatedExtension: '.g.dart');
}

/// Creates the dedicated modern model part.
///
/// Keeping modern output separate prevents changes to the legacy `.g.dart`
/// contract.
Builder ackModelBuilder(BuilderOptions options) {
  return PartBuilder(
    [AckModelGenerator()],
    '.ack.dart',
    header: _modernPartHeader,
    options: options,
  );
}

/// Creates the dedicated modern JSON part after `.ack.dart` exists.
Builder ackModelJsonBuilder(BuilderOptions options) {
  return PartBuilder(
    [AckJsonSerializableGenerator()],
    '.ack.g.dart',
    header: _modernPartHeader,
    options: options,
  );
}
