/// Application types whose names match Ack's constraint annotations.
library;

final class Uuid {
  const Uuid(this.value);
  final String value;
}

final class Email {
  const Email(this.address);
  final String address;
}

final class Url {
  const Url(this.href);
  final String href;
}

final class Date {
  const Date(this.iso);
  final String iso;
}

final class Min {
  const Min(this.value);
  final int value;
}

final class Pattern {
  const Pattern(this.source);
  final String source;
}
