/// Information about a property constraint
class PropertyConstraintInfo {
  final String constraintKey;
  final Map<String, Object?> parameters;

  const PropertyConstraintInfo({
    required this.constraintKey,
    required this.parameters,
  });

  @override
  String toString() => 'PropertyConstraintInfo($constraintKey: $parameters)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyConstraintInfo &&
          runtimeType == other.runtimeType &&
          constraintKey == other.constraintKey &&
          _mapEquals(parameters, other.parameters);

  @override
  int get hashCode => constraintKey.hashCode ^ parameters.hashCode;

  bool _mapEquals(Map<String, Object?> a, Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Required constraint implementation
class RequiredConstraint extends PropertyConstraintInfo {
  RequiredConstraint() : super(constraintKey: 'required', parameters: {});
}

/// Nullable constraint implementation
class NullableConstraint extends PropertyConstraintInfo {
  NullableConstraint() : super(constraintKey: 'nullable', parameters: {});
}
