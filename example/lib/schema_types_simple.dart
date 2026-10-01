import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part 'schema_types_simple.ack.dart';
part 'schema_types_simple.ack.g.dart';

/// Simple example: Basic primitives
@AckInfer()
final userSchema = Ack.object({
  'name': Ack.string(),
  'age': Ack.integer(),
  'active': Ack.boolean(),
});
