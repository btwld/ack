/// This file demonstrates the automatic `args` getter feature
/// for schemas with additionalProperties enabled via passthrough()
library;

import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'args_getter_example.g.dart';

/// Example 1: User configuration with additional metadata
/// The generated extension type will have an `args` getter that returns
/// only the additional properties (not 'username' or 'email')
@AckType()
final userConfigSchema = Ack.object({
  'username': Ack.string(),
  'email': Ack.string(),
}).passthrough();

/// Example 2: API request with explicit additionalProperties
/// Same behavior as passthrough() - generates args getter
@AckType()
final apiRequestSchema = Ack.object({
  'method': Ack.string(),
  'url': Ack.string(),
}, additionalProperties: true);

/// Example 3: Feature flags with base configuration
/// Demonstrates filtering out known fields from dynamic properties
@AckType()
final featureFlagsSchema = Ack.object({
  'appVersion': Ack.string(),
  'environment': Ack.string(),
}).passthrough();

/// Example 4: Empty schema with all properties as additional
@AckType()
final dynamicDataSchema = Ack.object({}).passthrough();
