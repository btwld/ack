import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'status_model.g.dart';

@Schemable(description: 'A model demonstrating enum field validation')
class StatusModel {
  final String simpleStatus;

  StatusModel({
    @EnumString(['active', 'inactive', 'pending']) required this.simpleStatus,
  });
}
