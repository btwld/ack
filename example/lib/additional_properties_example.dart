/// This file demonstrates immutable additional-property storage
/// for schemas with additionalProperties enabled via passthrough()
library;

import 'package:ack/ack.dart';

part 'additional_properties_example.ack.dart';
part 'additional_properties_example.ack.g.dart';

/// Example 1: User configuration with additional metadata
/// The generated model has `additionalProperties`, which contains
/// only the additional properties (not 'username' or 'email')
@Schemable()
final userConfigSchema = Ack.object({
  'username': Ack.string(),
  'email': Ack.string(),
}).passthrough();

/// Example 2: API request with explicit additionalProperties
/// Same behavior as passthrough().
@Schemable()
final apiRequestSchema = Ack.object({
  'method': Ack.string(),
  'url': Ack.string(),
}, additionalProperties: true);

/// Example 3: Feature flags with base configuration
/// Demonstrates filtering out known fields from dynamic properties
@Schemable()
final featureFlagsSchema = Ack.object({
  'appVersion': Ack.string(),
  'environment': Ack.string(),
}).passthrough();

/// Example 4: Empty schema with all properties as additional
@Schemable()
final dynamicDataSchema = Ack.object({}).passthrough();
