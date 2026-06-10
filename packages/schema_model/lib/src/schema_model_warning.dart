import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

@immutable
final class SchemaModelWarning {
  const SchemaModelWarning({
    required this.code,
    required this.message,
    this.path,
    this.context = const {},
  });

  final String code;
  final String message;
  final String? path;
  final Map<String, Object?> context;

  Map<String, Object?> toJson() => {
    'code': code,
    'message': message,
    if (path != null) 'path': path,
    if (context.isNotEmpty) 'context': context,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SchemaModelWarning) return false;
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
