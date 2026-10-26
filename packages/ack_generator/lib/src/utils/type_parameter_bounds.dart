import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
// The public TypeSystem API cannot substitute nested or F-bounded types.
// Keep this analyzer-13-specific dependency here while the package is pinned
// to >=13.0.0 <14.0.0, rather than maintaining a partial type substituter.
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/type_algebra.dart' show Substitution;

/// Substitutes all method type arguments into their parameter bounds.
List<DartType?> instantiateTypeParameterBounds(
  List<TypeParameterElement> parameters,
  List<DartType> arguments,
) {
  final substitution = Substitution.fromPairs2(parameters, arguments);
  return [
    for (final parameter in parameters)
      if (parameter.bound case final bound?)
        substitution.substituteType(bound)
      else
        null,
  ];
}
