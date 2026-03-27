import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'pet.g.dart';

/// Pet schemas: discriminated by 'type'
@AckType()
final catSchema = Ack.object({
  'type': Ack.literal('cat'),
  'lives': Ack.integer().min(1).max(9),
});

@AckType()
final dogSchema = Ack.object({
  'type': Ack.literal('dog'),
  'breed': Ack.string().minLength(1),
});

@AckType()
final petSchema = Ack.discriminated(
  discriminatorKey: 'type',
  schemas: {'cat': catSchema, 'dog': dogSchema},
);
