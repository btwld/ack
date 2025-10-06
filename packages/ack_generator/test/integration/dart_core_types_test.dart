import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  group('Dart Core Types', () {
    final allAssets = {
      'ack_annotations|lib/ack_annotations.dart': '''
export 'src/ack_model.dart';
''',
      'ack_annotations|lib/src/ack_model.dart': '''
class AckModel {
  final String? schemaName;
  final String? description;
  final bool additionalProperties;
  final String? additionalPropertiesField;
  final bool model;
  final String? discriminatedKey;
  final String? discriminatedValue;

  const AckModel({
    this.schemaName,
    this.description,
    this.additionalProperties = false,
    this.additionalPropertiesField,
    this.model = false,
    this.discriminatedKey,
    this.discriminatedValue,
  });
}
''',
      'ack|lib/ack.dart': '''
class Ack {
  static ObjectSchema object(Map<String, dynamic> fields, {bool additionalProperties = false}) => ObjectSchema();
  static StringSchema string() => StringSchema();
  static IntegerSchema integer() => IntegerSchema();
  static DoubleSchema double() => DoubleSchema();
  static BooleanSchema boolean() => BooleanSchema();
  static ListSchema list(dynamic schema) => ListSchema();
  static AnySchema any() => AnySchema();
}
class ObjectSchema {
  ObjectSchema optional() => this;
  ObjectSchema nullable() => this;
}
class StringSchema {
  StringSchema datetime() => this;
  StringSchema uri() => this;
  StringSchema optional() => this;
  StringSchema nullable() => this;
}
class IntegerSchema {
  IntegerSchema optional() => this;
  IntegerSchema nullable() => this;
}
class DoubleSchema {
  DoubleSchema optional() => this;
  DoubleSchema nullable() => this;
}
class BooleanSchema {
  BooleanSchema optional() => this;
  BooleanSchema nullable() => this;
}
class ListSchema {
  ListSchema optional() => this;
  ListSchema nullable() => this;
}
class AnySchema {
  AnySchema optional() => this;
  AnySchema nullable() => this;
}
''',
    };

    test('handles DateTime type correctly', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/datetime_model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class EventModel {
  final String name;
  final DateTime createdAt;
  final DateTime? updatedAt;

  EventModel({
    required this.name,
    required this.createdAt,
    this.updatedAt,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/datetime_model.g.dart': decodedMatches(
            allOf([
              contains('final eventModelSchema = Ack.object('),
              contains("'name': Ack.string()"),
              contains("'createdAt': Ack.string().datetime()"),
              contains(
                "'updatedAt': Ack.string().datetime().optional().nullable()",
              ),
            ]),
          ),
        },
      );
    });

    test('handles Duration type correctly', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/duration_model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class TimerModel {
  final String name;
  final Duration timeout;
  final Duration? interval;

  TimerModel({
    required this.name,
    required this.timeout,
    this.interval,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/duration_model.g.dart': decodedMatches(
            allOf([
              contains('final timerModelSchema = Ack.object('),
              contains("'name': Ack.string()"),
              contains("'timeout': Ack.integer()"),
              contains("'interval': Ack.integer().optional().nullable()"),
            ]),
          ),
        },
      );
    });

    test('handles Uri type correctly', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/uri_model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class LinkModel {
  final String title;
  final Uri url;
  final Uri? referrer;

  LinkModel({
    required this.title,
    required this.url,
    this.referrer,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/uri_model.g.dart': decodedMatches(
            allOf([
              contains('final linkModelSchema = Ack.object('),
              contains("'title': Ack.string()"),
              contains("'url': Ack.string().uri()"),
              contains("'referrer': Ack.string().uri().optional().nullable()"),
            ]),
          ),
        },
      );
    });

    test('handles all dart:core special types together', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/comprehensive_model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class ComprehensiveModel {
  final String name;
  final DateTime timestamp;
  final Duration elapsed;
  final Uri endpoint;
  final DateTime? optionalDate;
  final Duration? optionalDuration;
  final Uri? optionalUri;

  ComprehensiveModel({
    required this.name,
    required this.timestamp,
    required this.elapsed,
    required this.endpoint,
    this.optionalDate,
    this.optionalDuration,
    this.optionalUri,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/comprehensive_model.g.dart': decodedMatches(
            allOf([
              contains('final comprehensiveModelSchema = Ack.object('),
              contains("'name': Ack.string()"),
              contains("'timestamp': Ack.string().datetime()"),
              contains("'elapsed': Ack.integer()"),
              contains("'endpoint': Ack.string().uri()"),
              contains(
                "'optionalDate': Ack.string().datetime().optional().nullable()",
              ),
              contains(
                "'optionalDuration': Ack.integer().optional().nullable()",
              ),
              contains(
                "'optionalUri': Ack.string().uri().optional().nullable()",
              ),
            ]),
          ),
        },
      );
    });

    test('handles List<DateTime> correctly', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/list_datetime_model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class ScheduleModel {
  final String name;
  final List<DateTime> appointments;

  ScheduleModel({
    required this.name,
    required this.appointments,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/list_datetime_model.g.dart': decodedMatches(
            allOf([
              contains('final scheduleModelSchema = Ack.object('),
              contains("'name': Ack.string()"),
              contains("'appointments': Ack.list(Ack.string().datetime())"),
            ]),
          ),
        },
      );
    });

    test('handles List<Uri> correctly', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/list_uri_model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class BookmarksModel {
  final String category;
  final List<Uri> links;

  BookmarksModel({
    required this.category,
    required this.links,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/list_uri_model.g.dart': decodedMatches(
            allOf([
              contains('final bookmarksModelSchema = Ack.object('),
              contains("'category': Ack.string()"),
              contains("'links': Ack.list(Ack.string().uri())"),
            ]),
          ),
        },
      );
    });
  });
}
