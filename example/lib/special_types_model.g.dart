// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

// // GENERATED CODE - DO NOT MODIFY BY HAND

part of 'special_types_model.dart';

/// Generated schema for Event
final eventSchema = Ack.object({
  'name': Ack.string(),
  'timestamp': Ack.string().datetime(),
  'website': Ack.string().uri(),
  'duration': Ack.integer(),
  'optionalDate': Ack.string().datetime().optional().nullable(),
  'optionalUri': Ack.string().uri().optional().nullable(),
  'optionalDuration': Ack.integer().optional().nullable(),
});

/// Extension type for Event
extension type EventType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static EventType parse(Object? data) {
    final validated = eventSchema.parse(data);
    return EventType(validated as Map<String, Object?>);
  }

  static SchemaResult<EventType> safeParse(Object? data) {
    final result = eventSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(EventType(validated as Map<String, Object?>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get name => _data['name'] as String;

  DateTime get timestamp => DateTime.parse(_data['timestamp'] as String);

  Uri get website => Uri.parse(_data['website'] as String);

  Duration get duration => Duration(milliseconds: _data['duration'] as int);

  DateTime? get optionalDate => _data['optionalDate'] != null
      ? DateTime.parse(_data['optionalDate'] as String)
      : null;

  Uri? get optionalUri => _data['optionalUri'] != null
      ? Uri.parse(_data['optionalUri'] as String)
      : null;

  Duration? get optionalDuration => _data['optionalDuration'] != null
      ? Duration(milliseconds: _data['optionalDuration'] as int)
      : null;

  EventType copyWith({
    String? name,
    DateTime? timestamp,
    Uri? website,
    Duration? duration,
    DateTime? optionalDate,
    Uri? optionalUri,
    Duration? optionalDuration,
  }) {
    return EventType.parse({
      'name': name ?? this.name,
      'timestamp': timestamp ?? this.timestamp,
      'website': website ?? this.website,
      'duration': duration ?? this.duration,
      if (optionalDate != null || _data.containsKey('optionalDate'))
        'optionalDate': optionalDate ?? this.optionalDate,
      if (optionalUri != null || _data.containsKey('optionalUri'))
        'optionalUri': optionalUri ?? this.optionalUri,
      if (optionalDuration != null || _data.containsKey('optionalDuration'))
        'optionalDuration': optionalDuration ?? this.optionalDuration,
    });
  }
}
