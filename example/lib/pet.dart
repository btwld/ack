import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part 'pet.ack.dart';
part 'pet.ack.g.dart';

/// Pet schemas: discriminated by 'type'
@AckInfer()
final catSchema = Ack.object({
  'type': Ack.literal('cat'),
  'lives': Ack.integer().min(1).max(9),
});

@AckInfer()
final dogSchema = Ack.object({
  'type': Ack.literal('dog'),
  'breed': Ack.string().minLength(1),
});

@AckInfer()
final petSchema = Ack.discriminated(
  discriminatorKey: 'type',
  schemas: {'cat': catSchema, 'dog': dogSchema},
);
