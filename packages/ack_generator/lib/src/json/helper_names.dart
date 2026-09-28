/// Pascal-case first letter used by per-field Ack runtime bridges.
String ackBridgePascal(String fieldName) {
  if (fieldName.isEmpty) return fieldName;
  return '${fieldName[0].toUpperCase()}${fieldName.substring(1)}';
}

/// Decode-side runtime bridge for a stored field.
String ackFromRuntimeBridgeName(String fieldName) =>
    '_ackFromRuntime${ackBridgePascal(fieldName)}';

/// Encode-side runtime bridge for a stored field.
String ackToRuntimeBridgeName(String fieldName) =>
    '_ackToRuntime${ackBridgePascal(fieldName)}';

/// Decode-side top-level bridge for a class-first stored field.
String ackClassFromRuntimeBridgeName(String className, String fieldName) =>
    '_ack${className}FromRuntime${ackBridgePascal(fieldName)}';

/// Encode-side top-level bridge for a class-first stored field.
String ackClassToRuntimeBridgeName(String className, String fieldName) =>
    '_ack${className}ToRuntime${ackBridgePascal(fieldName)}';

/// Runtime-map decoder for a hand-written class-first model.
String ackClassFromRuntimeName(String className) =>
    '_\$${className}FromRuntime';

/// Runtime-map encoder for a hand-written class-first model.
String ackClassToRuntimeName(String className) => '_\$${className}ToRuntime';

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

/// Model class generated for an `@AckInfer` declaration.
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

/// json_serializable `fromJson` helper for a generated model class.
String jsonFromHelperName(String className) => '_\$${className}FromJson';

/// json_serializable `toJson` helper for a generated model class.
String jsonToHelperName(String className) => '_\$${className}ToJson';

/// All per-field bridges derived from [fieldName].
Iterable<String> ackFieldBridgeNames(String fieldName) sync* {
  yield ackFromRuntimeBridgeName(fieldName);
  yield ackToRuntimeBridgeName(fieldName);
}

/// All top-level JSON helpers derived from [className].
Iterable<String> ackJsonHelperNames(String className) sync* {
  yield jsonFromHelperName(className);
  yield jsonToHelperName(className);
}
