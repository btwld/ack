/// Well-known format values as defined in JSON Schema Draft-7 and common extensions.
///
/// JSON Schema allows the `format` keyword to provide semantic information
/// about string values. This enum covers standard formats from JSON Schema
/// and commonly-used extensions.
///
/// See:
/// - https://json-schema.org/draft-07/json-schema-validation.html#rfc.section.7.3
/// - https://json-schema.org/understanding-json-schema/reference/string.html#format
// ignore_for_file: constant_identifier_names
enum WellKnownFormat {
  // ============================================================================
  // String Formats (RFC 3339, RFC 5322, etc.)
  // ============================================================================

  /// Email address format (RFC 5322).
  ///
  /// Example: `user@example.com`
  email,

  /// Internationalized email address (RFC 6531).
  ///
  /// Example: `用户@例え.jp`
  idn_email('idn-email'),

  /// URI format (RFC 3986).
  ///
  /// Example: `https://example.com/path?query=value`
  uri,

  /// URI reference (RFC 3986).
  ///
  /// Example: `/path/to/resource`
  uri_reference('uri-reference'),

  /// URI template (RFC 6570).
  ///
  /// Example: `https://api.example.com/{version}/users/{id}`
  uri_template('uri-template'),

  /// IRI format (RFC 3987).
  ///
  /// Example: `https://例え.jp/パス`
  iri,

  /// IRI reference (RFC 3987).
  iri_reference('iri-reference'),

  /// UUID format (RFC 4122).
  ///
  /// Example: `550e8400-e29b-41d4-a716-446655440000`
  uuid,

  /// Hostname format (RFC 1123).
  ///
  /// Example: `example.com`
  hostname,

  /// Internationalized hostname (RFC 5890).
  ///
  /// Example: `例え.jp`
  idn_hostname('idn-hostname'),

  /// IPv4 address format (RFC 2673).
  ///
  /// Example: `192.168.1.1`
  ipv4,

  /// IPv6 address format (RFC 4291).
  ///
  /// Example: `2001:0db8:85a3:0000:0000:8a2e:0370:7334`
  ipv6,

  // ============================================================================
  // Date and Time Formats (RFC 3339)
  // ============================================================================

  /// Full date format (RFC 3339).
  ///
  /// Format: `YYYY-MM-DD`
  /// Example: `2024-01-15`
  date,

  /// Date-time format (RFC 3339).
  ///
  /// Format: `YYYY-MM-DDTHH:MM:SS.sssZ`
  /// Example: `2024-01-15T14:30:00.000Z`
  date_time('date-time'),

  /// Time format (RFC 3339).
  ///
  /// Format: `HH:MM:SS.sss`
  /// Example: `14:30:00.000`
  time,

  /// Duration format (ISO 8601).
  ///
  /// Example: `P3Y6M4DT12H30M5S` (3 years, 6 months, 4 days, 12 hours, 30 minutes, 5 seconds)
  duration,

  // ============================================================================
  // Numeric Formats
  // ============================================================================

  /// 32-bit integer format.
  ///
  /// Range: -2,147,483,648 to 2,147,483,647
  int32,

  /// 64-bit integer format.
  ///
  /// Range: -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807
  int64,

  /// Single-precision floating-point (32-bit).
  float,

  /// Double-precision floating-point (64-bit).
  double,

  // ============================================================================
  // Other Formats
  // ============================================================================

  /// JSON Pointer format (RFC 6901).
  ///
  /// Example: `/properties/name`
  json_pointer('json-pointer'),

  /// Relative JSON Pointer.
  ///
  /// Example: `0/properties/name`
  relative_json_pointer('relative-json-pointer'),

  /// Regular expression format (ECMA 262).
  ///
  /// Example: `^[A-Za-z]+$`
  regex,

  /// Enum format (special marker for enumerated values).
  ///
  /// Used internally to indicate string enums.
  enum_('enum'),

  // ============================================================================
  // Binary and Encoding Formats
  // ============================================================================

  /// Base64-encoded binary data (RFC 4648).
  ///
  /// Example: `SGVsbG8gV29ybGQ=`
  byte,

  /// Base64-encoded binary data with padding (RFC 4648).
  binary;

  // ============================================================================
  // Implementation
  // ============================================================================

  /// The JSON representation of this format.
  ///
  /// Some formats use hyphens (e.g., `date-time`), while others use
  /// underscores in Dart enum names (e.g., `date_time`).
  final String? _jsonValue;

  const WellKnownFormat([this._jsonValue]);

  /// Converts this format to its JSON Schema string representation.
  ///
  /// Example:
  /// ```dart
  /// WellKnownFormat.email.toJson()     // 'email'
  /// WellKnownFormat.date_time.toJson() // 'date-time'
  /// WellKnownFormat.idn_email.toJson() // 'idn-email'
  /// ```
  String toJson() => _jsonValue ?? name;

  /// Parses a JSON Schema format string to a [WellKnownFormat] enum value.
  ///
  /// Returns `null` if the string doesn't match any known format.
  ///
  /// Example:
  /// ```dart
  /// WellKnownFormat.parse('email')      // WellKnownFormat.email
  /// WellKnownFormat.parse('date-time')  // WellKnownFormat.date_time
  /// WellKnownFormat.parse('custom')     // null (unknown format)
  /// ```
  static WellKnownFormat? parse(String? value) {
    if (value == null) return null;

    // Try exact match first (handles formats without hyphens)
    for (final format in values) {
      if (format.toJson() == value) {
        return format;
      }
    }

    return null;
  }

  /// Returns true if this format is typically used with string types.
  bool get isStringFormat {
    return switch (this) {
      email ||
      idn_email ||
      uri ||
      uri_reference ||
      uri_template ||
      iri ||
      iri_reference ||
      uuid ||
      hostname ||
      idn_hostname ||
      ipv4 ||
      ipv6 ||
      date ||
      date_time ||
      time ||
      duration ||
      json_pointer ||
      relative_json_pointer ||
      regex ||
      enum_ ||
      byte ||
      binary =>
        true,
      int32 || int64 || float || double => false,
    };
  }

  /// Returns true if this format is typically used with numeric types.
  bool get isNumericFormat {
    return switch (this) {
      int32 || int64 || float || double => true,
      _ => false,
    };
  }
}
