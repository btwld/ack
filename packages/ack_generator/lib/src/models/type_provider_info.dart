import 'package:analyzer/dart/element/type.dart';

class TypeProviderInfo {
  final String providerTypeName;
  final DartType targetType;
  final String accessor;

  const TypeProviderInfo({
    required this.providerTypeName,
    required this.targetType,
    required this.accessor,
  });

  String get targetTypeName =>
      targetType.getDisplayString(withNullability: false);
}
