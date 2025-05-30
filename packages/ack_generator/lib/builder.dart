import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator.dart';

/// Main builder function - keeps it simple
Builder ackSchemaBuilder(BuilderOptions options) {
  return PartBuilder(
    [AckSchemaGenerator()],
    '.g.dart',
    header: '''
// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_this, unnecessary_new, unnecessary_const, prefer_collection_literals
// ignore_for_file: lines_longer_than_80_chars, unnecessary_null_checks, non_constant_identifier_names
''',
  );
}
