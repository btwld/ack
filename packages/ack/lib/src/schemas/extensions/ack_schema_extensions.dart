import '../../schemas/schema.dart';

/// Core extensions for all AckSchema types.
/// Provides common functionality like refinement, transformation, and optional marking.
extension AckSchemaExtensions<T extends Object> on AckSchema<T> {
  /// Adds a custom validation check that runs after all other validations for this schema have passed.
  ///
  /// [validate] is a function that receives the parsed value of type [T] and must return `true` if the validation passes, and `false` otherwise.
  ///
  /// [message] is the custom error message to be used if the validation fails.
  AckSchema<T> refine(
    bool Function(T value) validate, {
    String message = 'The value did not pass the custom validation.',
  }) {
    final newRefinement = (validate: validate, message: message);

    // Create a new schema instance with the new refinement added to the list.
    return copyWith(refinements: [...refinements, newRefinement]);
  }

  /// Makes the schema optional - the field can be omitted from an object.
  /// This is different from nullable() which allows null values but requires the field to be present.
  OptionalSchema<T> optional() => OptionalSchema(wrappedSchema: this);

  /// Transforms the validated value using the provided transformer function.
  ///
  /// The transformer is applied after all validations pass.
  /// This is useful for converting data types or applying business logic transformations.
  TransformedSchema<T, R> transform<R extends Object>(
    R Function(T? value) transformer,
  ) {
    return TransformedSchema(this, transformer);
  }
}
