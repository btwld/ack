// ignore: deprecated_member_use
import 'package:ack/annotations.dart' show AckModel, Schemable;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:json_serializable/type_helper.dart';
import 'package:source_gen/source_gen.dart';

import 'helper_names.dart';

/// Routes every stored Ack field through generated runtime bridge methods.
///
/// The input is an already-validated Ack runtime value, so this helper must
/// claim scalars as well as nested models. Default json_serializable codecs
/// would otherwise decode DateTime, Uri, enums, or nested JSON a second time.
final class AckRuntimeTypeHelper extends TypeHelper<TypeHelperContext> {
  const AckRuntimeTypeHelper();

  // ignore: deprecated_member_use
  static const _model = TypeChecker.typeNamed(AckModel, inPackage: 'ack');
  static const _schemable = TypeChecker.typeNamed(Schemable, inPackage: 'ack');

  @override
  Object? serialize(
    DartType targetType,
    String expression,
    TypeHelperContext context,
  ) {
    final className = context.classElement.name!;
    final fieldName = context.fieldElement.name!;
    final helper = _isClassFirst(context.classElement)
        ? ackClassToRuntimeBridgeName(className, fieldName)
        : '$className.${ackToRuntimeBridgeName(fieldName)}';
    return '$helper($expression)';
  }

  @override
  Object? deserialize(
    DartType targetType,
    String expression,
    TypeHelperContext context,
    bool defaultProvided,
  ) {
    final className = context.classElement.name!;
    final fieldName = context.fieldElement.name!;
    final helper = _isClassFirst(context.classElement)
        ? ackClassFromRuntimeBridgeName(className, fieldName)
        : '$className.${ackFromRuntimeBridgeName(fieldName)}';
    return '$helper($expression)';
  }

  bool _isClassFirst(ClassElement element) =>
      _model.hasAnnotationOfExact(element) ||
      _schemable.hasAnnotationOfExact(element) ||
      element.allSupertypes.any(
        (type) =>
            _model.hasAnnotationOfExact(type.element) ||
            _schemable.hasAnnotationOfExact(type.element),
      );
}
