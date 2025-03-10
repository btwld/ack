import '../helpers.dart';
import 'schema_error.dart';

class AckViolationException implements Exception {
  final SchemaError error;

  const AckViolationException(this.error);

  Map<String, dynamic> toMap() {
    return {'error': error.toMap()};
  }

  String toJson() => prettyJson(toMap());

  @override
  String toString() {
    return 'AckViolationException: ${toJson()}';
  }
}
