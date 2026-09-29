import 'package:ack_generator/src/utils/string_literal.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';

String _parsedValue(String literal) {
  final unit = parseString(content: 'const value = $literal;').unit;
  final variable = (unit.declarations.single as TopLevelVariableDeclaration)
      .variables
      .variables
      .single;
  return (variable.initializer! as SimpleStringLiteral).value;
}

void main() {
  test('literals round-trip through the Dart parser', () {
    const values = [
      'plain',
      "quote' slash\\ dollar\$ \${notInterpolation}",
      'first\nsecond\r\nthird',
      '\u0000\t\b\f\u001f\u007f  ',
    ];
    for (final value in values) {
      expect(_parsedValue(dartStringLiteral(value)), value);
    }
  });

  test('line terminators are escaped, not written raw', () {
    expect(dartStringLiteral('a\nb\rc'), r"'a\u000ab\u000dc'");
  });
}
