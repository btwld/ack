// ignore_for_file: deprecated_member_use_from_same_package

import 'package:ack/ack.dart';
import 'package:ack/annotations.dart' as ack;
import 'package:test/test.dart';

import 'own_types.dart';

final class Contact {
  const Contact(this.email);

  @ack.Email()
  final Email email;
}

final class SingleImportContact {
  const SingleImportContact(this.email, this.id);

  @Validate.email()
  final Email email;

  @Validate.uuid()
  final Uuid id;
}

void main() {
  test('package:ack/ack.dart exports the model and Validate annotations', () {
    const values = <Object>[
      Schemable(caseStyle: AckCaseStyle.snake),
      AckField(description: 'id'),
      Required(),
      Optional(),
      NotNull(),
      Validate.email(),
      Validate.minLength(2),
      Validate.matches(r'^\d+$'),
      ack.Validate.uuid(),
    ];

    expect(values, hasLength(9));
    expect(AckUnknownPropertyPolicy.values, hasLength(3));
  });

  test(
    'constraint names from package:ack/ack.dart leave room for app types',
    () {
      const uuid = Uuid('7c9e6679');
      const email = Email('ada@example.com');
      const url = Url('https://example.com');
      const date = Date('2026-10-01');
      const min = Min(1);
      const pattern = Pattern('^a');
      const contact = SingleImportContact(email, uuid);

      expect(
        [
          uuid.value,
          email.address,
          url.href,
          date.iso,
          min.value,
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
          '^a',
          'ada@example.com',
          '7c9e6679',
        ],
      );
    },
  );

  test('a prefixed annotations import sits beside a same-named app type', () {
    const contact = Contact(Email('ada@example.com'));

    expect(contact.email.address, 'ada@example.com');
    expect(const ack.Email(), isA<ack.Email>());
  });

  test('Matches annotation exposes pattern', () {
    const annotation = ack.Matches('^a');

    expect(annotation, isA<ack.Matches>());
    expect(annotation.pattern, '^a');
  });
}
