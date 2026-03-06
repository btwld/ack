import 'package:analyzer/dart/element/type.dart';

String typeIdentityKey(DartType type) {
  final baseIdentity = _baseTypeIdentity(type);

  if (type is ParameterizedType && type.typeArguments.isNotEmpty) {
    final typeArguments = type.typeArguments.map(typeIdentityKey).join(',');
    return '$baseIdentity<$typeArguments>';
  }

  return baseIdentity;
}

String _baseTypeIdentity(DartType type) {
  final element = type.element3;
  final libraryUri = element?.library2?.uri.toString();
  final elementName = element?.name3;

  if (libraryUri != null && elementName != null) {
    return '$libraryUri::$elementName';
  }

  return type.getDisplayString(withNullability: false);
}

class TypeProviderInfo {
  final String providerTypeName;
  final DartType targetType;
  final String accessor;

  const TypeProviderInfo({
    required this.providerTypeName,
    required this.targetType,
    required this.accessor,
  });

  String get targetTypeIdentityKey => typeIdentityKey(targetType);

  String get targetTypeName =>
      targetType.getDisplayString(withNullability: false);
}
