import 'package:test/test.dart';
import 'package:ack_generator/src/builders/method_builder.dart';
import 'package:ack_generator/src/models/model_info.dart';
import 'package:ack_generator/src/models/field_info.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:dart_style/dart_style.dart';

void main() {
  group('MethodBuilder', () {
    late MethodBuilder builder;
    late DartFormatter formatter;
    late ModelInfo testModel;

    setUp(() {
      builder = MethodBuilder();
      formatter = DartFormatter();
      testModel = ModelInfo(
        className: 'User',
        schemaClassName: 'UserSchema',
        description: 'Test user model',
        fields: [],
        requiredFields: [],
      );
    });

    test('builds parse method with covariant return type', () {
      final method = builder.buildParseMethod(testModel);
      final code = _methodToString(method);
      
      expect(code, contains('@override'));
      expect(code, contains('UserSchema parse(Object? input)'));
      expect(code, contains('return super.parse(input) as UserSchema;'));
    });

    test('builds tryParse method with nullable covariant return type', () {
      final method = builder.buildTryParseMethod(testModel);
      final code = _methodToString(method);
      
      expect(code, contains('@override'));
      expect(code, contains('UserSchema? tryParse(Object? input)'));
      expect(code, contains('return super.tryParse(input) as UserSchema?;'));
    });

    test('builds createValidated method with protected annotation', () {
      final method = builder.buildCreateValidatedMethod(testModel);
      final code = _methodToString(method);
      
      expect(code, contains('@override'));
      expect(code, contains('@protected'));
      expect(code, contains('UserSchema createValidated(Map<String, Object?> data)'));
      expect(code, contains('return UserSchema._valid(data);'));
    });

    test('method names are correct', () {
      final parseMethod = builder.buildParseMethod(testModel);
      final tryParseMethod = builder.buildTryParseMethod(testModel);
      final createValidatedMethod = builder.buildCreateValidatedMethod(testModel);
      
      expect(parseMethod.name, equals('parse'));
      expect(tryParseMethod.name, equals('tryParse'));
      expect(createValidatedMethod.name, equals('createValidated'));
    });

    test('methods have correct parameter types', () {
      final parseMethod = builder.buildParseMethod(testModel);
      expect(parseMethod.requiredParameters.length, equals(1));
      expect(parseMethod.requiredParameters.first.name, equals('input'));
      
      final createValidatedMethod = builder.buildCreateValidatedMethod(testModel);
      expect(createValidatedMethod.requiredParameters.length, equals(1));
      expect(createValidatedMethod.requiredParameters.first.name, equals('data'));
    });
  });
}

String _methodToString(cb.Method method) {
  final emitter = cb.DartEmitter();
  return method.accept(emitter).toString();
}
