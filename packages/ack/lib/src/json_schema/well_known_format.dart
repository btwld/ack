library;

enum WellKnownFormat {
  email('email'),
  uri('uri'),
  uuid('uuid'),
  date('date'),
  dateTime('date-time'),
  ipv4('ipv4'),
  ipv6('ipv6');

  const WellKnownFormat(this.value);
  final String value;

  static WellKnownFormat? fromValue(String? raw) {
    if (raw == null) return null;
    for (final candidate in WellKnownFormat.values) {
      if (candidate.value == raw) return candidate;
    }
    return null;
  }
}
