import '../../schemas/schema.dart';

extension RefineExtension<T extends Object> on AckSchema<T> {
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
}
