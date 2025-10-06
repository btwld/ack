import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'schema_types_simple.g.dart';

/// Simple example: Basic primitives
@AckType()
final userSchema = Ack.object({
  'name': Ack.string(),
  'age': Ack.integer(),
  'active': Ack.boolean(),
});
