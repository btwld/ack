/// The `json_serializable` configuration for each `AckCaseStyle`.
///
/// `AckJsonSerializableGenerator` resolves this library and passes the
/// constant named after a model's case style to its delegate as the class
/// annotation. Optional null fields stay absent; generated Ack glue restores
/// required nullable keys.
library;

import 'package:json_annotation/json_annotation.dart';

const none = JsonSerializable(
  includeIfNull: false,
  fieldRename: FieldRename.none,
);

const snake = JsonSerializable(
  includeIfNull: false,
  fieldRename: FieldRename.snake,
);

const kebab = JsonSerializable(
  includeIfNull: false,
  fieldRename: FieldRename.kebab,
);

const pascal = JsonSerializable(
  includeIfNull: false,
  fieldRename: FieldRename.pascal,
);

const screamingSnake = JsonSerializable(
  includeIfNull: false,
  fieldRename: FieldRename.screamingSnake,
);
