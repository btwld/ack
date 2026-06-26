import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

@immutable
final class AckSchemaModelWarning {
  /// A default value could not be represented in the exported JSON Schema.
  static const String defaultNotExportSafe = 'default_not_export_safe';

  /// An [InstanceSchema] has a runtime-only JSON boundary that cannot be
  /// rendered as JSON Schema. Matched when deciding whether a codec output is
  /// representable as Standard JSON Schema.
  static const String instanceJsonBoundary = 'ack_instance_json_boundary';

  /// An `Ack.any()` schema has no constrained JSON boundary.
  static const String anyJsonBoundary = 'ack_any_json_boundary';

  /// A [LazySchema]'s runtime checks cannot be export-verified.
  static const String lazyRuntimeChecksNotExportSafe =
      'lazy_runtime_checks_not_export_safe';

  /// A DateTime constraint cannot be expressed in JSON Schema Draft-7.
  static const String datetimeConstraintNotDraft7 =
      'datetime_constraint_not_draft7';

  final String code;

  final String message;
  final String? path;
  final Map<String, Object?> context;
  const AckSchemaModelWarning({
    required this.code,
    required this.message,
    this.path,
    this.context = const {},
  });

  Map<String, Object?> toJson() => {
    'code': code,
    'message': message,
    if (path != null) 'path': path,
    if (context.isNotEmpty) 'context': context,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AckSchemaModelWarning) return false;

    return code == other.code &&
        message == other.message &&
        path == other.path &&
        const MapEquality<String, Object?>().equals(context, other.context);
  }

  @override
  int get hashCode => Object.hash(
    code,
    message,
    path,
    const MapEquality<String, Object?>().hash(context),
  );
}
