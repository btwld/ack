/// MCP tool schemas and argument validation powered by ACK.
library;

import 'dart:async';

import 'package:ack/ack.dart';
import 'package:mcp_dart/mcp_dart.dart';

/// Exports ACK object contracts as MCP tool input schemas.
extension AckMcpToolInputSchema on AckSchema<Object, Object> {
  /// Renders with [toJsonSchema] and preserves its keywords in a [JsonObject].
  ///
  /// Throws [ArgumentError] unless the rendered root has `type: object`.
  /// Composition roots (`anyOf` or `oneOf`), including nullable and
  /// discriminated roots, cannot be advertised. Primitive and list roots
  /// are also rejected.
  ToolInputSchema toMcpToolInputSchema() {
    final json = toJsonSchema();
    if (json['type'] != 'object') {
      final shape = json.containsKey('anyOf')
          ? 'anyOf (nullable or union root)'
          : json.containsKey('oneOf')
          ? 'oneOf (discriminated root)'
          : json['type'] ?? json.keys.join(', ');
      throw ArgumentError(
        'MCP tool input must render as type: object; root renders as $shape.',
      );
    }
    return JsonObject.fromJson(json);
  }
}

/// Parses MCP wire arguments, applying ACK defaults, codecs and refinements.
SchemaResult<R> parseMcpToolArguments<R extends Object>(
  AckSchema<JsonMap, R> schema,
  Map<String, dynamic> args, {
  String? debugName,
}) => schema.safeParse(args, debugName: debugName);

/// Describes validation leaves as JSON Pointer `path: message` lines.
///
/// Nested errors are unwrapped recursively. Empty nested errors retain their
/// own message. Cause-backed messages are replaced with a generic message
/// because ACK may include exception details in them. Other messages are
/// preserved verbatim and should themselves avoid including sensitive data.
List<String> describeAckValidationError(SchemaError error) {
  if (error is SchemaNestedError && error.errors.isNotEmpty) {
    return error.errors.expand(describeAckValidationError).toList();
  }
  // ACK can embed exception text (and its input) in a cause-backed message.
  final message = error.cause == null
      ? error.message
      : 'Argument validation failed.';
  return ['${error.path}: $message'];
}

/// Returns a tool error containing only leaf validation paths and messages.
CallToolResult ackValidationErrorToCallToolResult(
  SchemaError error, {
  required String toolName,
}) => CallToolResult(
  isError: true,
  content: [
    TextContent(
      text:
          "Invalid arguments for tool '$toolName':\n"
          '${describeAckValidationError(error).join('\n')}',
    ),
  ],
);

/// A tool callback receiving validated ACK runtime arguments and MCP context.
typedef AckToolFunction<R> = FutureOr<CallToolResult> Function(
  R args,
  RequestHandlerExtra extra,
);

/// Registers MCP tools whose input contracts and parsing are owned by ACK.
extension AckMcpServer on McpServer {
  /// Advertises [input] and parses arguments before invoking [callback].
  ///
  /// Invalid ACK arguments return a tool error, or [onInvalidArguments]' result,
  /// without invoking [callback]. MCP's own schema validation runs first and
  /// its failures do not reach [onInvalidArguments]. A non-object rendered root
  /// throws [ArgumentError] synchronously at registration.
  RegisteredTool registerAckTool<R extends Object>(
    String name, {
    required AckSchema<JsonMap, R> input,
    required AckToolFunction<R> callback,
    String? title,
    String? description,
    ToolAnnotations? annotations,
    Map<String, dynamic>? meta,
    CallToolResult Function(SchemaError error)? onInvalidArguments,
  }) {
    final inputSchema = input.toMcpToolInputSchema();
    return registerTool(
      name,
      inputSchema: inputSchema,
      title: title,
      description: description,
      annotations: annotations,
      meta: meta,
      callback: (args, extra) {
        final result = parseMcpToolArguments(input, args, debugName: name);
        if (result case Ok<R>(value: final value?)) {
          return callback(value, extra);
        }
        final error = switch (result) {
          Fail<R>(:final error) => error,
          Ok<R>() => SchemaValidationError(
            message: 'Tool arguments must parse to a non-null object.',
            context: SchemaContext(name: name, schema: input, value: args),
          ),
        };
        return onInvalidArguments != null
            ? onInvalidArguments(error)
            : ackValidationErrorToCallToolResult(error, toolName: name);
      },
    );
  }
}
