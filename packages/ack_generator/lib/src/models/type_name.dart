/// Represents a type name with potential generic arguments
class TypeName {
  final String name;
  final List<TypeName> typeArguments;

  const TypeName(this.name, this.typeArguments);

  @override
  String toString() {
    if (typeArguments.isEmpty) return name;
    final args = typeArguments.join(', ');
    return '$name<$args>';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypeName &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          typeArguments.length == other.typeArguments.length &&
          _listEquals(typeArguments, other.typeArguments);

  @override
  int get hashCode => name.hashCode ^ typeArguments.hashCode;

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
