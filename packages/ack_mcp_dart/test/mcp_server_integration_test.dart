import 'dart:async';

import 'package:ack/ack.dart';
import 'package:ack_mcp_dart/ack_mcp_dart.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

CallToolResult textResult(String text) =>
    CallToolResult(content: [TextContent(text: text)]);
String resultText(CallToolResult result) =>
    (result.content.single as TextContent).text;

void main() {
  setUpAll(silenceMcpLogs);
  tearDownAll(resetMcpLogHandler);
  for (final version in [null, '2025-11-25', '2025-06-18']) {
    group(version ?? 'stable discovery (2026-07-28)', () {
      late McpServer server;
      late McpClient client;
      late _TransportPair transports;
      setUp(() {
        server = McpServer(
          const Implementation(name: 'ack-test', version: '1.0.0'),
        );
        client = McpClient(
          const Implementation(name: 'test-client', version: '1.0.0'),
          options: McpClientOptions(protocolVersion: version),
        );
        transports = _TransportPair();
      });
      tearDown(() async {
        await client.close();
        await server.close();
        await transports.close();
      });
      Future<void> connect() async {
        await server.connect(transports.server);
        await client.connect(transports.client);
      }

      test('lists schemas and metadata for schema and model tools', () async {
        server.registerAckTool(
          'search',
          input: searchSchema(),
          title: 'Search',
          description: 'Search documents',
          annotations: const ToolAnnotations(readOnlyHint: true),
          meta: {'app': 'ack'},
          callback: (args, extra) => textResult('ok'),
        );
        server.registerAckTool(
          'model',
          input: SearchInput.schema,
          title: 'Model',
          description: 'Typed search',
          annotations: const ToolAnnotations(readOnlyHint: true),
          meta: {'app': 'model'},
          callback: (args, extra) => textResult(args.query),
        );
        await connect();
        final tools = (await client.listTools()).tools;
        expect(tools, hasLength(2));
        for (final tool in tools) {
          expect(tool.inputSchema.toJson(), searchSchema().toJsonSchema());
          expect(tool.annotations?.readOnlyHint, isTrue);
        }
        final search = tools.singleWhere((tool) => tool.name == 'search');
        final model = tools.singleWhere((tool) => tool.name == 'model');
        expect(search.title, 'Search');
        expect(search.description, 'Search documents');
        expect(search.meta, {'app': 'ack'});
        expect(model.title, 'Model');
        expect(model.description, 'Typed search');
        expect(model.meta, {'app': 'model'});
      });

      test(
        'passes defaults, normalized integers and request context',
        () async {
          final received = <JsonMap>[];
          server.registerAckTool(
            'search',
            input: searchSchema(),
            callback: (args, extra) async {
              received.add(args);
              expect(extra, isA<RequestHandlerExtra>());
              return textResult('${args['limit']}');
            },
          );
          await connect();
          expect(
            resultText(
              await client.callTool(
                const CallToolRequest(
                  name: 'search',
                  arguments: {'query': 'dart'},
                ),
              ),
            ),
            '5',
          );
          expect(
            resultText(
              await client.callTool(
                const CallToolRequest(
                  name: 'search',
                  arguments: {'query': 'dart', 'limit': 2.0},
                ),
              ),
            ),
            '2',
          );
          expect(received.last['limit'], isA<int>());
          expect(received, hasLength(2));
        },
      );

      test('model callback receives a typed model and defaults', () async {
        SearchInput? received;
        server.registerAckTool(
          'search',
          input: SearchInput.schema,
          callback: (args, extra) {
            received = args;
            return textResult(args.query);
          },
        );
        await connect();
        expect(
          resultText(
            await client.callTool(
              const CallToolRequest(
                name: 'search',
                arguments: {'query': 'dart'},
              ),
            ),
          ),
          'dart',
        );
        expect(received?.limit, 5);
      });

      test('empty-object tools accept empty and omitted arguments', () async {
        var calls = 0;
        server.registerAckTool(
          'validate',
          input: Ack.object({}),
          callback: (args, extra) {
            expect(args, isEmpty);
            calls++;
            return textResult('valid');
          },
        );
        await connect();
        await client.callTool(
          const CallToolRequest(name: 'validate', arguments: {}),
        );
        await client.callTool(const CallToolRequest(name: 'validate'));
        expect(calls, 2);
      });

      test(
        'model conversion exceptions are redacted and session recovers',
        () async {
          var calls = 0;
          server.registerAckTool(
            'number',
            input: AckModelAdapter<JsonMap, JsonMap, int>(
              schema: () => Ack.object({'value': Ack.string()}),
              fromRuntime: (args) => int.parse(args['value'] as String),
              toRuntime: (value) => {'value': '$value'},
            ).modelSchema,
            callback: (args, extra) {
              calls++;
              return textResult('$args');
            },
          );
          await connect();
          final failure = await client.callTool(
            const CallToolRequest(
              name: 'number',
              arguments: {'value': 'PRIVATE-TOKEN-123'},
            ),
          );
          expect(failure.isError, isTrue);
          expect(resultText(failure), contains('Argument validation failed.'));
          expect(resultText(failure), isNot(contains('PRIVATE-TOKEN-123')));
          expect(calls, 0);
          final success = await client.callTool(
            const CallToolRequest(name: 'number', arguments: {'value': '7'}),
          );
          expect(resultText(success), '7');
          expect(calls, 1);
        },
      );

      test(
        'custom invalid handler receives the original exception details',
        () async {
          SchemaError? received;
          server.registerAckTool(
            'number',
            input: AckModelAdapter<JsonMap, JsonMap, int>(
              schema: () => Ack.object({'value': Ack.string()}),
              fromRuntime: (args) => int.parse(args['value'] as String),
              toRuntime: (value) => {'value': '$value'},
            ).modelSchema,
            onInvalidArguments: (error) {
              received = error;
              return textResult('Use digits only.');
            },
            callback: (args, extra) =>
                fail('Invalid arguments reached callback'),
          );
          await connect();
          final result = await client.callTool(
            const CallToolRequest(
              name: 'number',
              arguments: {'value': 'PRIVATE-TOKEN-123'},
            ),
          );
          expect(resultText(result), 'Use digits only.');
          expect(received?.cause, isA<FormatException>());
          expect(received?.message, contains('PRIVATE-TOKEN-123'));
          expect(received?.stackTrace, isNotNull);
        },
      );

      for (final useModel in [false, true]) {
        test(
          'refinement failure skips ${useModel ? 'model' : 'schema'} callback and session recovers',
          () async {
            var calls = 0;
            final input = searchSchema().refine(
              (args) => args['query'] != 'blocked',
              message: 'Query is unavailable',
            );
            if (useModel) {
              server.registerAckTool(
                'search',
                input: AckModelAdapter<JsonMap, JsonMap, SearchInput>(
                  schema: () => input,
                  fromRuntime: searchModel.fromRuntime,
                  toRuntime: searchModel.toRuntime,
                ).modelSchema,
                callback: (args, extra) {
                  calls++;
                  return textResult(args.query);
                },
              );
            } else {
              server.registerAckTool(
                'search',
                input: input,
                callback: (args, extra) {
                  calls++;
                  return textResult(args['query'] as String);
                },
              );
            }
            await connect();
            final invalid = await client.callTool(
              const CallToolRequest(
                name: 'search',
                arguments: {'query': 'blocked'},
              ),
            );
            expect(invalid.isError, isTrue);
            expect(resultText(invalid), contains('Query is unavailable'));
            expect(calls, 0);
            expect(
              resultText(
                await client.callTool(
                  const CallToolRequest(
                    name: 'search',
                    arguments: {'query': 'ok'},
                  ),
                ),
              ),
              'ok',
            );
            expect(calls, 1);
          },
        );

        test(
          'custom invalid handler for ${useModel ? 'model' : 'schema'} tool',
          () async {
            var calls = 0;
            SchemaError? received;
            final input = searchSchema().refine(
              (args) => false,
              message: 'Unavailable',
            );
            CallToolResult invalid(SchemaError error) {
              received = error;
              return CallToolResult(
                isError: true,
                content: [TextContent(text: 'custom')],
              );
            }

            if (useModel) {
              server.registerAckTool(
                'search',
                input: AckModelAdapter<JsonMap, JsonMap, SearchInput>(
                  schema: () => input,
                  fromRuntime: searchModel.fromRuntime,
                  toRuntime: searchModel.toRuntime,
                ).modelSchema,
                onInvalidArguments: invalid,
                callback: (args, extra) {
                  calls++;
                  return textResult('wrong');
                },
              );
            } else {
              server.registerAckTool(
                'search',
                input: input,
                onInvalidArguments: invalid,
                callback: (args, extra) {
                  calls++;
                  return textResult('wrong');
                },
              );
            }
            await connect();
            final result = await client.callTool(
              const CallToolRequest(
                name: 'search',
                arguments: {'query': 'dart'},
              ),
            );
            expect(resultText(result), 'custom');
            expect(received, isA<SchemaError>());
            expect(calls, 0);
          },
        );
      }

      test(
        'MCP structural validation skips ACK and the app callback',
        () async {
          var calls = 0;
          var invalidCalls = 0;
          server.registerAckTool(
            'search',
            input: searchSchema(),
            onInvalidArguments: (error) {
              invalidCalls++;
              return textResult('wrong');
            },
            callback: (args, extra) {
              calls++;
              return textResult('ok');
            },
          );
          await connect();
          final result = client.callTool(
            const CallToolRequest(
              name: 'search',
              arguments: {'query': 'dart', 'limit': 2.5},
            ),
          );
          if (version == '2025-06-18') {
            await expectLater(
              result,
              throwsA(
                isA<McpError>().having(
                  (e) => e.code,
                  'code',
                  ErrorCode.invalidParams.value,
                ),
              ),
            );
          } else {
            expect((await result).isError, isTrue);
          }
          expect(calls, 0);
          expect(invalidCalls, 0);
          await client.callTool(
            const CallToolRequest(name: 'search', arguments: {'query': 'ok'}),
          );
          expect(calls, 1);
        },
      );

      test(
        'nullable schema and model roots fail synchronously at registration',
        () {
          final input = Ack.object({}).nullable();
          expect(
            () => server.registerAckTool(
              'bad',
              input: input,
              callback: (args, extra) => textResult('wrong'),
            ),
            throwsArgumentError,
          );
          expect(
            () => server.registerAckTool(
              'badModel',
              input: AckModelAdapter<JsonMap, JsonMap, JsonMap>(
                schema: () => input,
                fromRuntime: (args) => args,
                toRuntime: (args) => args,
              ).modelSchema,
              callback: (args, extra) => textResult('wrong'),
            ),
            throwsArgumentError,
          );
        },
      );
    });
  }
}

/// Linked byte streams exercising MCP serialization and protocol negotiation.
class _TransportPair {
  final _toServer = StreamController<List<int>>.broadcast();
  final _toClient = StreamController<List<int>>.broadcast();

  late final client = IOStreamTransport(
    stream: _toClient.stream,
    sink: _toServer.sink,
  );
  late final server = IOStreamTransport(
    stream: _toServer.stream,
    sink: _toClient.sink,
  );

  Future<void> close() async {
    await client.close();
    await server.close();
    await _toServer.close();
    await _toClient.close();
  }
}
