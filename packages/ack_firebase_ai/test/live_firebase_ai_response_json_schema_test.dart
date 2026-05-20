import 'dart:convert';
import 'dart:io';

import 'package:ack/ack.dart';
import 'package:ack_firebase_ai/ack_firebase_ai.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final liveConfig = _LiveFirebaseAiConfig.fromEnvironment(
    Platform.environment,
    dartDefines: _liveFirebaseAiDartDefines,
  );

  group('live Firebase AI configuration', () {
    test('uses Firebase env vars and the latest Flash default', () {
      final config = _LiveFirebaseAiConfig.fromEnvironment(
        _liveFirebaseAiEnv(),
      );

      expect(config, isNotNull);
      expect(config!.firebaseOptions.apiKey, 'api-key');
      expect(config.firebaseOptions.projectId, 'project-id');
      expect(config.firebaseOptions.appId, 'app-id');
      expect(config.firebaseOptions.messagingSenderId, 'sender-id');
      expect(config.backend, _LiveFirebaseAiBackend.googleAI);
      expect(config.location, 'global');
      expect(config.model, _defaultLiveFirebaseAiModel);
    });

    test('allows dart-define overrides for backend, location, and model', () {
      final config = _LiveFirebaseAiConfig.fromEnvironment(
        const {},
        dartDefines: _liveFirebaseAiEnv(
          backend: 'vertex-ai',
          location: 'us-central1',
          model: 'gemini-3-flash-preview',
        ),
      );

      expect(config, isNotNull);
      expect(config!.backend, _LiveFirebaseAiBackend.vertexAI);
      expect(config.location, 'us-central1');
      expect(config.model, 'gemini-3-flash-preview');
    });
  });

  group(
    'live Firebase AI responseJsonSchema',
    skip: liveConfig == null ? _liveTestSkipReason : false,
    () {
      late FirebaseApp app;

      setUpAll(() async {
        _LiveFirebaseAiTestWidgetsBinding.ensureInitialized();
        TestFirebaseCoreHostApi.setUp(_LiveFirebaseCoreHostApi());

        app = await Firebase.initializeApp(
          name: 'ack-firebase-ai-live-${DateTime.now().microsecondsSinceEpoch}',
          options: liveConfig!.firebaseOptions,
        );
      });

      test(
        'generates JSON that validates with the same ACK schema',
        () async {
          final schema = Ack.object({
            'category': Ack.enumString(['bug', 'feature', 'docs']),
            'confidence': Ack.integer().min(0).max(100),
            'actions': Ack.list(
              Ack.object({
                'title': Ack.string(),
                'owner': Ack.enumString(['engineering', 'product', 'docs']),
                'estimate': Ack.anyOf([
                  Ack.integer().min(1).max(5),
                  Ack.enumString(['unknown']),
                ]),
              }, additionalProperties: false),
            ).minLength(2).maxLength(3),
          }, additionalProperties: false).describe('Issue triage response');

          final model = liveConfig!
              .firebaseAI(app)
              .generativeModel(
                model: liveConfig.model,
                generationConfig: GenerationConfig(
                  responseMimeType: 'application/json',
                  responseJsonSchema: schema.toFirebaseAiResponseJsonSchema(),
                  temperature: 0,
                  maxOutputTokens: 2048,
                ),
              );

          final response = await model.generateContent([
            Content.text(
              'Return issue triage JSON only. Use category "bug", '
              'confidence 87, and exactly two actions. Each action needs a '
              'title, owner, and estimate.',
            ),
          ]);

          final generatedJson = _decodeGeneratedJson(response.text);
          final parsed = schema.safeParse(generatedJson);

          expect(
            parsed.isOk,
            isTrue,
            reason:
                'Firebase AI returned JSON that ACK rejected.\n'
                'Generated response: ${jsonEncode(generatedJson)}\n'
                'ACK error: ${parsed.isFail ? parsed.getError() : null}',
          );
        },
        timeout: const Timeout(Duration(minutes: 2)),
      );
    },
  );
}

Map<String, String> _liveFirebaseAiEnv({
  String backend = '',
  String location = '',
  String model = '',
}) {
  return {
    'ACK_FIREBASE_AI_LIVE': '1',
    if (backend.isNotEmpty) 'ACK_FIREBASE_AI_BACKEND': backend,
    if (location.isNotEmpty) 'FIREBASE_AI_LOCATION': location,
    if (model.isNotEmpty) 'ACK_FIREBASE_AI_MODEL': model,
    'FIREBASE_API_KEY': 'api-key',
    'FIREBASE_PROJECT_ID': 'project-id',
    'FIREBASE_APP_ID': 'app-id',
    'FIREBASE_MESSAGING_SENDER_ID': 'sender-id',
  };
}

const _liveTestSkipReason = '''
Set ACK_FIREBASE_AI_LIVE=1 plus FIREBASE_API_KEY, FIREBASE_PROJECT_ID,
FIREBASE_APP_ID, and FIREBASE_MESSAGING_SENDER_ID to run the live Firebase AI
responseJsonSchema contract test. The default model is gemini-3.5-flash.
Optionally set ACK_FIREBASE_AI_MODEL or ACK_FIREBASE_AI_BACKEND.
''';

const _defaultLiveFirebaseAiModel = 'gemini-3.5-flash';

const _liveFirebaseAiDartDefines = {
  'ACK_FIREBASE_AI_LIVE': String.fromEnvironment('ACK_FIREBASE_AI_LIVE'),
  'ACK_FIREBASE_AI_BACKEND': String.fromEnvironment('ACK_FIREBASE_AI_BACKEND'),
  'ACK_FIREBASE_AI_MODEL': String.fromEnvironment('ACK_FIREBASE_AI_MODEL'),
  'FIREBASE_AI_LOCATION': String.fromEnvironment('FIREBASE_AI_LOCATION'),
  'FIREBASE_API_KEY': String.fromEnvironment('FIREBASE_API_KEY'),
  'FIREBASE_PROJECT_ID': String.fromEnvironment('FIREBASE_PROJECT_ID'),
  'FIREBASE_APP_ID': String.fromEnvironment('FIREBASE_APP_ID'),
  'FIREBASE_MESSAGING_SENDER_ID': String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  ),
};

Object? _decodeGeneratedJson(String? responseText) {
  expect(responseText, isNotNull, reason: 'Firebase AI returned no text.');

  try {
    return jsonDecode(responseText!);
  } on FormatException catch (error) {
    fail('Firebase AI returned non-JSON text: $responseText\n$error');
  }
}

final class _LiveFirebaseAiConfig {
  const _LiveFirebaseAiConfig({
    required this.firebaseOptions,
    required this.backend,
    required this.location,
    required this.model,
  });

  final FirebaseOptions firebaseOptions;
  final _LiveFirebaseAiBackend backend;
  final String location;
  final String model;

  FirebaseAI firebaseAI(FirebaseApp app) {
    return switch (backend) {
      _LiveFirebaseAiBackend.googleAI => FirebaseAI.googleAI(app: app),
      _LiveFirebaseAiBackend.vertexAI => FirebaseAI.vertexAI(
        app: app,
        location: location,
      ),
    };
  }

  static _LiveFirebaseAiConfig? fromEnvironment(
    Map<String, String> env, {
    Map<String, String> dartDefines = const {},
  }) {
    if (_optionalConfig(env, dartDefines, 'ACK_FIREBASE_AI_LIVE') != '1') {
      return null;
    }

    final apiKey = _requiredConfig(env, dartDefines, 'FIREBASE_API_KEY');
    final projectId = _requiredConfig(env, dartDefines, 'FIREBASE_PROJECT_ID');
    final appId = _requiredConfig(env, dartDefines, 'FIREBASE_APP_ID');
    final messagingSenderId = _requiredConfig(
      env,
      dartDefines,
      'FIREBASE_MESSAGING_SENDER_ID',
    );

    return _LiveFirebaseAiConfig(
      firebaseOptions: FirebaseOptions(
        apiKey: apiKey,
        projectId: projectId,
        appId: appId,
        messagingSenderId: messagingSenderId,
      ),
      backend: _LiveFirebaseAiBackend.parse(
        _optionalConfig(env, dartDefines, 'ACK_FIREBASE_AI_BACKEND'),
      ),
      location:
          _optionalConfig(env, dartDefines, 'FIREBASE_AI_LOCATION') ?? 'global',
      model:
          _optionalConfig(env, dartDefines, 'ACK_FIREBASE_AI_MODEL') ??
          _defaultLiveFirebaseAiModel,
    );
  }
}

enum _LiveFirebaseAiBackend {
  googleAI,
  vertexAI;

  static _LiveFirebaseAiBackend parse(String? value) {
    final normalized = value?.replaceAll('-', '_').toLowerCase();
    return switch (normalized) {
      null ||
      '' ||
      'google_ai' ||
      'google' ||
      'developer' => _LiveFirebaseAiBackend.googleAI,
      'vertex_ai' || 'vertex' => _LiveFirebaseAiBackend.vertexAI,
      _ => throw ArgumentError.value(
        value,
        'ACK_FIREBASE_AI_BACKEND',
        'Expected google_ai or vertex_ai.',
      ),
    };
  }
}

String _requiredConfig(
  Map<String, String> env,
  Map<String, String> dartDefines,
  String name,
) {
  final value = _optionalConfig(env, dartDefines, name);
  if (value == null) {
    throw StateError('Set $name to run the live Firebase AI test.');
  }
  return value;
}

String? _optionalConfig(
  Map<String, String> env,
  Map<String, String> dartDefines,
  String name,
) {
  final envValue = env[name]?.trim();
  if (envValue != null && envValue.isNotEmpty) return envValue;

  final defineValue = dartDefines[name]?.trim();
  if (defineValue != null && defineValue.isNotEmpty) return defineValue;

  return null;
}

final class _LiveFirebaseCoreHostApi implements TestFirebaseCoreHostApi {
  @override
  Future<CoreInitializeResponse> initializeApp(
    String appName,
    CoreFirebaseOptions initializeAppRequest,
  ) async {
    return CoreInitializeResponse(
      name: appName,
      options: initializeAppRequest,
      pluginConstants: {},
    );
  }

  @override
  Future<List<CoreInitializeResponse>> initializeCore() async => [];

  @override
  Future<CoreFirebaseOptions> optionsFromResource() {
    throw UnsupportedError(
      'Live Firebase AI tests require explicit FirebaseOptions from env vars.',
    );
  }
}

final class _LiveFirebaseAiTestWidgetsBinding
    extends AutomatedTestWidgetsFlutterBinding {
  static _LiveFirebaseAiTestWidgetsBinding ensureInitialized() {
    TestWidgetsFlutterBinding? existingBinding;
    try {
      existingBinding = TestWidgetsFlutterBinding.instance;
    } catch (_) {
      return _LiveFirebaseAiTestWidgetsBinding();
    }

    if (existingBinding case final _LiveFirebaseAiTestWidgetsBinding binding) {
      return binding;
    }
    throw StateError(
      'The live Firebase AI test requires an HTTP-enabled test binding, but '
      '${existingBinding.runtimeType} is already initialized.',
    );
  }

  @override
  bool get overrideHttpClient => false;
}
