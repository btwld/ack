// These tests intentionally cover the deprecated annotations.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:ack/annotations.dart';
import 'package:ack/ack_generator_support.dart';
import 'package:test/test.dart';

void main() {
  test('public barrel exposes legacy AckType and modern AckInfer', () {
    const legacy = AckType(name: 'User');
    const modern = AckInfer(name: 'User');
    expect(legacy.name, 'User');
    expect(modern.name, 'User');
    expect(AckInfer.jsonSerializable, isA<AckGeneratedJson>());
  });

  test('support barrel exposes the marker with fixed null omission', () {
    const marker = AckGeneratedJson();
    expect(marker.config.includeIfNull, isFalse);

    final generated = AckInfer.jsonSerializable as AckGeneratedJson;
    expect(generated.config.includeIfNull, isFalse);
    expect(
      identical(AckInfer.jsonSerializable, const AckGeneratedJson()),
      isTrue,
    );
  });
}
