import 'dart:collection';
import 'dart:convert';

import 'package:collection/collection.dart';

import '../constraints/constraint.dart';
import '../constraints/datetime_constraint.dart';
import '../context.dart';
import '../schemas/schema.dart';
import '../utils/json_utils.dart';
import 'ack_schema_model.dart';
import 'ack_schema_model_warning.dart';

const _deepEquality = DeepCollectionEquality();

extension AckSchemaModelExtension<
  Boundary extends Object,
  Runtime extends Object
>
    on AckSchema<Boundary, Runtime> {
  /// Converts this schema into an [AckSchemaModel], preserving imported Draft
  /// 2020-12 resources including dynamic references.
  ///
  /// Native Ack schemas continue to use their Draft-7 representation.
  AckSchemaModel toSchemaModel() =>
      _SchemaModelBuilder(preserveImportedDialect: true).build(this);

  /// Lowers imported schemas into the legacy Draft-7 `definitions` / `$ref`
  /// representation when possible.
  AckSchemaModel toSchemaModelDraft7() =>
      _SchemaModelBuilder(preserveImportedDialect: false).build(this);

  /// Exports imported schemas using the legacy Draft-7 `definitions` / `$ref`
  /// representation when possible.
  Map<String, Object?> toJsonSchemaDraft7() =>
      toSchemaModelDraft7().toJsonSchema();
}

final class _SchemaModelBuilder {
  _SchemaModelBuilder({this.preserveImportedDialect = true});

  final bool preserveImportedDialect;
  // Every emitted definition name is reserved here. A null value marks a lazy
  // target that is currently being built.
  final _definitions = <String, Object?>{};

  // Lazy-target identity is tracked separately from emitted definitions.
  final _lazyTargets = <String, Object>{};
  var _importCount = 0;
  var _composingImports = false;
  final _importedResources = <Uri, Map<String, Object?>>{};
  final _resourceLocations = <Uri, Uri>{};

  Map<String, Object?> _mergeRootDefinitions(Object? existingDefinitions) {
    final schemaDefinitions = <String, Object?>{};
    for (final entry in _definitions.entries) {
      switch (entry.value) {
        case final AckSchemaModel model:
          schemaDefinitions[entry.key] = model.toJsonSchema();
        case final Map<String, Object?> schema:
          schemaDefinitions[entry.key] = schema;
        case null:
          break;
        default:
          throw StateError('Invalid schema definition for "${entry.key}".');
      }
    }
    if (existingDefinitions == null) return schemaDefinitions;
    if (existingDefinitions is! Map) {
      throw ArgumentError(
        'Root JSON Schema definitions must be a map when generated '
        'definitions are exported.',
      );
    }

    final merged = <String, Object?>{};
    for (final entry in existingDefinitions.entries) {
      final key = entry.key;
      if (key is! String) {
        throw ArgumentError(
          'Root JSON Schema definitions keys must be strings when generated '
          'definitions are exported.',
        );
      }
      merged[key] = entry.value;
    }

    for (final entry in schemaDefinitions.entries) {
      if (merged.containsKey(entry.key)) {
        if (!_deepEquality.equals(merged[entry.key], entry.value)) {
          throw ArgumentError(
            'Generated definition "${entry.key}" collides with an existing '
            'root JSON Schema definition. Use a unique lazy name or rename '
            'the existing definition.',
          );
        }
        continue;
      }
      merged[entry.key] = entry.value;
    }

    return merged;
  }

  AckSchemaModel _build(
    AckSchema<dynamic, dynamic> schema, {
    bool requireStandardDialect = false,
  }) {
    if (schema is WrapperSchema) {
      // Wrappers can add null operators or projected constraints. Keep those
      // outside a source dialect that may have disabled their vocabularies.
      final base = _build(schema.inner, requireStandardDialect: true);
      var layered = base
          .withDescription(schema.description ?? base.description)
          .withNullable(schema.isNullable);
      if (schema.excludesInnerNull && _admitsNull(layered)) {
        layered = _excludeNull(layered);
      }
      // `DefaultSchema.constraints` is a passthrough to `inner.constraints`,
      // which `_build(schema.inner)` already applied. Re-running them here
      // would emit duplicate warnings (e.g. datetime range under a default).
      //
      // A codec's constraints are declared in runtime terms, so projecting
      // them onto the boundary schema is only honest when the codec says its
      // mapping preserves them. Otherwise the keyword is omitted and the
      // omission is reported.
      var wrapped = schema is DefaultSchema
          ? layered
          : _applyConstraints(
              layered,
              schema,
              projectKeywords:
                  schema is! CodecSchema ||
                  schema.projectsConstraintsToBoundary,
            );

      if (schema is DefaultSchema) {
        final exportDefault = _defaultExportValueOrNull(schema);
        if (exportDefault != null) {
          wrapped = wrapped.withDefaultValue(exportDefault);
        } else {
          wrapped = wrapped.withWarnings([
            ...wrapped.warnings,
            AckSchemaModelWarning(
              code: 'default_not_export_safe',
              message:
                  'Schema default was omitted because it cannot be represented safely in exported JSON-compatible schema models.',
            ),
          ]);
        }
      }

      return wrapped;
    }

    final model = switch (schema) {
      StringSchema() => AckStringSchemaModel(
        description: schema.description,
        nullable: schema.isNullable,
      ),
      IntegerSchema() => AckIntegerSchemaModel(
        description: schema.description,
        nullable: schema.isNullable,
      ),
      DoubleSchema() || NumberSchema() => AckNumberSchemaModel(
        description: schema.description,
        nullable: schema.isNullable,
      ),
      BooleanSchema() => AckBooleanSchemaModel(
        description: schema.description,
        nullable: schema.isNullable,
      ),
      EnumSchema() => _enum(schema),
      ListSchema() => _array(schema),
      MapSchema() => _map(schema),
      ObjectSchema() => _object(schema),
      AnyOfSchema() => _anyOf(schema),
      AnySchema() => _any(schema),
      InstanceSchema() => _instance(schema),
      DiscriminatedObjectSchema() => _discriminated(schema),
      LazySchema<dynamic, dynamic>() => _lazy(schema),
      ImportedJsonSchema() => _imported(
        schema,
        requireStandardDialect: requireStandardDialect,
      ),
      _ => throw UnsupportedError(
        'Schema type ${schema.runtimeType} is not supported for AckSchemaModel conversion.',
      ),
    };

    return schema is LazySchema ? model : _applyConstraints(model, schema);
  }

  AckSchemaModel _imported(
    ImportedJsonSchema schema, {
    required bool requireStandardDialect,
  }) {
    final importIndex = _importCount++;
    if (preserveImportedDialect) {
      final indexedSchemas = HashSet<Map<String, Object?>>.identity();
      final needsAssertionEnvelope =
          schema.needsStandardAssertionEnvelope &&
          (requireStandardDialect ||
              schema.isNullable != schema.sourceAllowsNull ||
              schema.constraints.isNotEmpty);
      if (_composingImports || needsAssertionEnvelope) {
        final document = schema.export2020Document(
          importIndex: importIndex,
          includeFluentNullability: false,
          onSchema: indexedSchemas.add,
        );
        return AckAllOfSchemaModel(
          schemas: [
            AckRawSchemaModel(
              schema: _shareImportedResources(document, indexedSchemas),
              indexedSchemas: indexedSchemas,
            ),
          ],
          description: schema.description,
          nullable: schema.isNullable,
          extensions: {
            if (!schema.isNullable && schema.sourceAllowsNull)
              'not': const {'type': 'null'},
          },
        );
      }
      return AckRawSchemaModel(
        schema: schema.export2020Document(
          importIndex: importIndex,
          onSchema: indexedSchemas.add,
        ),
        indexedSchemas: indexedSchemas,
        description: schema.description,
        nullable:
            schema.isNullable &&
            (!schema.sourceAllowsNull || schema.constraints.isNotEmpty),
      );
    }
    final prefix = '_ack_import_${importIndex}_';
    for (final entry in schema.exportDefinitions(prefix).entries) {
      if (_definitions.containsKey(entry.key)) {
        throw ArgumentError(
          'Imported definition collides with "${entry.key}".',
        );
      }
      _definitions[entry.key] = entry.value;
    }
    final sourceNullable = schema.sourceAllowsNull;
    // Draft-7 ignores siblings of a bare $ref. Keep the imported root in an
    // allOf envelope so fluent metadata and constraints remain effective.
    return AckAllOfSchemaModel(
      schemas: [AckRefSchemaModel(refName: '${prefix}0')],
      description: schema.description,
      extensions: {
        if (!schema.isNullable && sourceNullable) 'not': const {'type': 'null'},
      },
      nullable: schema.isNullable,
    );
  }

  // Resource identity belongs to the imported document, not an occurrence's
  // fluent constraints. Keep one copy and reference it from later occurrences.
  Map<String, Object?> _shareImportedResources(
    Map<String, Object?> document,
    Set<Map<String, Object?>> indexedSchemas,
  ) {
    final locations = <Uri, Uri>{};
    Uri location(Uri base, List<String> path) => path.isEmpty
        ? base.removeFragment()
        : base.replace(
            fragment: '/${path.map(escapeJsonPointerToken).join('/')}',
          );

    Object? index(Object? value, Uri base, List<(Uri, List<String>)> scopes) {
      final id = value is Map<String, Object?> ? value[r'$id'] : null;
      if (id is String) {
        try {
          base = base.resolve(id);
          final address = scopes.isEmpty
              ? base
              : location(scopes.first.$1, scopes.first.$2);
          _resourceLocations.putIfAbsent(base, () => address);
          scopes = [...scopes, (base, <String>[])];
        } on FormatException {
          // Dormant malformed $id values in unreachable definitions remain as-is.
        }
      }
      for (final (uri, path) in scopes) {
        final (resource, relativePath) = scopes.last;
        locations[location(uri, path)] = location(resource, relativePath);
      }
      if (value is! Map<String, Object?>) return value;
      return _mapImportedChildren(
        value,
        (child, path) => index(child, base, [
          for (final (uri, prefix) in scopes) (uri, [...prefix, ...path]),
        ]),
        indexedSchemas,
      );
    }

    final base = Uri.parse(document[r'$id']! as String);
    index(document, base, []);

    Uri canonicalLocation(Uri reference) {
      if (locations[reference] case final exact?) return exact;
      // Boolean schemas have no map identity to index. Their pointer still
      // follows the canonical resource of the nearest indexed ancestor.
      var prefix = reference.fragment;
      while (prefix.startsWith('/')) {
        prefix = prefix.substring(0, prefix.lastIndexOf('/'));
        final ancestor = prefix.isEmpty
            ? reference.removeFragment()
            : reference.replace(fragment: prefix);
        if (locations[ancestor] case final canonical?) {
          return canonical.replace(
            fragment:
                '${canonical.fragment}${reference.fragment.substring(prefix.length)}',
          );
        }
      }
      return reference;
    }

    Object? normalize(Object? value, Uri base) {
      if (value is! Map<String, Object?>) return value;
      final id = value[r'$id'];
      var resolvedValidId = false;
      if (id is String) {
        try {
          base = base.resolve(id);
          resolvedValidId = true;
        } on FormatException {
          // Dormant malformed $id values in unreachable definitions remain as-is.
        }
      }
      final result = _mapImportedChildren(
        value,
        (child, _) => normalize(child, base),
        indexedSchemas,
      );
      if (indexedSchemas.contains(value)) indexedSchemas.add(result);
      if (resolvedValidId) result[r'$id'] = base.toString();
      for (final keyword in [r'$ref', r'$dynamicRef']) {
        final ref = result[keyword];
        if (ref is String) {
          Uri resolved;
          try {
            resolved = base.resolve(ref);
          } on FormatException {
            // Dormant malformed references are not evaluated by the importer.
            continue;
          }
          final canonical = canonicalLocation(resolved);
          final address = _resourceLocations[canonical.removeFragment()];
          if (address != null &&
              (canonical.fragment.isEmpty ||
                  canonical.fragment.startsWith('/'))) {
            result[keyword] = address
                .replace(fragment: '${address.fragment}${canonical.fragment}')
                .toString();
          } else {
            result[keyword] = canonical.toString();
          }
        }
      }
      return result;
    }

    Object? share(Object? value) {
      if (value is! Map<String, Object?>) return value;
      final id = value[r'$id'];
      if (id is String) {
        final uri = Uri.tryParse(id);
        if (uri != null) {
          final existing = _importedResources[uri];
          if (existing != null) {
            if (!_deepEquality.equals(existing, value)) {
              throw ArgumentError(
                'Conflicting imported schema resource "$uri".',
              );
            }
            return <String, Object?>{
              r'$ref': _resourceLocations[uri].toString(),
            };
          }
          _importedResources[uri] = value;
        }
      }
      final rebuilt = _mapImportedChildren(
        value,
        (child, _) => share(child),
        indexedSchemas,
      );
      if (indexedSchemas.contains(value)) indexedSchemas.add(rebuilt);
      return rebuilt;
    }

    return share(normalize(document, base))! as Map<String, Object?>;
  }

  AckSchemaModel _enum(EnumSchema schema) {
    return AckStringSchemaModel(
      description: schema.description,
      enumValues: [for (final value in schema.values) value.name],
      nullable: schema.isNullable,
    );
  }

  AckSchemaModel _array(ListSchema schema) {
    return AckArraySchemaModel(
      description: schema.description,
      nullable: schema.isNullable,
      items: _build(schema.itemSchema),
    );
  }

  AckSchemaModel _map(MapSchema schema) {
    return AckObjectSchemaModel(
      description: schema.description,
      nullable: schema.isNullable,
      additionalProperties: AckAdditionalPropertiesSchema(
        _build(schema.valueSchema),
      ),
    );
  }

  AckSchemaModel _object(ObjectSchema schema) {
    final properties = <String, AckSchemaModel>{};
    final required = <String>[];
    final ordering = <String>[];

    for (final entry in schema.properties.entries) {
      ordering.add(entry.key);
      properties[entry.key] = _wrapPropertyConversion(
        entry.key,
        () => _build(entry.value),
      );
      if (_isRequiredObjectProperty(entry.value)) {
        required.add(entry.key);
      }
    }

    return AckObjectSchemaModel(
      description: schema.description,
      nullable: schema.isNullable,
      properties: properties.isEmpty ? null : properties,
      required: required.isEmpty ? null : required,
      propertyOrdering: ordering.isEmpty ? null : ordering,
      additionalProperties: schema.additionalProperties
          ? const AckAdditionalPropertiesAllowed()
          : const AckAdditionalPropertiesDisallowed(),
    );
  }

  AckSchemaModel _anyOf(AnyOfSchema schema) {
    return AckAnyOfSchemaModel(
      schemas: schema.schemas.map(_build).toList(growable: false),
      nullable: schema.isNullable,
      description: schema.description,
    );
  }

  AckSchemaModel _instance(InstanceSchema schema) {
    // InstanceSchema accepts arbitrary Dart instances of a runtime type with no
    // direct JSON representation. Adapters that flow through a codec see the
    // boundary schema instead; this is the fallback for a bare instance.
    return AckAnyOfSchemaModel(
      schemas: [
        AckStringSchemaModel(description: schema.description),
        AckNumberSchemaModel(description: schema.description),
        AckIntegerSchemaModel(description: schema.description),
        AckBooleanSchemaModel(description: schema.description),
        AckObjectSchemaModel(description: schema.description),
        AckArraySchemaModel(description: schema.description),
      ],
      nullable: schema.isNullable,
      description: schema.description,
      warnings: const [
        AckSchemaModelWarning(
          code: 'ack_instance_json_boundary',
          message:
              'Ack.instance<T>() accepts arbitrary Dart instances at runtime; JSON-like adapters can only represent JSON-compatible values.',
        ),
      ],
    );
  }

  AckSchemaModel _any(AnySchema schema) {
    final description = schema.description;
    final primitiveBranches = [
      AckStringSchemaModel(description: description),
      AckNumberSchemaModel(description: description),
      AckIntegerSchemaModel(description: description),
      AckBooleanSchemaModel(description: description),
      AckObjectSchemaModel(description: description),
      AckArraySchemaModel(description: description),
    ];

    return AckAnyOfSchemaModel(
      schemas: primitiveBranches,
      nullable: schema.isNullable,
      description: description,
      warnings: const [
        AckSchemaModelWarning(
          code: 'ack_any_json_boundary',
          message:
              'Ack.any() accepts non-null JSON-safe values at runtime, matching the JSON-compatible values adapters can represent.',
        ),
      ],
    );
  }

  AckSchemaModel _discriminated(DiscriminatedObjectSchema schema) {
    if (schema.schemas.isEmpty) {
      return AckObjectSchemaModel(
        properties: const {},
        required: const [],
        nullable: schema.isNullable,
        description: schema.description,
      );
    }

    final branches = <AckSchemaModel>[];
    for (final entry in schema.schemas.entries) {
      final converted = _build(schema.effectiveBranch(entry.key));
      if (converted is! AckObjectSchemaModel) {
        throw ArgumentError(
          'Discriminated branch "${entry.key}" must export as an object schema model.',
        );
      }
      branches.add(converted);
    }

    return AckAnyOfSchemaModel(
      schemas: branches,
      discriminator: AckSchemaDiscriminatorModel(
        propertyName: schema.discriminatorKey,
      ),
      description: schema.description,
      nullable: schema.isNullable,
    );
  }

  AckSchemaModel _lazy(LazySchema<dynamic, dynamic> schema) {
    final name = schema.name;
    final target = schema.target;
    final priorTarget = _lazyTargets[name];
    if (priorTarget != null) {
      if (!identical(priorTarget, target)) {
        throw ArgumentError(
          'Two Ack.lazy entries share name "$name" but resolve to different '
          'schemas. Use unique names per recursive target.',
        );
      }

      return _lazyRef(schema);
    }

    if (_definitions.containsKey(name)) {
      throw ArgumentError(
        'Ack.lazy definition "$name" collides with an imported definition. '
        'Use a unique lazy name.',
      );
    }

    _lazyTargets[name] = target;
    _definitions[name] = null;
    _definitions[name] = _build(target);

    return _lazyRef(schema);
  }

  AckSchemaModel _lazyRef(LazySchema<dynamic, dynamic> schema) {
    AckSchemaModel model = AckRefSchemaModel(
      refName: schema.name,
      description: schema.description,
      nullable: schema.isNullable,
    );
    if (schema.excludesTargetNull) model = _excludeNull(model);
    final constraintCount = schema.runtimeConstraintCount;
    final refinementCount = schema.runtimeRefinementCount;

    return model.withWarnings([
      ...model.warnings,
      AckSchemaModelWarning(
        code: 'lazy_runtime_checks_not_export_safe',
        message:
            'Ack.lazy constraints and refinements were omitted because JSON Schema refs cannot safely carry runtime-only validation checks.',
        context: {
          'constraintCount': constraintCount,
          'refinementCount': refinementCount,
        },
      ),
    ]);
  }

  AckSchemaModel build(AckSchema<dynamic, dynamic> schema) {
    var unwrapped = schema;
    while (unwrapped is WrapperSchema) {
      unwrapped = unwrapped.inner;
    }
    _composingImports = unwrapped is! ImportedJsonSchema;
    final root = _build(schema);
    final needs2020Dialect =
        preserveImportedDialect &&
        _importCount > 0 &&
        root is! AckRawSchemaModel &&
        !root.extensions.containsKey(r'$schema');
    if (_definitions.isEmpty && !needs2020Dialect) return root;

    return root.withExtensions({
      if (needs2020Dialect)
        r'$schema': 'https://json-schema.org/draft/2020-12/schema',
      ...root.extensions,
      if (_definitions.isNotEmpty)
        'definitions': _mergeRootDefinitions(root.extensions['definitions']),
    });
  }
}

/// Whether [model] can still accept `null` after its own nullable flag.
///
/// References, imported resources, and extension keywords are opaque here, so
/// they count as accepting `null`.
bool _admitsNull(AckSchemaModel model) {
  if (model.nullable || model.extensions.isNotEmpty) return true;
  return switch (model) {
    AckRefSchemaModel() || AckRawSchemaModel() || AckNullSchemaModel() => true,
    AckAnyOfSchemaModel(:final schemas) ||
    AckOneOfSchemaModel(:final schemas) => schemas.any(_admitsNull),
    AckAllOfSchemaModel(:final schemas) => schemas.every(_admitsNull),
    _ => false,
  };
}

AckSchemaModel _excludeNull(AckSchemaModel model) => model.withExtensions({
  ...model.extensions,
  'allOf': [
    ...?model.extensions['allOf'] as List<Object?>?,
    const {
      'not': {'type': 'null'},
    },
  ],
});

AckSchemaModel _applyConstraints(
  AckSchemaModel model,
  AckSchema<dynamic, dynamic> schema, {
  bool projectKeywords = true,
}) {
  var next = model;
  // Rendering the model walks its whole subtree, so only do it once a
  // constraint actually projects keywords.
  late final appliedKeywordValues = {
    for (final entry in _renderedKeywords(model).entries)
      entry.key: <Object?>[entry.value],
  };
  final postNormalizerStart = schema is StringSchema
      ? schema.firstPostNormalizerConstraintIndex
      : null;
  final omittedConstraintKeys = <String>[];
  for (final (index, constraint) in schema.constraints.indexed) {
    final projectConstraint =
        projectKeywords &&
        (postNormalizerStart == null || index < postNormalizerStart);
    if (constraint is DateTimeConstraint) {
      next = _applyDateTimeConstraint(next, constraint);
      continue;
    }

    if (constraint is JsonSchemaSpec) {
      final keywords = constraint.toJsonSchema();
      if (!projectConstraint) {
        if (keywords.isNotEmpty) {
          omittedConstraintKeys.add(constraint.constraintKey);
        }
        continue;
      }
      final newKeywords = <String, Object?>{};
      final conflicts = <String, Object?>{};
      for (final entry in keywords.entries) {
        final seenValues = appliedKeywordValues[entry.key];
        if (seenValues == null) {
          appliedKeywordValues[entry.key] = [entry.value];
          newKeywords[entry.key] = entry.value;
        } else if (!seenValues.any(
          (value) => _deepEquality.equals(value, entry.value),
        )) {
          seenValues.add(entry.value);
          conflicts[entry.key] = entry.value;
        }
      }
      if (newKeywords.isNotEmpty) {
        next = next.withJsonSchemaKeywords(newKeywords);
      }
      if (conflicts.isNotEmpty) {
        appliedKeywordValues.putIfAbsent('allOf', () => <Object?>[]);
        final existingAllOf = switch (next.extensions['allOf']) {
          final List<Object?> value => value,
          _ => const <Object?>[],
        };
        next = next.withExtensions({
          ...next.extensions,
          'allOf': [...existingAllOf, conflicts],
        });
      }
    }
  }

  if (omittedConstraintKeys.isEmpty) return next;

  return next.withWarnings([
    ...next.warnings,
    AckSchemaModelWarning(
      code: 'codec_runtime_constraint_not_exported',
      message:
          'Codec constraints were omitted because they validate runtime values, not the encoded boundary values the exported schema describes.',
      context: {'constraints': omittedConstraintKeys},
    ),
  ]);
}

Map<String, Object?> _renderedKeywords(AckSchemaModel model) {
  final rendered = model.toJsonSchema();
  final branches = rendered['anyOf'];
  if (model.nullable && branches is List && branches.isNotEmpty) {
    final nonNullBranch = branches.first;
    if (nonNullBranch is Map) {
      return Map<String, Object?>.from(nonNullBranch);
    }
  }
  return rendered;
}

AckSchemaModel _applyDateTimeConstraint(
  AckSchemaModel model,
  DateTimeConstraint constraint,
) {
  return model.withWarnings([
    ...model.warnings,
    AckSchemaModelWarning(
      code: 'datetime_constraint_not_draft7',
      message:
          'DateTime range constraints are not emitted because JSON Schema Draft-7 has no standard format range keywords.',
      context: {
        'constraint': constraint.comparisonType,
        'reference': constraint.formattedReference,
        'format': constraint.jsonSchemaFormat,
      },
    ),
  ]);
}

/// Best-effort export of a [DefaultSchema] default value.
///
/// Encodes the runtime default through the wrapped schema so codec
/// transformations are applied, then verifies the result is JSON-safe before
/// returning it. Returns `null` when no JSON-safe representation is reachable.
Object? _defaultExportValueOrNull(DefaultSchema<dynamic, dynamic> schema) {
  final resolved = schema.resolveDefaultWithContext(
    _defaultExportContext(schema),
  );
  if (resolved.isFail) return null;

  final defaultValue = resolved.getOrNull();
  if (defaultValue == null) return null;

  final encoded = schema.inner.safeEncode(defaultValue);
  if (encoded.isFail) return null;

  return _jsonRoundTripOrNull(encoded.getOrNull());
}

bool _isRequiredObjectProperty(AckSchema<dynamic, dynamic> schema) {
  if (schema.isOptional) return false;
  if (schema is DefaultSchema &&
      schema.resolveDefaultWithContext(_defaultExportContext(schema)).isOk) {
    return false;
  }

  return true;
}

/// Throwaway [SchemaContext] used only to drive
/// [DefaultSchema.resolveDefaultWithContext]. Errors produced through this
/// context are never surfaced — both callers consume only `.isOk` /
/// `.getOrNull()` — so the rooted error path is intentional.
SchemaContext _defaultExportContext(DefaultSchema<dynamic, dynamic> schema) {
  return SchemaContext(
    name: schema.schemaTypeName,
    schema: schema as AnyAckSchema,
    value: null,
  );
}

Object? _jsonRoundTripOrNull(Object? value) {
  if (value == null) return null;
  try {
    return jsonDecode(jsonEncode(value));
  } catch (_) {
    return null;
  }
}

/// Adds the property name to supported conversion errors without losing stacks.
T _wrapPropertyConversion<T>(String key, T Function() fn) {
  try {
    return fn();
  } catch (e, st) {
    final msg =
        'Error converting property "$key": ${e is Error ? e.toString() : e}';
    if (e is UnsupportedError) {
      Error.throwWithStackTrace(UnsupportedError(msg), st);
    } else if (e is ArgumentError) {
      Error.throwWithStackTrace(ArgumentError(msg), st);
    } else if (e is StateError) {
      Error.throwWithStackTrace(StateError(msg), st);
    }
    rethrow;
  }
}

// Rewrite identities only at compiler-indexed schema locations. Annotation
// payloads stay ordinary data unless explicitly referenced as schemas.
Map<String, Object?> _mapImportedChildren(
  Map<String, Object?> schema,
  Object? Function(Object?, List<String>) visit,
  Set<Map<String, Object?>> indexedSchemas,
) {
  Object? visitIndexed(Object? value, List<String> path) {
    if (value is Map<String, Object?>) {
      if (indexedSchemas.contains(value)) return visit(value, path);
      return {
        for (final entry in value.entries)
          entry.key: visitIndexed(entry.value, [...path, entry.key]),
      };
    }
    if (value is List) {
      return [
        for (final (index, child) in value.indexed)
          visitIndexed(child, [...path, '$index']),
      ];
    }
    return value;
  }

  return {
    for (final entry in schema.entries)
      entry.key: visitIndexed(entry.value, [entry.key]),
  };
}
