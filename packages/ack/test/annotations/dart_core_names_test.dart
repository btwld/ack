import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';
import 'package:test/test.dart';

@Schemable(name: 'Endpoint')
final class _Endpoint {
  const _Endpoint({required this.uri, required this.createdAt});

  @AckKey('endpoint_uri')
  @Validate.uri()
  final Uri uri;

  @Validate.dateTime()
  final DateTime createdAt;
}

void main() {
  test(
    'package:ack/ack.dart and annotations.dart leave dart:core Pattern, Uri, and DateTime visible',
    () {
      final Pattern pattern = RegExp('a');
      const annotation = Schemable(name: 'Banana');
      final endpoint = _Endpoint(
        uri: Uri.parse('https://example.com'),
        createdAt: DateTime.utc(2026, 10, 1),
      );

      expect(pattern.allMatches(annotation.name!.toLowerCase()), hasLength(3));
      expect(endpoint.uri.host, 'example.com');
      expect(endpoint.createdAt.year, 2026);
    },
  );
}
