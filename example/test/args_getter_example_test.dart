import 'package:test/test.dart';

import '../lib/args_getter_example.dart';

void main() {
  group('Args getter examples', () {
    test('args excludes declared fields', () {
      final config = UserConfigType.parse({
        'username': 'leo',
        'email': 'leo@example.com',
        'theme': 'dark',
        'retries': 3,
      });

      expect(config.username, 'leo');
      expect(config.email, 'leo@example.com');
      expect(config.args, {'theme': 'dark', 'retries': 3});
    });

    test('passthrough additional properties are preserved', () {
      final request = ApiRequestType.parse({
        'method': 'POST',
        'url': 'https://api.example.com/users',
        'headers': {'x-trace': '123'},
        'timeoutMs': 5000,
      });

      expect(request.method, 'POST');
      expect(request.url, 'https://api.example.com/users');
      expect(request.args, {
        'headers': {'x-trace': '123'},
        'timeoutMs': 5000,
      });
    });

    test('empty-schema passthrough keeps all properties in args', () {
      final data = {'enabled': true, 'rollout': 25, 'label': 'beta'};
      final dynamicData = DynamicDataType.parse(data);

      expect(dynamicData.args, data);
    });
  });
}
