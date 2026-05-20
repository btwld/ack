import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:ack_firebase_ai/ack_firebase_ai.dart';

void main() {
  final userSchema = Ack.object({
    'name': Ack.string().minLength(2).maxLength(50),
    'email': Ack.string().email(),
    'age': Ack.integer().min(0).max(120).optional(),
  });

  final responseJsonSchema = userSchema.toFirebaseAiResponseJsonSchema();
  print(const JsonEncoder.withIndent('  ').convert(responseJsonSchema));

  final generatedText = jsonEncode({
    'name': 'Ada Lovelace',
    'email': 'ada@example.com',
    'age': 36,
  });
  final decoded = jsonDecode(generatedText);
  final result = userSchema.safeParse(decoded);

  if (result.isOk) {
    final user = result.getOrThrow();
    print('Valid user: $user');
    return;
  }

  throw StateError(
    'Generated response did not match schema: ${result.getError()}',
  );
}
