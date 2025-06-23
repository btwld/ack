import '../schema.dart';

extension TransformExtension<T extends Object> on AckSchema<T> {
  TransformedSchema<T, R> transform<R extends Object>(
    R Function(T? value) transformer,
  ) {
    return TransformedSchema(this, transformer);
  }
}
