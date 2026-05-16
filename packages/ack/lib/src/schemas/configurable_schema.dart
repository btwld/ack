part of 'schema.dart';

/// Schemas that expose mutation of their runtime-side configuration without
/// changing the concrete schema type.
///
/// Every schema implementation in ACK (primitives, composites, codecs,
/// wrappers) implements this interface. Extension methods like `.refine`,
/// `.nullable`, `.optional`, `.constrain` use it to compose without
/// dynamic casts to implementation classes.
abstract interface class ConfigurableSchema<
  Boundary extends Object,
  Runtime extends Object
> implements AckSchema<Boundary, Runtime> {
  /// Returns a copy of this schema with the supplied runtime-side
  /// configuration replaced. Implementations that do not support a given
  /// field (e.g. a wrapper that owns nullability differently) may ignore
  /// that argument, but should otherwise preserve identity for the others.
  AckSchema<Boundary, Runtime> withRuntimeConfig({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Runtime>>? constraints,
    List<Refinement<Runtime>>? refinements,
  });
}
