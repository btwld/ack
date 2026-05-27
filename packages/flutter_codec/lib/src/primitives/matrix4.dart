import 'package:ack/ack.dart';
import 'package:flutter/widgets.dart' show Matrix4;

/// Codec for [Matrix4].
///
/// The encoded list contains exactly 16 finite numbers in [Matrix4.storage]
/// order, which is column-major.
final matrix4Codec = Ack.list(Ack.number())
    .length(16)
    .codec<Matrix4>(
      decode: (values) =>
          Matrix4.fromList(values.map((value) => value.toDouble()).toList()),
      encode: (value) => value.storage.toList(),
    );
