import 'package:ack/ack.dart';
import 'package:flutter/painting.dart'
    show TextHeightBehavior, TextLeadingDistribution;

import '../enums.dart' show textLeadingDistributionCodec;
import '../json_readers.dart';

/// Codec for [TextHeightBehavior].
///
/// Composes `applyHeightToFirstAscent` and `applyHeightToLastDescent`
/// (booleans, both default `true`) with [textLeadingDistributionCodec] for
/// `leadingDistribution` (default [TextLeadingDistribution.proportional]).
/// All three fields match Flutter's constructor defaults, so encoding a
/// default [TextHeightBehavior] round-trips through both encode and parse.
final textHeightBehaviorCodec =
    Ack.object({
      'applyHeightToFirstAscent': Ack.boolean().withDefault(true),
      'applyHeightToLastDescent': Ack.boolean().withDefault(true),
      'leadingDistribution': textLeadingDistributionCodec.withDefault(
        TextLeadingDistribution.proportional,
      ),
    }).codec<TextHeightBehavior>(
      decode: (data) => TextHeightBehavior(
        applyHeightToFirstAscent: readValue<bool>(
          data,
          'applyHeightToFirstAscent',
        ),
        applyHeightToLastDescent: readValue<bool>(
          data,
          'applyHeightToLastDescent',
        ),
        leadingDistribution: readValue<TextLeadingDistribution>(
          data,
          'leadingDistribution',
        ),
      ),
      encode: (value) => {
        'applyHeightToFirstAscent': value.applyHeightToFirstAscent,
        'applyHeightToLastDescent': value.applyHeightToLastDescent,
        'leadingDistribution': value.leadingDistribution,
      },
    );
