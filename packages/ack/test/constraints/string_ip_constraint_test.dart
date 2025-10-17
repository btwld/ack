import 'package:ack/ack.dart';
import 'package:ack/src/constraints/string_ip_constraint.dart';
import 'package:test/test.dart';

void main() {
  group('StringIpConstraint', () {
    group('IPv4', () {
      final ipv4Constraint = const StringIpConstraint(version: 4);

      test('accepts valid IPv4 addresses', () {
        expect(ipv4Constraint.isValid('0.0.0.0'), isTrue);
        expect(ipv4Constraint.isValid('127.0.0.1'), isTrue);
        expect(ipv4Constraint.isValid('192.168.0.1'), isTrue);
        expect(ipv4Constraint.isValid('255.255.255.255'), isTrue);
        expect(ipv4Constraint.isValid('8.8.8.8'), isTrue);
        expect(ipv4Constraint.isValid('1.2.3.4'), isTrue);
      });

      test('rejects invalid IPv4 addresses - out of range', () {
        expect(ipv4Constraint.isValid('256.1.1.1'), isFalse);
        expect(ipv4Constraint.isValid('1.256.1.1'), isFalse);
        expect(ipv4Constraint.isValid('1.1.256.1'), isFalse);
        expect(ipv4Constraint.isValid('1.1.1.256'), isFalse);
        expect(ipv4Constraint.isValid('999.999.999.999'), isFalse);
      });

      test('rejects invalid IPv4 addresses - malformed', () {
        expect(ipv4Constraint.isValid('1.1.1'), isFalse);
        expect(ipv4Constraint.isValid('1.1.1.1.1'), isFalse);
        expect(ipv4Constraint.isValid(''), isFalse);
        expect(ipv4Constraint.isValid('abc.def.ghi.jkl'), isFalse);
        expect(ipv4Constraint.isValid('1.1.1.'), isFalse);
        expect(ipv4Constraint.isValid('.1.1.1'), isFalse);
      });

      test('rejects IPv6 addresses when version is 4', () {
        expect(
          ipv4Constraint.isValid('2001:0db8:85a3:0000:0000:8a2e:0370:7334'),
          isFalse,
        );
        expect(ipv4Constraint.isValid('::1'), isFalse);
      });

      test('builds correct error message', () {
        final message = ipv4Constraint.buildMessage('invalid');
        expect(message, contains('IPv4'));
        expect(message, contains('invalid'));
      });
    });

    group('IPv6', () {
      final ipv6Constraint = const StringIpConstraint(version: 6);

      test('accepts valid IPv6 addresses - full form', () {
        expect(
          ipv6Constraint.isValid('2001:0db8:85a3:0000:0000:8a2e:0370:7334'),
          isTrue,
        );
        expect(
          ipv6Constraint.isValid('2001:db8:85a3:0:0:8a2e:370:7334'),
          isTrue,
        );
        expect(
          ipv6Constraint.isValid('fe80:0000:0000:0000:0204:61ff:fe9d:f156'),
          isTrue,
        );
      });

      test('accepts valid IPv6 addresses - compressed form', () {
        expect(ipv6Constraint.isValid('::1'), isTrue); // loopback
        expect(ipv6Constraint.isValid('::'), isTrue); // all zeros
        expect(ipv6Constraint.isValid('2001:db8::8a2e:370:7334'), isTrue);
        expect(
          ipv6Constraint.isValid('::ffff:192.0.2.1'),
          isTrue,
        ); // IPv4-mapped
      });

      test('accepts valid IPv6 addresses - link-local', () {
        expect(ipv6Constraint.isValid('fe80::1'), isTrue);
        expect(ipv6Constraint.isValid('fe80::204:61ff:fe9d:f156'), isTrue);
      });

      test('rejects invalid IPv6 addresses', () {
        expect(ipv6Constraint.isValid(''), isFalse);
        expect(ipv6Constraint.isValid('not an ipv6'), isFalse);
        expect(ipv6Constraint.isValid('192.168.1.1'), isFalse); // IPv4
      });

      test('rejects IPv4 addresses when version is 6', () {
        expect(ipv6Constraint.isValid('192.168.0.1'), isFalse);
        expect(ipv6Constraint.isValid('127.0.0.1'), isFalse);
      });

      test('builds correct error message', () {
        final message = ipv6Constraint.buildMessage('invalid');
        expect(message, contains('IPv6'));
        expect(message, contains('invalid'));
      });
    });

    group('Any version (IPv4 or IPv6)', () {
      final anyIpConstraint = const StringIpConstraint();

      test('accepts valid IPv4 addresses', () {
        expect(anyIpConstraint.isValid('192.168.0.1'), isTrue);
        expect(anyIpConstraint.isValid('127.0.0.1'), isTrue);
      });

      test('accepts valid IPv6 addresses', () {
        expect(anyIpConstraint.isValid('::1'), isTrue);
        expect(anyIpConstraint.isValid('2001:db8::8a2e:370:7334'), isTrue);
      });

      test('rejects invalid IP addresses', () {
        expect(anyIpConstraint.isValid(''), isFalse);
        expect(anyIpConstraint.isValid('not an ip'), isFalse);
        expect(anyIpConstraint.isValid('256.256.256.256'), isFalse);
      });

      test('builds correct error message without version', () {
        final message = anyIpConstraint.buildMessage('invalid');
        expect(message, contains('IP address'));
        expect(message, contains('invalid'));
        expect(message.contains('IPv4') || message.contains('IPv6'), isFalse);
      });
    });

    group('JSON Schema', () {
      test('generates correct schema for IPv4', () {
        final schema = const StringIpConstraint(version: 4).toJsonSchema();
        expect(schema, {'format': 'ipv4'});
      });

      test('generates correct schema for IPv6', () {
        final schema = const StringIpConstraint(version: 6).toJsonSchema();
        expect(schema, {'format': 'ipv6'});
      });

      test('generates correct schema for any version', () {
        final schema = const StringIpConstraint().toJsonSchema();
        expect(schema, {
          'oneOf': [
            {'format': 'ipv4'},
            {'format': 'ipv6'},
          ],
        });
      });
    });

    group('Integration with StringSchema', () {
      test('validates IPv4 addresses via string schema', () {
        final ipSchema = Ack.string().ip(version: 4);

        final validResult = ipSchema.safeParse('192.168.1.1');
        expect(validResult.isOk, isTrue);
        expect(validResult.getOrNull(), '192.168.1.1');

        final invalidResult = ipSchema.safeParse('999.999.999.999');
        expect(invalidResult.isOk, isFalse);
      });

      test('validates IPv6 addresses via string schema', () {
        final ipSchema = Ack.string().ip(version: 6);

        final validResult = ipSchema.safeParse('::1');
        expect(validResult.isOk, isTrue);
        expect(validResult.getOrNull(), '::1');

        final invalidResult = ipSchema.safeParse('192.168.1.1');
        expect(invalidResult.isOk, isFalse);
      });

      test('validates any IP address via string schema', () {
        final ipSchema = Ack.string().ip();

        expect(ipSchema.safeParse('192.168.1.1').isOk, isTrue);
        expect(ipSchema.safeParse('::1').isOk, isTrue);
        expect(ipSchema.safeParse('invalid').isOk, isFalse);
      });
    });
  });
}
