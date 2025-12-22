/// Converts a PascalCase or camelCase string to camelCase.
///
/// Examples:
/// - "UserSchema" → "userSchema"
/// - "CustomUserSchema" → "customUserSchema"
String toCamelCase(String text) {
  if (text.isEmpty) return text;
  return text[0].toLowerCase() + text.substring(1);
}

/// Generates an extension type name from a schema variable name.
///
/// Removes the "Schema" suffix (if present) and capitalizes the first letter.
///
/// Examples:
/// - "userSchema" → "User"
/// - "addressSchema" → "Address"
/// - "myDataSchema" → "MyData"
String generateTypeNameFromVariable(String variableName) {
  var name = variableName;
  if (name.endsWith('Schema')) {
    name = name.substring(0, name.length - 'Schema'.length);
  }
  if (name.isEmpty) return 'Type';
  return name[0].toUpperCase() + name.substring(1);
}
