import 'dart:convert';
import 'dart:io';

import 'package:ack/ack.dart';
import 'package:path/path.dart' as p;
import 'package:punycoder/punycoder.dart' as punycoder;
import 'package:test/test.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

void main() {
  for (final format in ['idn-hostname', 'idn-email', 'hostname', 'email']) {
    for (final operation in ['parse', 'encode']) {
      test('$format enforces Unicode Bidi rules during $operation', () {
        final schema = Ack.fromJsonSchema({
          'type': 'string',
          'format': format,
        }, assertFormats: true);
        final restored = Ack.fromJsonSchema(schema.toJsonSchema());
        final international = format.startsWith('idn-');
        final email = format.endsWith('email');
        for (final example in [
          // RTL labels cannot contain any L character (rule 2).
          (domain: '\u05d0\u03b1.example', valid: false),
          (domain: '\u05d0\u0430.example', valid: false),
          (domain: '\u05d0中.example', valid: false),
          (domain: '\u05d0\u{10428}.example', valid: false),
          (domain: '\u{1e922}\u03b1.example', valid: false),
          (domain: '\u05d0\u0903.example', valid: false),
          // LTR labels cannot contain R/AL or AN characters (rule 5).
          (domain: '\u03b1\u05d0.example', valid: false),
          (domain: '\u03b1\u0660.\u05d0', valid: false),
          // Each label in a Bidi domain must start with L, R or AL (rule 1).
          (domain: '1\u03b1.\u05d0', valid: false),
          (domain: '\u0660\u0661.example', valid: false),
          // Endings ignore trailing NSMs, but cannot be ON (rules 3 and 6).
          (domain: '\u05d0\u02b9.example', valid: false),
          (domain: '\u05d0\u02b9\u0301.example', valid: false),
          (domain: '\u03b1\u02b9.\u05d0', valid: false),
          // RTL labels cannot mix EN and AN digits (rule 4).
          (domain: '\u05d00\u0660.example', valid: false),
          (domain: '\u05d0\u06f0\u0660.example', valid: false),
          (domain: '\u05d0\u05d1.example', valid: true),
          (domain: '\u{1e922}\u{1e923}.example', valid: true),
          (domain: '\u05d0\u05b0.example', valid: true),
          (domain: '\u05d01\u05b0.example', valid: true),
          (domain: '\u05d0\u0660.example', valid: true),
          // Extended Arabic-Indic digits have class EN, like ASCII digits.
          (domain: '\u05d00\u06f0.example', valid: true),
          (domain: '\u03b1.\u05d0', valid: true),
          (domain: '中.\u05d0', valid: true),
          (domain: '\u03b1\u0301.\u05d0', valid: true),
          (domain: '123.example', valid: true),
        ]) {
          final asciiDomain = example.domain
              .split('.')
              .map((label) {
                return label.runes.every((rune) => rune < 128)
                    ? label
                    : 'xn--${punycoder.punycode.encode(unorm.nfkc(label))}';
              })
              .join('.');
          for (final domain in [
            if (international) example.domain,
            asciiDomain,
          ]) {
            final value = email ? 'user@$domain' : domain;
            for (final candidate in [schema, restored]) {
              final result = operation == 'parse'
                  ? candidate.safeParse(value)
                  : candidate.safeEncode(value);
              expect(result.isOk, example.valid, reason: value);
            }
          }
        }
      });
    }
  }

  test('ASCII hostname labels follow RFC 1123', () {
    for (final format in ['hostname', 'idn-hostname']) {
      final schema = Ack.fromJsonSchema({
        'type': 'string',
        'format': format,
      }, assertFormats: true);
      final roundTrip = Ack.fromJsonSchema(schema.toJsonSchema());
      for (final hostname in ['ab--cd.example', 'AB--CD.EXAMPLE']) {
        expect(schema.safeParse(hostname).isOk, isTrue, reason: format);
        expect(roundTrip.safeParse(hostname).isOk, isTrue, reason: format);
      }
      for (final hostname in [
        '-host.example',
        'host-.example',
        'a_b.example',
      ]) {
        expect(schema.safeParse(hostname).isFail, isTrue, reason: format);
        expect(roundTrip.safeParse(hostname).isFail, isTrue, reason: format);
      }
    }
  });

  test('relative JSON pointers allow line terminators in tokens', () {
    final schema = Ack.fromJsonSchema({
      'type': 'string',
      'format': 'relative-json-pointer',
    }, assertFormats: true);
    final roundTrip = Ack.fromJsonSchema(schema.toJsonSchema());
    for (final token in [
      'foo\nbar',
      'foo\rbar',
      'foo\r\nbar',
      'foo\u2028bar',
    ]) {
      final pointer = '0/$token';
      expect(schema.safeParse(pointer).isOk, isTrue, reason: pointer);
      expect(roundTrip.safeParse(pointer).isOk, isTrue, reason: pointer);
    }
    for (final pointer in ['01/foo\nbar', '0/foo\n~2bar', '0\n#']) {
      expect(schema.safeParse(pointer).isFail, isTrue, reason: pointer);
      expect(roundTrip.safeParse(pointer).isFail, isTrue, reason: pointer);
    }
  });

  const root = 'test/fixtures/json_schema_2020_12_full/draft2020-12';
  final formatDirectory = Directory('$root/optional/format');

  group('official 2020-12 optional format assertion', () {
    for (final file in formatDirectory.listSync().whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      final filename = p.basename(file.path);
      final groups = (jsonDecode(file.readAsStringSync()) as List)
          .cast<Map<String, Object?>>();
      for (final group in groups) {
        test('$filename: ${group['description']}', () {
          if (filename == 'unknown.json') {
            expect(
              () => Ack.fromJsonSchema(group['schema']!, assertFormats: true),
              throwsA(isA<JsonSchemaImportException>()),
            );
            return;
          }
          final schema = Ack.fromJsonSchema(
            group['schema']!,
            assertFormats: true,
          );
          final roundTrip = Ack.fromJsonSchema(schema.toJsonSchema());
          final mismatches = <String>[];
          for (final example in group['tests']! as List) {
            final testCase = example as Map<String, Object?>;
            final actual = schema.safeParse(testCase['data']).isOk;
            if (actual != testCase['valid']) {
              mismatches.add(
                '${testCase['description']}: expected ${testCase['valid']}, got $actual',
              );
            }
            final exported = roundTrip.safeParse(testCase['data']).isOk;
            if (exported != testCase['valid']) {
              mismatches.add(
                'export: ${testCase['description']}: expected ${testCase['valid']}, got $exported',
              );
            }
          }
          expect(mismatches, isEmpty);
        });
      }
    }
  });

  group('official 2020-12 format-assertion vocabulary', () {
    final groups =
        (jsonDecode(
                  File(
                    '$root/optional/format-assertion.json',
                  ).readAsStringSync(),
                )
                as List)
            .cast<Map<String, Object?>>();
    final documents = <Uri, Object>{
      for (final value in ['true', 'false'])
        Uri.parse(
          'http://localhost:1234/draft2020-12/format-assertion-$value.json',
        ): jsonDecode(
          File(
            '$root/../remotes/draft2020-12/format-assertion-$value.json',
          ).readAsStringSync(),
        )!,
    };
    for (final group in groups) {
      test(group['description']! as String, () {
        final schema = Ack.fromJsonSchema(
          group['schema']!,
          documents: documents,
        );
        final roundTrip = Ack.fromJsonSchema(schema.toJsonSchema());
        for (final example in group['tests']! as List) {
          final testCase = example as Map<String, Object?>;
          expect(
            schema.safeParse(testCase['data']).isOk,
            testCase['valid'],
            reason: testCase['description'] as String,
          );
          expect(
            roundTrip.safeParse(testCase['data']).isOk,
            testCase['valid'],
            reason: 'export: ${testCase['description']}',
          );
        }
      });
    }
  });
}
