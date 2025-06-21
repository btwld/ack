import 'package:code_builder/code_builder.dart';
import '../models/model_info.dart';

/// Builds methods for schema classes
class MethodBuilder {
  /// Build parse method with covariant return type
  Method buildParseMethod(ModelInfo model) {
    return Method((b) => b
      ..name = 'parse'
      ..annotations.add(const CodeExpression(Code('override')))
      ..returns = refer(model.schemaClassName)
      ..requiredParameters.add(Parameter((p) => p
        ..name = 'input'
        ..type = refer('Object?')
      ))
      ..body = Code('return super.parse(input) as ${model.schemaClassName};')
    );
  }

  /// Build tryParse method with covariant return type
  Method buildTryParseMethod(ModelInfo model) {
    return Method((b) => b
      ..name = 'tryParse'
      ..annotations.add(const CodeExpression(Code('override')))
      ..returns = refer('${model.schemaClassName}?')
      ..requiredParameters.add(Parameter((p) => p
        ..name = 'input'
        ..type = refer('Object?')
      ))
      ..body = Code('return super.tryParse(input) as ${model.schemaClassName}?;')
    );
  }

  /// Build createValidated factory method
  Method buildCreateValidatedMethod(ModelInfo model) {
    return Method((b) => b
      ..name = 'createValidated'
      ..annotations.addAll([
        const CodeExpression(Code('override')),
        const CodeExpression(Code('protected')),
      ])
      ..returns = refer(model.schemaClassName)
      ..requiredParameters.add(Parameter((p) => p
        ..name = 'data'
        ..type = refer('Map<String, Object?>')
      ))
      ..body = Code('return ${model.schemaClassName}._valid(data);')
    );
  }
}
