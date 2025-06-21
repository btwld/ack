import 'package:meta/meta_meta.dart';

/// Annotation to mark a class for schema generation
@Target({TargetKind.classType})
class AckModel {
  /// Optional custom schema class name
  final String? schemaName;
  
  /// Optional description for the schema
  final String? description;
  
  const AckModel({
    this.schemaName,
    this.description,
  });
}
