part of '../ack_base.dart';

final class ConstraintError extends SchemaError {
  final String name;
  const ConstraintError({
    required this.name,
    required super.message,
    required super.context,
  }) : super(type: 'constraint_$name');
}
