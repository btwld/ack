part of '../ack.dart';

class AckException implements Exception {
  final List<SchemaError> errors;
  final StackTrace? stackTrace;

  const AckException(this.errors, {this.stackTrace});

  Map<String, dynamic> toMap() {
    return {'errors': errors.map((e) => e.toMap()).toList()};
  }

  String toJson() => prettyJson(toMap());

  @override
  String toString() {
    return 'AckException: ${toJson()}';
  }
}
