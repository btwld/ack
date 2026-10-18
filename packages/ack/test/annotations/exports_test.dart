import 'package:ack/ack.dart';
import 'package:ack/annotations.dart' as ack;
import 'package:test/test.dart';

import 'own_types.dart';

@ack.Schemable(caseStyle: ack.AckCaseStyle.snake)
final class Contact {
  const Contact(this.email);

  /// @description Primary email
  @ack.AckKey('email_address')
  @ack.Validate.email()
  final Email email;
}

@Schemable()
final class SingleImportContact {
  const SingleImportContact(this.email, this.id);

  /// @description Contact email
  @AckKey('email')
  @Validate.email()
  final Email email;

  @Validate.uuid()
  final Uuid id;
}

void main() {
  test('package:ack/ack.dart exports the model and Validate annotations', () {
    const values = <Object>[
      Schemable(caseStyle: AckCaseStyle.snake),
      AckKey('id'),
      Validate.required(),
      Validate.optional(),
      Validate.notNull(),
      Validate.email(),
      Validate.minLength(2),
      Validate.matches(r'^\d+$'),
      ack.Validate.uuid(),
    ];

    expect(values, hasLength(9));
    expect(AckUnknownPropertyPolicy.values, hasLength(3));
  });

  test('constraint names from package:ack/ack.dart and annotations.dart leave room for app types', () {
    const uuid = Uuid('7c9e6679');
    const email = Email('ada@example.com');
    const url = Url('https://example.com');
    const date = Date('2026-10-01');
    const min = Min(1);
    const max = Max(10);
    const pattern = Pattern('^a');
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
        'ada@example.com',
        '7c9e6679',
      ],
    );
  });

  test(
    'a prefixed annotations import exposes Schemable, AckKey, and Validate',
    () {
      const contact = Contact(Email('ada@example.com'));
      const schemable = ack.Schemable(name: 'Contact');
      const key = ack.AckKey('email_address');
      const validate = ack.Validate.matches('^a');

      expect(contact.email.address, 'ada@example.com');
      expect(schemable.name, 'Contact');
      expect(key.name, 'email_address');
      expect(validate, isA<Validate>());
      expect(validate.kind, 'matches');
      expect(validate.value, '^a');
    },
  );
}
