import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'special_types_model.g.dart';

@AckModel()
@AckType()
class Event {
  final String name;
  final DateTime timestamp;
  final Uri website;
  final Duration duration;
  final DateTime? optionalDate;
  final Uri? optionalUri;
  final Duration? optionalDuration;

  Event({
    required this.name,
    required this.timestamp,
    required this.website,
    required this.duration,
    this.optionalDate,
    this.optionalUri,
    this.optionalDuration,
  });
}
