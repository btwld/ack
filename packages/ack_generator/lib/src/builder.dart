import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:source_gen/source_gen.dart';

import 'json_schema/json_schema_builder.dart';
import 'json_schema/json_schema_library.dart';
import 'model_generator.dart';

/// Creates the shared `.g.dart` part builder for `@Schemable` models.
Builder ackGenerator(BuilderOptions options) {
  return SharedPartBuilder(
    [AckModelGenerator()],
    'ack',
    formatOutput: _formatOutput,
  );
}

/// Creates a direct `.g.dart` part builder for single-step unit tests.
Builder ackModelBuilder(BuilderOptions options) {
  return PartBuilder(
    [AckModelGenerator()],
    '.g.dart',
    options: options,
    formatOutput: _formatOutput,
  );
}

// dart_style 3.1.14 parses augmentations but its class visitor drops `augment`.
// Temporarily remove only AST-identified declaration tokens, then restore them
// at the formatted declaration offsets. String literals and comments are never
// interpreted as declarations or changed by this workaround.
String _formatOutput(String code, Version languageVersion) {
  final features = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: languageVersion,
    flags: const ['augmentations'],
  );
  List<ClassDeclaration> classes(String source) => parseString(
    content: source,
    featureSet: features,
  ).unit.declarations.whereType<ClassDeclaration>().toList();
  final declarations = classes(code);
  final names = <String>{};
  var plainCode = code;
  for (final declaration in declarations.reversed) {
    final token = declaration.augmentKeyword;
    if (token == null) continue;
    names.add(declaration.namePart.typeName.lexeme);
    plainCode = plainCode.replaceRange(token.offset, token.end, '');
  }
  var formatted = DartFormatter(
    languageVersion: languageVersion,
    experimentFlags: const ['augmentations'],
  ).format(plainCode);
  for (final declaration in classes(formatted).reversed) {
    if (!names.contains(declaration.namePart.typeName.lexeme)) continue;
    final token = declaration.finalKeyword ?? declaration.sealedKeyword!;
    formatted = formatted.replaceRange(token.offset, token.offset, 'augment ');
  }
  return formatted;
}

/// Creates the opt-in builder that generates `@Schemable` schema declarations
/// from `*.schema.json` JSON Schema bundles.
///
/// Enable it in a consumer's `build.yaml` as `ack_generator:ack_json_schema`.
Builder ackJsonSchemaBuilder(BuilderOptions options) => AckJsonSchemaBuilder(
  AckJsonSchemaLibraryOptions.fromConfig(options.config),
);
