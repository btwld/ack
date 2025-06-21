/// Information about a validation constraint
class ConstraintInfo {
  final String name;
  final List<String> arguments;

  const ConstraintInfo({
    required this.name,
    required this.arguments,
  });
}
