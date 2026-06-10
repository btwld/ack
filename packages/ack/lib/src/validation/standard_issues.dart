import 'package:schema_model/schema_model.dart';

import 'schema_error.dart';

extension StandardIssueConversion on SchemaError {
  List<StandardIssue> toStandardIssues() {
    return switch (this) {
      SchemaNestedError(errors: final errors) when errors.isNotEmpty => [
        for (final error in errors) ...error.toStandardIssues(),
      ],
      SchemaConstraintsError(constraints: final constraints)
          when constraints.isNotEmpty =>
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
