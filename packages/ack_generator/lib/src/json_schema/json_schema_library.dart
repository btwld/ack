import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';

import '../analyzer/schema_first_names.dart';
import '../utils/string_literal.dart';
import 'json_schema_generation_exception.dart';

part 'json_schema_emitter.dart';
part 'json_schema_translator.dart';

/// How generated models treat properties a JSON Schema object doesn't declare.
enum AckUnknownPropertiesMode {
  /// Follows the schema, where `additionalProperties: false` rejects unknown
  /// keys.
  schema,

  /// Accepts and keeps unknown keys on every object, for clients that must
  /// tolerate additive server changes to strict schemas.
  preserve,
}

/// Whether to prefer typed fields or exact source-schema value wrappers.
enum AckJsonSchemaModelMode { auto, validated }

/// Options for [generateAckSchemaLibrary].
final class AckJsonSchemaLibraryOptions {
  /// Creates generation options.
  const AckJsonSchemaLibraryOptions({
    this.unknownProperties = AckUnknownPropertiesMode.schema,
    this.documentPaths = const {},
    this.assertFormats = false,
    this.modelMode = AckJsonSchemaModelMode.auto,
  });

  /// Parses builder options from `build.yaml`.
  ///
  /// Throws an [ArgumentError] for an unknown key or value.
  factory AckJsonSchemaLibraryOptions.fromConfig(Map<String, Object?> config) {
    final unknown = config.keys.toSet().difference({
      'unknown_properties',
      'documents',
      'assert_formats',
      'model_mode',
    });
    if (unknown.isNotEmpty) {
      throw ArgumentError(
        'Unknown ack_json_schema options: ${unknown.join(', ')}. '
        'Supported: unknown_properties, documents, assert_formats, model_mode.',
      );
    }
    final mode = config['unknown_properties'] ?? 'schema';
    final paths = config['documents'] ?? const <String, String>{};
    if (paths is! Map ||
        paths.keys.any((key) => key is! String) ||
        paths.values.any((value) => value is! String)) {
      throw ArgumentError.value(
        paths,
        'documents',
        'Must map retrieval URI strings to package asset paths.',
      );
    }
    final assertFormats = config['assert_formats'] ?? false;
    if (assertFormats is! bool) {
      throw ArgumentError.value(
        assertFormats,
        'assert_formats',
        'Must be a boolean.',
      );
    }
    return AckJsonSchemaLibraryOptions(
      assertFormats: assertFormats,
      modelMode: switch (config['model_mode'] ?? 'auto') {
        'auto' => AckJsonSchemaModelMode.auto,
        'validated' => AckJsonSchemaModelMode.validated,
        final value => throw ArgumentError.value(
          value,
          'model_mode',
          'Must be "auto" or "validated".',
        ),
      },
      documentPaths: {
        for (final entry in paths.entries)
          Uri.parse(entry.key as String): entry.value as String,
      },
      unknownProperties: switch (mode) {
        'schema' => AckUnknownPropertiesMode.schema,
        'preserve' => AckUnknownPropertiesMode.preserve,
        _ => throw ArgumentError.value(
          mode,
          'unknown_properties',
          'Must be "schema" or "preserve".',
        ),
      },
    );
  }

  /// How objects treat undeclared properties.
  final AckUnknownPropertiesMode unknownProperties;

  /// External schema resources declared in `build.yaml`, keyed by retrieval
  /// URI and stored at package-local asset paths.
  final Map<Uri, String> documentPaths;

  /// Whether to assert known formats even under the standard 2020-12 dialect.
  final bool assertFormats;

  /// Mode for generated models (`auto` retains typed models where possible;
  /// `validated` uses exact source-schema value wrappers for every model).
  final AckJsonSchemaModelMode modelMode;
}

/// A generated Dart library and the document it was checked against.
final class AckJsonSchemaLibrary {
  const AckJsonSchemaLibrary._({
    required this.source,
    required this.effectiveDocument,
    required this.widenedPointers,
  });

  /// The formatted Dart source.
  final String source;

  /// The input document with the option widenings applied.
  ///
  /// Validated value models use `Ack.fromJsonSchema` directly. Typed models
  /// retain the documented integer-range and string-length edge cases.
  final Map<String, Object?> effectiveDocument;

  /// Pointers of objects whose unknown-property rule an option widened.
  final List<String> widenedPointers;
}

/// Generates typed Ack models or validated value models from a draft 2020-12
/// [document].
///
/// [documentUri] identifies the document in diagnostics and resolves its
/// references. [documents] supplies offline external resources. [partStem]
/// names typed model parts (`<stem>.g.dart`); value-model fallback needs no
/// parts. Set [includeParts] to `false` for a plain typed schema library.
///
/// Throws an [AckJsonSchemaGenerationException] for invalid or unresolvable
/// schema resources, with source pointers where available.
AckJsonSchemaLibrary generateAckSchemaLibrary({
  required Object? document,
  required Uri documentUri,
  required String partStem,
  AckJsonSchemaLibraryOptions options = const AckJsonSchemaLibraryOptions(),
  Map<Uri, Object> documents = const {},
  bool includeParts = true,
  Version? languageVersion,
}) {
  if (options.modelMode == AckJsonSchemaModelMode.auto) {
    final translator = _Translator(documentUri, options, documents);
    final effective = translator.prepare(document);
    if (effective != null) translator.translate(effective);
    if (translator.diagnostics.isEmpty) {
      final unformatted = _emit(
        translator,
        documentUri: documentUri,
        partStem: partStem,
        includeParts: includeParts,
      );
      return AckJsonSchemaLibrary._(
        source: DartFormatter(
          languageVersion:
              languageVersion ?? DartFormatter.latestLanguageVersion,
        ).format(unformatted),
        effectiveDocument: effective!,
        widenedPointers: List.unmodifiable(translator.widened),
      );
    }
  }

  // The typed translator is intentionally conservative. A valid document it
  // cannot lower still generates a value model with the source validator as
  // its parse/encode boundary, so no 2020-12 assertion is silently dropped.
  final fallbackDocuments = <Uri, Object>{
    for (final entry in documents.entries) entry.key: _deepCopy(entry.value)!,
  };
  final fallback = _Translator(documentUri, options, fallbackDocuments);
  final fallbackDocument = fallback.prepareFallback(document);
  if (fallback.diagnostics.isNotEmpty) {
    throw AckJsonSchemaGenerationException(documentUri, fallback.diagnostics);
  }
  return AckJsonSchemaLibrary._(
    source:
        DartFormatter(
          languageVersion:
              languageVersion ?? DartFormatter.latestLanguageVersion,
        ).format(
          _emitFallback(
            fallbackDocument!,
            documentUri: documentUri,
            documents: fallbackDocuments,
            assertFormats: options.assertFormats,
            widened: fallback.widened,
          ),
        ),
    effectiveDocument: fallbackDocument,
    widenedPointers: List.unmodifiable(fallback.widened),
  );
}
