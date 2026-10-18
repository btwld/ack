/// Public static facade generated for a class-first schema.
String ackClassSchemaFacadeName(String className, {String? override}) =>
    override ?? '${className}Schema';

/// Private codec backing a class-first schema facade.
String ackClassSchemaBackingName(String className) =>
    '_${className[0].toLowerCase()}${className.substring(1)}Schema';

/// Private boundary-preserving schema backing a class-first facade.
String ackClassWireSchemaName(String className) =>
    '_${className[0].toLowerCase()}${className.substring(1)}WireSchema';

/// Private runtime decoder generated for a class-first object model.
String ackClassFromRuntimeName(String className) =>
    '_\$${className}FromRuntime';

/// Private runtime encoder generated for a class-first object model.
String ackClassToRuntimeName(String className) => '_\$${className}ToRuntime';

/// Model class generated for a `@Schemable` schema declaration.
String ackInferModelClassName(String declarationName, {String? override}) {
  if (override != null) return override;
  final stem = declarationName.endsWith('Schema')
      ? declarationName.substring(0, declarationName.length - 'Schema'.length)
      : declarationName;
  if (stem.isEmpty) return stem;
  return '${stem[0].toUpperCase()}${stem.substring(1)}';
}

/// Private object schema used as a discriminated-union branch.
String ackClassRawObjectName(String className) =>
    '_${className[0].toLowerCase()}${className.substring(1)}Object';

/// Private per-model type used to distinguish an omitted copyWith argument.
String ackCopyWithUnsetTypeName(String className) =>
    '_${className}CopyWithUnset';

/// Public interface that types a generated model's `copyWith` call.
String ackCopyWithInterfaceName(String className) => '\$${className}CopyWith';

/// Private implementation behind a generated model's `copyWith` getter.
String ackCopyWithImplementationName(String className) =>
    '_\$${className}CopyWith';

/// Private facade alias used from a model's scope without member shadowing.
String ackClassSchemaAliasName(String className) => '_\$${className}SchemaApi';

/// Library-scoped value operations, outside user model member scope.
String ackClassEqualsName(String className) => '_\$${className}Equals';
String ackClassHashName(String className) => '_\$${className}HashCode';

/// Types used inside augmentations are private aliases so user fields cannot
/// shadow core type names or the Ack import prefix.
const ackClassScopeTypeNames = {
  '_AckObject',
  '_AckDynamic',
  '_AckString',
  '_AckMap',
  '_AckBool',
  '_AckInt',
  '_AckSchema',
  '_AckSchemaResult',
};
String ackClassCopyWithAliasName(String className) =>
    '_\$${className}CopyWithApi';
