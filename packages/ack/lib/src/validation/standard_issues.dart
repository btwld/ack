import 'package:standard_schema/standard_schema.dart';

import 'schema_error.dart';

extension StandardIssueConversion on SchemaError {
  List<StandardIssue> toStandardIssues() {
    return switch (this) {
      SchemaNestedError(:final errors) when errors.isNotEmpty => [
        for (final error in errors) ...error.toStandardIssues(),
      ],
      SchemaConstraintsError(:final constraints) when constraints.isNotEmpty =>
        [
          for (final constraint in constraints)
            StandardIssue(
              message: constraint.message,
              path: context.pathSegments,
            ),
        ],
      _ => [StandardIssue(message: message, path: context.pathSegments)],
    };
  }
}
