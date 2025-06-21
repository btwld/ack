/// Shared test assets for ack_generator tests
const ackAnnotationsAsset = {
  'ack_annotations|lib/ack_annotations.dart': '''
library ack_annotations;

export 'src/ack_model.dart';
export 'src/ack_field.dart';
''',
  'ack_annotations|lib/src/ack_model.dart': '''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
class AckModel {
  final String? schemaName;
  final String? description;
  
  const AckModel({
    this.schemaName,
    this.description,
  });
}
''',
  'ack_annotations|lib/src/ack_field.dart': '''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.field})
class AckField {
  final bool required;
  final String? jsonKey;
  final List<String> constraints;
  
  const AckField({
    this.required = false,
    this.jsonKey,
    this.constraints = const [],
  });
}
''',
};

const ackPackageAsset = {
  'ack|lib/ack.dart': '''
export 'src/schemas/schema.dart';
export 'src/schemas/schema_model.dart';
export 'src/validation/ack_exception.dart';
export 'src/validation/schema_error.dart';
export 'src/validation/schema_result.dart';
export 'src/ack.dart';
''',
  'ack|lib/src/ack.dart': '''
class Ack {
  static const string = _StringSchema();
  static const integer = _IntegerSchema();
  static const double = _DoubleSchema();
  static const number = _NumberSchema();
  static const boolean = _BooleanSchema();
  static const any = _AnySchema();
  
  static _ListSchema list(dynamic itemSchema) => _ListSchema(itemSchema);
  static _ObjectSchema object(Map<String, dynamic> properties, {List<String>? required}) => 
    _ObjectSchema(properties, required: required);
}

class _StringSchema {
  const _StringSchema();
  _StringSchema email() => this;
  _StringSchema notEmpty() => this;
  _StringSchema minLength(int length) => this;
  _StringSchema maxLength(int length) => this;
  _StringSchema url() => this;
  _StringSchema uuid() => this;
  _StringSchema pattern(String pattern) => this;
  _StringSchema nullable() => this;
}

class _IntegerSchema {
  const _IntegerSchema();
  _IntegerSchema min(int value) => this;
  _IntegerSchema max(int value) => this;
  _IntegerSchema positive() => this;
  _IntegerSchema negative() => this;
  _IntegerSchema nullable() => this;
}

class _DoubleSchema {
  const _DoubleSchema();
  _DoubleSchema min(double value) => this;
  _DoubleSchema max(double value) => this;
  _DoubleSchema positive() => this;
  _DoubleSchema negative() => this;
  _DoubleSchema nullable() => this;
}

class _NumberSchema {
  const _NumberSchema();
  _NumberSchema nullable() => this;
}

class _BooleanSchema {
  const _BooleanSchema();
  _BooleanSchema nullable() => this;
}

class _AnySchema {
  const _AnySchema();
}

class _ListSchema {
  final dynamic itemSchema;
  const _ListSchema(this.itemSchema);
  _ListSchema nullable() => this;
}

class _ObjectSchema {
  final Map<String, dynamic> properties;
  final List<String>? required;
  const _ObjectSchema(this.properties, {this.required});
  _ObjectSchema nullable() => this;
}
''',
  'ack|lib/src/schemas/schema_model.dart': '''
import 'package:meta/meta.dart';

abstract class SchemaModel {
  final Map<String, Object?>? _data;
  
  const SchemaModel() : _data = null;
  
  @protected
  const SchemaModel.validated(Map<String, Object?> data) : _data = data;
  
  ObjectSchema get definition;
  
  bool get hasData => _data != null;
  
  SchemaModel parse(Object? input) {
    // Simplified implementation for testing
    return createValidated(input as Map<String, Object?>);
  }
  
  SchemaModel? tryParse(Object? input) {
    try {
      return parse(input);
    } catch (_) {
      return null;
    }
  }
  
  @protected
  SchemaModel createValidated(Map<String, Object?> data);
  
  @protected
  T getValue<T extends Object>(String key) {
    if (_data == null) {
      throw StateError('No data available - use parse() first');
    }
    final value = _data![key];
    if (value == null) {
      throw StateError('Required field "\$key" is null');
    }
    if (value is! T) {
      throw StateError(
        'Field "\$key" has incorrect type. Expected \$T but got \${value.runtimeType}',
      );
    }
    return value;
  }
  
  @protected
  T? getValueOrNull<T extends Object>(String key) {
    if (_data == null) return null;
    final value = _data![key];
    if (value == null) return null;
    if (value is! T) {
      throw StateError(
        'Field "\$key" has incorrect type. Expected \$T? but got \${value.runtimeType}',
      );
    }
    return value;
  }
  
  Map<String, Object?> toMap() {
    if (_data == null) return const {};
    return Map.unmodifiable(_data!);
  }
}

class ObjectSchema {}
''',
  'ack|lib/src/validation/ack_exception.dart': '''
class AckException implements Exception {
  final String message;
  const AckException(this.message);
  
  @override
  String toString() => 'AckException: \$message';
}
''',
  'ack|lib/src/validation/schema_error.dart': '''
class SchemaError {
  final String message;
  const SchemaError(this.message);
}
''',
  'ack|lib/src/validation/schema_result.dart': '''
class SchemaResult<T> {
  final T? value;
  final SchemaError? error;
  
  const SchemaResult.ok(this.value) : error = null;
  const SchemaResult.error(this.error) : value = null;
  
  bool get isOk => error == null;
  T getOrThrow() => value!;
  SchemaError getError() => error!;
}
''',
};

/// Combines all required assets for testing
Map<String, String> get allTestAssets => {
  ...ackAnnotationsAsset,
  ...ackPackageAsset,
};
