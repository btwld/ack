import 'package:ack/ack.dart';

part 'pet.g.dart';

/// Pet schemas: discriminated by 'type'
@Schemable()
final catSchema = Ack.object({
  'type': Ack.literal('cat'),
  'lives': Ack.integer().min(1).max(9),
});

@Schemable()
final dogSchema = Ack.object({
  'type': Ack.literal('dog'),
  'breed': Ack.string().minLength(1),
});

@Schemable()
final petSchema = Ack.discriminated(
  discriminatorKey: 'type',
  schemas: {'cat': catSchema, 'dog': dogSchema},
);
