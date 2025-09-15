import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'edge_case_models.g.dart';

// Test deeply nested generic types - INTENTIONALLY COMMENTED OUT
// This demonstrates complex generics that are NOT supported by the generator
// @AckModel(model: true)
// class ComplexGenericModel {
//   final String id;
//   final List<Map<String, List<String>>> nestedData;
//   final Map<String, List<Map<String, dynamic>>> complexMap;
//
//   ComplexGenericModel({
//     required this.id,
//     required this.nestedData,
//     required this.complexMap,
//   });
// }

// Test circular reference handling - INTENTIONALLY COMMENTED OUT
// Self-referencing models are not yet supported
// @AckModel(model: true)
// class NodeModel {
//   final String id;
//   final String name;
//   final List<NodeModel>? children;
//   final NodeModel? parent;
//
//   NodeModel({
//     required this.id,
//     required this.name,
//     this.children,
//     this.parent,
//   });
// }

// Test very large number of fields (performance) - THIS WORKS
@AckModel(model: true)
class LargeFieldModel {
  final String field1;
  final String field2;
  final String field3;
  final String field4;
  final String field5;
  final String field6;
  final String field7;
  final String field8;
  final String field9;
  final String field10;
  final String field11;
  final String field12;
  final String field13;
  final String field14;
  final String field15;
  final String field16;
  final String field17;
  final String field18;
  final String field19;
  final String field20;

  LargeFieldModel({
    required this.field1,
    required this.field2,
    required this.field3,
    required this.field4,
    required this.field5,
    required this.field6,
    required this.field7,
    required this.field8,
    required this.field9,
    required this.field10,
    required this.field11,
    required this.field12,
    required this.field13,
    required this.field14,
    required this.field15,
    required this.field16,
    required this.field17,
    required this.field18,
    required this.field19,
    required this.field20,
  });
}

// Test special characters in field names - THIS WORKS
@AckModel(model: true)
class SpecialFieldsModel {
  @AckField(jsonKey: 'user-id')
  final String userId;

  @AckField(jsonKey: 'full_name')
  final String fullName;

  @AckField(jsonKey: 'email.address')
  final String emailAddress;

  @AckField(jsonKey: 'meta:data')
  final String metadata;

  SpecialFieldsModel({
    required this.userId,
    required this.fullName,
    required this.emailAddress,
    required this.metadata,
  });
}
