/// Provides mock ACK package files for testing
Map<String, String> getMockAckPackage() {
  return {
    'ack|lib/ack.dart': '''
export 'src/annotations.dart';
export 'src/ack.dart';
export 'src/schema_model.dart';
export 'src/schema_registry.dart';
export 'src/json_schema_converter.dart';
export 'src/ack_exception.dart';
''',
    'ack|lib/src/annotations.dart': '''
class Schema {
  final String? description;
  final bool additionalProperties;
  final String? additionalPropertiesField;
  final String? discriminatedKey;
  final String? discriminatedValue;

  const Schema({
    this.description,
    this.additionalProperties = false,
    this.additionalPropertiesField,
    this.discriminatedKey,
    this.discriminatedValue,
  });
}

class IsEmail {
  const IsEmail();
}

class IsNotEmpty {
  const IsNotEmpty();
}

class Required {
  const Required();
}

class MinLength {
  final int length;
  const MinLength(this.length);
}

class Nullable {
  const Nullable();
}
''',
  };
}
