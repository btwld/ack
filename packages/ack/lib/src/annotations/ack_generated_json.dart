import 'package:json_annotation/json_annotation.dart';

/// Generator-support marker applied to Ack-generated model classes.
///
/// This is not part of the user-facing annotation API. `ack_generator` emits
/// [AckInfer.jsonSerializable] so the internal JSON builder can delegate
/// structural mapping to `json_serializable` without a literal
/// `@JsonSerializable` annotation that the ordinary builder would also claim.
///
/// The marker must hold a real [JsonSerializable] constant because
/// `JsonSerializableGenerator.generateForAnnotatedElement` → `mergeConfig`
/// reads annotation fields via `ConstantReader`, and source_gen's null reader
/// throws `UnsupportedError`. That is why `json_annotation` is a runtime
/// dependency of this package.
final class AckGeneratedJson {
  /// Creates the internal JSON-mapping marker.
  const AckGeneratedJson({
    this.config = const JsonSerializable(includeIfNull: false),
  });

  /// Fixed `json_serializable` configuration owned by Ack.
  ///
  /// `includeIfNull` is always `false` so optional null fields stay absent.
  /// Required nullable keys are restored by generated Ack glue.
  final JsonSerializable config;
}
