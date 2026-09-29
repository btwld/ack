// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80
// ignore_for_file: type=lint
// coverage:ignore-file
//
// Generated from mapping.schema.json by ack_generator:ack_json_schema.
// unknown_properties: preserve widened these objects:
// - #/$defs/Listing
// - #/$defs/Listing/properties/address

import 'package:ack/ack.dart' as ack;
import 'package:ack_annotations/ack_annotations.dart' as ack_annotations;

@ack_annotations.AckInfer(name: 'ListingAddress')
final listingAddressSchema = ack.Ack.object({
  'city': ack.Ack.string(),
}, additionalProperties: true);

@ack_annotations.AckInfer(name: 'Listing')
final listingSchema = ack.Ack.object({
  'key': ack.Ack.string()
      .minLength(2)
      .maxLength(8)
      .describe('The key, with \'quotes\', \$dollars, and \\backslashes\\.'),
  'code': ack.Ack.string().matches('^[A-Z]{2}-\\d+\$').optional(),
  'rooms': ack.Ack.integer().min(1).max(9),
  'floors': ack.Ack.integer().greaterThan(0).max(4).optional(),
  'price': ack.Ack.number().min(0).lessThan(1000000.5).optional(),
  'active': ack.Ack.boolean(),
  'status': ack.Ack.enumString(['Active', 'Closed']).nullable().optional(),
  'kind': ack.Ack.literal('residential').optional(),
  'tags': ack.Ack.list(
    ack.Ack.string(),
  ).minItems(1).maxItems(3).unique().optional(),
  'notes': ack.Ack.string().nullable().optional(),
  'nickname': ack.Ack.string().nullable().optional(),
  'streetNumber': ack.Ack.any()
      .refine(
        (value) => value is String || value is num,
        message: 'Expected a string or a number.',
      )
      .nullable()
      .optional(),
  'extra': ack.Ack.any().nullable().optional(),
  'labels': ack.Ack.map(ack.Ack.integer()).optional(),
  'meta': ack.Ack.map(ack.Ack.any().nullable()).optional(),
  'address': listingAddressSchema.optional(),
  'photo': photoSchema.optional(),
  'cover': photoSchema.nullable().optional(),
  'photos': ack.Ack.list(photoSchema).optional(),
}, additionalProperties: true).describe('A listing.\nWith a second line.');

@ack_annotations.AckInfer(name: 'Photo')
final photoSchema = ack.Ack.object({
  'url': ack.Ack.string(),
  'width': ack.Ack.integer().optional(),
}, additionalProperties: true);
