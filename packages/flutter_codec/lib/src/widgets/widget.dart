import 'package:ack/ack.dart';
import 'package:flutter/widgets.dart' show Widget;

import 'container.dart' show containerWidgetCodec;
import 'text.dart' show textWidgetCodec;

/// Codec for the supported [Widget] union, discriminated by `"type"`.
///
/// The union starts with [Container]. Additional widget branches register here
/// as they gain first-class codecs.
final DiscriminatedObjectSchema<Widget> widgetCodec = Ack.discriminated<Widget>(
  discriminatorKey: 'type',
  schemas: {'container': containerWidgetCodec, 'text': textWidgetCodec},
);
