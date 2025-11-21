library;

enum WellKnownFormat {
  email,
  uri,
  uuid,
  date,
  dateTime,
  ipv4,
  ipv6,
}

extension WellKnownFormatExt on WellKnownFormat {
  String toJson() => switch (this) {
        WellKnownFormat.email => 'email',
        WellKnownFormat.uri => 'uri',
        WellKnownFormat.uuid => 'uuid',
        WellKnownFormat.date => 'date',
        WellKnownFormat.dateTime => 'date-time',
        WellKnownFormat.ipv4 => 'ipv4',
        WellKnownFormat.ipv6 => 'ipv6',
      };
}
