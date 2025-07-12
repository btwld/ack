import 'package:ack_annotations/ack_annotations.dart';

part 'validation_test_model.g.dart';

// This model should trigger validation warnings for complex generics
@AckModel(model: true)
class ComplexValidationModel {
  final String id;
  
  // This complex nested generic should be caught by our validator
  final List<Map<String, List<String>>> problematicField;
  
  ComplexValidationModel({
    required this.id,
    required this.problematicField,
  });
}