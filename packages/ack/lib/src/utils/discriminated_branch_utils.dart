import '../schemas/schema.dart';

AckSchema unwrapDiscriminatedBranchSchema(AckSchema schema) {
  var current = schema;
  while (current is TransformedSchema) {
    current = current.schema;
  }

  return current;
}
