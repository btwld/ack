import 'package:ack/ack.dart';

part 'large_model.g.dart';

/// Large model with many properties for performance testing
@Schema(
  description: 'Large model with many properties for performance testing',
  additionalProperties: true,
  additionalPropertiesField: 'extraData',
)
class LargeModel {
  // String fields with various validations
  @IsNotEmpty()
  final String field1;
  
  @IsEmail()
  final String field2;
  
  @MinLength(5)
  final String field3;
  
  @IsNotEmpty()
  final String field4;
  
  @MinLength(3)
  final String field5;
  
  // Numeric fields
  final int field6;
  final double field7;
  final int field8;
  final double field9;
  final int field10;
  
  // Boolean fields
  final bool field11;
  final bool field12;
  final bool field13;
  
  // DateTime fields
  final DateTime field14;
  final DateTime field15;
  
  // Optional fields with various constraints
  @Nullable()
  final String? field16;
  
  @Required()
  final String? field17;
  
  @Nullable()
  final int? field18;
  
  @Required()
  final bool? field19;
  
  @Nullable()
  final DateTime? field20;
  
  // Collection fields
  final List<String> field21;
  final List<int> field22;
  final Map<String, dynamic> field23;
  final List<bool> field24;
  
  // Additional properties field
  final Map<String, dynamic> extraData;

  LargeModel({
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
    this.field16,
    this.field17,
    this.field18,
    this.field19,
    this.field20,
    required this.field21,
    required this.field22,
    required this.field23,
    required this.field24,
    Map<String, dynamic>? extraData,
  }) : extraData = extraData ?? {};
}
