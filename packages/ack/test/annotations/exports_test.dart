import 'package:ack/ack.dart';
import 'package:ack/annotations.dart' as ack;
import 'package:test/test.dart';

import 'own_types.dart';

@ack.Schemable(caseStyle: ack.AckCaseStyle.snake)
final class Contact {
  const Contact(this.email);

  /// @description Primary email
  @ack.AckKey('email_address')
  @ack.IsEmail()
  final Email email;
}

@Schemable()
final class SingleImportContact {
  const SingleImportContact(this.email, this.id);

  /// @description Contact email
  @AckKey('email')
  @IsEmail()
  final Email email;

  @IsUuid()
  final Uuid id;
}

void main() {
  test('package:ack/ack.dart exports the model and rule annotations', () {
    const values = <Object>[
      Schemable(caseStyle: AckCaseStyle.snake),
      AckKey('id'),
      IsOptional(),
      IsRequired(),
      IsNotNull(),
      HasMin(0),
      HasMax(10),
      IsMultipleOf(2),
      IsPositive(),
      IsNegative(),
      HasMinLength(2),
      HasMaxLength(20),
      HasMatch(r'^\d+$'),
      IsNotEmpty(),
      IsEmail(),
      IsUrl(),
      IsUri(),
      IsUuid(),
      IsDate(),
      IsDateTime(),
      IsIp(version: 4),
      HasMinItems(1),
      HasMaxItems(5),
      HasUniqueItems(),
      ack.IsUuid(),
    ];

    expect(values, hasLength(25));
    expect(values.skip(2), everyElement(isA<ack.AckRule>()));
    expect(AckUnknownPropertyPolicy.values, hasLength(3));
  });

  test(
    'constraint names from package:ack/ack.dart and annotations.dart leave room for app types',
    () {
      const uuid = Uuid('7c9e6679');
      const email = Email('ada@example.com');
      const url = Url('https://example.com');
      const date = Date('2026-10-01');
      const min = Min(1);
      const max = Max(10);
      const pattern = Pattern('^a');
      const required = Required('wire');
      const optional = Optional(null);
      const contact = SingleImportContact(email, uuid);

      expect(
        [
          uuid.value,
          email.address,
          url.href,
          date.iso,
          min.value,
          max.value,
          pattern.source,
          required.reason,
          optional.value,
          contact.email.address,
          contact.id.value,
        ],
        [
          '7c9e6679',
          'ada@example.com',
          'https://example.com',
          '2026-10-01',
          1,
          10,
          '^a',
          'wire',
          null,
          'ada@example.com',
          '7c9e6679',
        ],
      );
    },
  );

  test(
    'a prefixed annotations import exposes Schemable, AckKey, and the rules',
    () {
      const contact = Contact(Email('ada@example.com'));
      const schemable = ack.Schemable(name: 'Contact');
      const key = ack.AckKey('email_address');
      const rules = <ack.AckRule>[
        ack.IsOptional(),
        ack.IsRequired(),
        ack.IsNotNull(),
        ack.HasMin(0),
        ack.HasMax(10),
        ack.IsMultipleOf(2),
        ack.IsPositive(),
        ack.IsNegative(),
        ack.HasMinLength(2),
        ack.HasMaxLength(20),
        ack.HasMatch('^a'),
        ack.IsNotEmpty(),
        ack.IsEmail(),
        ack.IsUrl(),
        ack.IsUri(),
        ack.IsUuid(),
        ack.IsDate(),
        ack.IsDateTime(),
        ack.IsIp(),
        ack.HasMinItems(1),
        ack.HasMaxItems(5),
        ack.HasUniqueItems(),
      ];

      expect(contact.email.address, 'ada@example.com');
      expect(schemable.name, 'Contact');
      expect(key.name, 'email_address');
      expect(rules, hasLength(22));
      expect((rules[10] as ack.HasMatch).pattern, '^a');
    },
  );
}
