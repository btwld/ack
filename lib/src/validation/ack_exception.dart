import '../helpers.dart';
import 'schema_error.dart';

class AckException implements Exception {
  final SchemaError error;

  const AckException(this.error);

  Map<String, dynamic> toMap() {
    return {'error': error.toMap()};
  }

  String toJson() => prettyJson(toMap());

  @override
  String toString() {
    return '$AckException: ${toJson()}';
  }
}
