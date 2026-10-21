import 'package:ack/ack.dart';

part 'schema_types_discriminated.g.dart';

/// Discriminated schema example for immutable model generation with @Schemable.
@Schemable()
final catSchema = Ack.object({'lives': Ack.integer()});

@Schemable()
ObjectSchema get dogSchema => Ack.object({'bark': Ack.boolean()}).passthrough();

@Schemable()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {'cat': catSchema, 'dog': dogSchema},
);
