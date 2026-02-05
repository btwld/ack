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
