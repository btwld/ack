// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

// // GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:ack/ack.dart';

/// Generated schema for StatusModel
/// A model demonstrating enum field validation
final statusModelSchema = Ack.object({
  'simpleStatus': Ack.string().enumString(['active', 'inactive', 'pending']),
});
