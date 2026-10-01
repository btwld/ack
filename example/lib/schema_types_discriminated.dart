import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part 'schema_types_discriminated.ack.dart';
part 'schema_types_discriminated.ack.g.dart';

/// Discriminated schema example for immutable model generation with @AckInfer.
@AckInfer()
final catSchema = Ack.object({'lives': Ack.integer()});

@AckInfer()
ObjectSchema get dogSchema => Ack.object({'bark': Ack.boolean()}).passthrough();

@AckInfer()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {'cat': catSchema, 'dog': dogSchema},
);
