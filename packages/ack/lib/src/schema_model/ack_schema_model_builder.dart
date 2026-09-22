import 'dart:convert';

import 'package:collection/collection.dart';

import '../constraints/constraint.dart';
import '../constraints/datetime_constraint.dart';
import '../context.dart';
import '../json_schema/json_schema_utils.dart';
import '../schemas/schema.dart';
import 'ack_schema_model.dart';
import 'ack_schema_model_warning.dart';

const _deepEquality = DeepCollectionEquality();

extension AckSchemaModelExtension<
  Boundary extends Object,
  Runtime extends Object
>
    on AckSchema<Boundary, Runtime> {
  AckSchemaModel toSchemaModel() => _SchemaModelBuilder().build(this);
}

final class _SchemaModelBuilder {
  // Every emitted definition name is reserved here. A null value marks a lazy
  // target that is currently being built.
  final _definitions = <String, Object?>{};

  // Lazy-target identity is tracked separately because imported definitions
  // are complete schema bodies, not recursive lazy targets.
  final _lazyTargets = <String, Object>{};
  var _importCount = 0;

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

  AckSchemaModel _build(AckSchema<dynamic, dynamic> schema) {
    if (schema is WrapperSchema) {
      final base = _build(schema.inner);
      // Defaults and boundary-preserving wrappers do not transform the wire
      // value, so they should not advertise themselves as transformed.
      final extensions = schema is DefaultSchema || schema is BoundarySchema
          ? base.extensions
          : {...base.extensions, 'x-transformed': true};
      final layered = base
          .withDescription(schema.description ?? base.description)
          .withNullable(schema.isNullable || base.nullable)
          .withExtensions(extensions);
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
      StringSchema() => _string(schema),
      IntegerSchema() => _integer(schema),
      DoubleSchema() => _number(
        description: schema.description,
        nullable: schema.isNullable,
      ),
      NumberSchema() => _number(
        description: schema.description,
        nullable: schema.isNullable,
      ),
      BooleanSchema() => _boolean(schema),
      EnumSchema() => _enum(schema),
      ListSchema() => _array(schema),
      MapSchema() => _map(schema),
      ObjectSchema() => _object(schema),
      AnyOfSchema() => _anyOf(schema),
      AnySchema() => _any(schema),
      InstanceSchema() => _instance(schema),
      DiscriminatedObjectSchema() => _discriminated(schema),
      LazySchema<dynamic, dynamic>() => _lazy(schema),
      ImportedJsonSchema() => _imported(schema),
      _ => throw UnsupportedError(
        'Schema type ${schema.runtimeType} is not supported for AckSchemaModel conversion.',
      ),
    };

    return schema is LazySchema ? model : _applyConstraints(model, schema);
  }

  AckSchemaModel _imported(ImportedJsonSchema schema) {
    final prefix = '_ack_import_${_importCount++}_';
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

  AckSchemaModel _string(StringSchema schema) {
    return AckStringSchemaModel(
      description: schema.description,
      nullable: schema.isNullable,
    );
  }

  AckSchemaModel _integer(IntegerSchema schema) {
    return AckIntegerSchemaModel(
      description: schema.description,
      nullable: schema.isNullable,
    );
  }

  AckSchemaModel _number({String? description, required bool nullable}) {
    return AckNumberSchemaModel(description: description, nullable: nullable);
  }

  AckSchemaModel _boolean(BooleanSchema schema) {
    return AckBooleanSchemaModel(
      description: schema.description,
      nullable: schema.isNullable,
    );
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
      properties[entry.key] = wrapPropertyConversion(
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
    var model = AckRefSchemaModel(
      refName: schema.name,
      description: schema.description,
      nullable: schema.isNullable,
    );
    final constraintCount = schema.runtimeConstraintCount;
    final refinementCount = schema.runtimeRefinementCount;
    if (constraintCount == 0 && refinementCount == 0) {
      return model;
    }

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
    final root = _build(schema);
    if (_definitions.isEmpty) return root;

    return root.withExtensions({
      ...root.extensions,
      'definitions': _mergeRootDefinitions(root.extensions['definitions']),
    });
  }
}

AckSchemaModel _applyConstraints(
  AckSchemaModel model,
  AckSchema<dynamic, dynamic> schema, {
  bool projectKeywords = true,
}) {
  var next = model;
  final appliedKeywordValues = {
    for (final entry in _renderedKeywords(model).entries)
      entry.key: <Object?>[entry.value],
  };
  final omittedConstraintKeys = <String>[];
  for (final constraint in schema.constraints) {
    if (constraint is DateTimeConstraint) {
      next = _applyDateTimeConstraint(next, constraint);
      continue;
    }

    if (constraint is JsonSchemaSpec) {
      final keywords = constraint.toJsonSchema();
      if (!projectKeywords) {
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
