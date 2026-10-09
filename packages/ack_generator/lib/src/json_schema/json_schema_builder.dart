import 'dart:convert';

import 'package:build/build.dart';
import 'package:pub_semver/pub_semver.dart';

import 'json_schema_library.dart';

/// Generates `<name>.schema.dart` `@AckInfer` declarations from each
/// `<name>.schema.json` draft 2020-12 bundle.
///
/// The generated library declares the model parts that `ack_models` and
/// `ack_model_json` then fill in the same build.
final class AckJsonSchemaBuilder implements Builder {
  /// Creates the builder with its `build.yaml` [options].
  AckJsonSchemaBuilder(this.options);

  /// The parsed builder options.
  final AckJsonSchemaLibraryOptions options;

  @override
  final buildExtensions = const {
    '.schema.json': ['.schema.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final input = buildStep.inputId;
    final Object? document;
    try {
      document = jsonDecode(await buildStep.readAsString(input));
    } on FormatException catch (error) {
      throw FormatException('${input.uri} is not valid JSON: ${error.message}');
    }
    final documents = <Uri, Object>{};
    for (final entry in options.documentPaths.entries) {
      final asset = AssetId(input.package, entry.value);
      if (!await buildStep.canRead(asset)) {
        throw FormatException(
          '${input.uri} cannot read document ${entry.key} at ${entry.value}.',
        );
      }
      try {
        final decoded = jsonDecode(await buildStep.readAsString(asset));
        if (decoded == null) {
          throw const FormatException('Expected a schema object or boolean.');
        }
        documents[input.uri.resolveUri(entry.key)] = decoded;
      } on FormatException catch (error) {
        throw FormatException(
          '${input.uri} document ${entry.key} is not valid JSON: '
          '${error.message}',
        );
      }
    }
    final packageConfig = await buildStep.packageConfig;
    final language = packageConfig[input.package]?.languageVersion;
    final library = generateAckSchemaLibrary(
      document: document,
      documentUri: input.uri,
      partStem: input.pathSegments.last.replaceFirst(RegExp(r'\.json$'), ''),
      options: options,
      documents: documents,
      languageVersion: language == null
          ? null
          : Version(language.major, language.minor, 0),
    );
    await buildStep.writeAsString(
      input.changeExtension('.dart'),
      library.source,
    );
  }
}
