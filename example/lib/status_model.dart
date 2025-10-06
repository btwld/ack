import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'status_model.g.dart';

@AckModel(description: 'A model demonstrating enum field validation')
class StatusModel {
  @EnumString(['active', 'inactive', 'pending'])
  final String simpleStatus;

  StatusModel({required this.simpleStatus});
}
