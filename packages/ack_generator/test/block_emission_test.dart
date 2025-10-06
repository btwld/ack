import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

/// Test to understand how code_builder emits Block statements
void main() {
  group('Block emission tests', () {
    test('Block with statements using addAll', () {
      final method = Method(
        (m) => m
          ..name = 'parse'
          ..static = true
          ..returns = refer('SimpleUserType')
          ..requiredParameters.add(
            Parameter(
              (p) => p
                ..name = 'data'
                ..type = refer('Object?'),
            ),
          )
          ..body = Block(
            (b) => b.statements.addAll([
              Code('final validated = simpleUserSchema.parse(data);'),
              Code('return SimpleUserType(validated as Map<String, dynamic>);'),
            ]),
          ),
      );

      final emitter = DartEmitter(
        allocator: Allocator.none,
        orderDirectives: true,
        useNullSafetySyntax: true,
      );

      final output = method.accept(emitter).toString();
      print('=== Block with addAll ===');
      print(output);
      print('=== End ===\n');
    });

    test('Block.of with Code statements', () {
      final method = Method(
        (m) => m
          ..name = 'parse'
          ..static = true
          ..returns = refer('SimpleUserType')
          ..requiredParameters.add(
            Parameter(
              (p) => p
                ..name = 'data'
                ..type = refer('Object?'),
            ),
          )
          ..body = Block.of([
            Code('final validated = simpleUserSchema.parse(data);'),
            Code('return SimpleUserType(validated as Map<String, dynamic>);'),
          ]),
      );

      final emitter = DartEmitter(
        allocator: Allocator.none,
        orderDirectives: true,
        useNullSafetySyntax: true,
      );

      final output = method.accept(emitter).toString();
      print('=== Block.of ===');
      print(output);
      print('=== End ===\n');
    });

    test('Multi-line Code string', () {
      final method = Method(
        (m) => m
          ..name = 'parse'
          ..static = true
          ..returns = refer('SimpleUserType')
          ..requiredParameters.add(
            Parameter(
              (p) => p
                ..name = 'data'
                ..type = refer('Object?'),
            ),
          )
          ..body = Code('''
final validated = simpleUserSchema.parse(data);
return SimpleUserType(validated as Map<String, dynamic>);
'''),
      );

      final emitter = DartEmitter(
        allocator: Allocator.none,
        orderDirectives: true,
        useNullSafetySyntax: true,
      );

      final output = method.accept(emitter).toString();
      print('=== Multi-line Code ===');
      print(output);
      print('=== End ===\n');
    });

    test('Code with explicit newlines', () {
      final method = Method(
        (m) => m
          ..name = 'parse'
          ..static = true
          ..returns = refer('SimpleUserType')
          ..requiredParameters.add(
            Parameter(
              (p) => p
                ..name = 'data'
                ..type = refer('Object?'),
            ),
          )
          ..body = Code(
            'final validated = simpleUserSchema.parse(data);\nreturn SimpleUserType(validated as Map<String, dynamic>);',
          ),
      );

      final emitter = DartEmitter(
        allocator: Allocator.none,
        orderDirectives: true,
        useNullSafetySyntax: true,
      );

      final output = method.accept(emitter).toString();
      print('=== Code with \\n ===');
      print(output);
      print('=== End ===\n');
    });
  });
}
