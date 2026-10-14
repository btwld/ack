/// Generated mixin that exposes class-first JSON and value members.
String ackClassMixinName(String className) => '_\$${className}Ack';

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
