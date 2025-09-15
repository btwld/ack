import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'validation_test_model.g.dart';

// This model demonstrates complex generics that are NOT supported by the generator
// This is intentionally commented out to avoid build errors
// @AckModel(model: true)
// class ComplexValidationModel {
//   final String id;
//
//   // This complex nested generic should be caught by our validator
//   final List<Map<String, List<String>>> problematicField;
//
//   ComplexValidationModel({
//     required this.id,
//     required this.problematicField,
//   });
// }

// Simple model that DOES work with the generator
@AckModel(model: true)
class SimpleValidationModel {
  final String id;
  final String name;
  final List<String> tags;

  SimpleValidationModel({
    required this.id,
    required this.name,
    required this.tags,
  });
}
