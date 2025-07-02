import 'package:ack_generator/src/builders/schema_builder.dart';
import 'package:ack_generator/src/models/model_info.dart';
import 'package:ack_generator/src/models/field_info.dart';

void main() {
  final builder = SchemaBuilder();
  
  final model = ModelInfo(
    className: 'User',
    schemaClassName: 'UserSchema', 
    description: 'User model for testing',
    fields: [
      FieldInfo(
        name: 'id',
        jsonKey: 'id',
        type: 'String',
        isRequired: true,
        isNullable: false,
        constraints: [],
        enumValues: [],
      ),
      FieldInfo(
        name: 'name', 
        jsonKey: 'name',
        type: 'String',
        isRequired: true,
        isNullable: false,
        constraints: [],
        enumValues: [],
      ),
    ],
    additionalProperties: false,
  );

  final result = builder.build(model);
  print('Generated output:');
  print('=' * 50);
  print(result);
  print('=' * 50);
}