import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'schema_types_discriminated.g.dart';

/// Discriminated schema example for @AckType extension generation.
@AckType()
final catSchema = Ack.object({
  'kind': Ack.literal('cat'),
  'lives': Ack.integer(),
});

@AckType()
ObjectSchema get dogSchema => Ack.object({
  'kind': Ack.literal('dog'),
  'bark': Ack.boolean(),
}).passthrough();

@AckType()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {'cat': catSchema, 'dog': dogSchema},
);
