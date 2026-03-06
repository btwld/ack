import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';

import '../models/model_info.dart';
import '../models/type_provider_info.dart';
import 'annotation_utils.dart';

class UnsupportedSchemaTypeError implements Exception {
  final String typeName;

  const UnsupportedSchemaTypeError(this.typeName);

  @override
  String toString() => 'Unsupported schema type: $typeName';
}

class ResolvedSchemaType {
  final String schemaExpression;
  final TypeProviderInfo? provider;

  const ResolvedSchemaType({required this.schemaExpression, this.provider});
}

class SchemableTypeResolver {
  final List<ModelInfo> allModels;
  final List<TypeProviderInfo> typeProviders;
  final LibraryElement2? currentLibrary;

  const SchemableTypeResolver({
    this.allModels = const [],
    this.typeProviders = const [],
    this.currentLibrary,
  });

  ResolvedSchemaType resolve(DartType type) {
    final typeName = type.getDisplayString(withNullability: false);

    final primitiveSchema = _primitiveSchemaFor(typeName);
    if (primitiveSchema != null) {
      return ResolvedSchemaType(schemaExpression: primitiveSchema);
    }

    final specialSchema = _specialSchemaFor(type);
    if (specialSchema != null) {
      return ResolvedSchemaType(schemaExpression: specialSchema);
    }

    if (type is TypeParameterType ||
        type.isDartCoreObject ||
        typeName == 'dynamic') {
      return const ResolvedSchemaType(schemaExpression: 'Ack.any()');
    }

    if (_isEnum(type)) {
      return ResolvedSchemaType(
        schemaExpression: 'Ack.enumValues<$typeName>($typeName.values)',
      );
    }

    if (type.isDartCoreList) {
      final itemType = _firstTypeArgument(type);
      if (itemType == null) {
        return const ResolvedSchemaType(
          schemaExpression: 'Ack.list(Ack.any())',
        );
      }

      final resolvedItemType = resolve(itemType);
      return ResolvedSchemaType(
        schemaExpression: 'Ack.list(${resolvedItemType.schemaExpression})',
        provider: resolvedItemType.provider,
      );
    }

    if (type.isDartCoreMap) {
      return const ResolvedSchemaType(
        schemaExpression: 'Ack.object({}, additionalProperties: true)',
      );
    }

    if (type.isDartCoreSet) {
      final itemType = _firstTypeArgument(type);
      if (itemType == null) {
        return const ResolvedSchemaType(
          schemaExpression: 'Ack.list(Ack.any()).unique()',
        );
      }

      final resolvedItemType = resolve(itemType);
      return ResolvedSchemaType(
        schemaExpression:
            'Ack.list(${resolvedItemType.schemaExpression}).unique()',
        provider: resolvedItemType.provider,
      );
    }

    final provider = _providerFor(type);
    if (provider != null) {
      return ResolvedSchemaType(
        schemaExpression: '(${provider.accessor}.schema as AckSchema)',
        provider: provider,
      );
    }

    final schemableSchema = _schemableSchemaReferenceFor(type);
    if (schemableSchema != null) {
      return ResolvedSchemaType(schemaExpression: schemableSchema);
    }

    throw UnsupportedSchemaTypeError(typeName);
  }

  String schemaExpressionFor(DartType type) => resolve(type).schemaExpression;

  TypeProviderInfo? providerFor(DartType type) => _providerFor(type);

  String? schemableSchemaReferenceFor(DartType type) {
    return _schemableSchemaReferenceFor(type);
  }

  TypeProviderInfo? _providerFor(DartType type) {
    final typeName = type.getDisplayString(withNullability: false);
    for (final provider in typeProviders) {
      if (provider.targetTypeName == typeName) {
        return provider;
      }
    }
    return null;
  }

  String? _primitiveSchemaFor(String typeName) {
    return switch (typeName) {
      'String' => 'Ack.string()',
      'int' => 'Ack.integer()',
      'double' => 'Ack.double()',
      'bool' => 'Ack.boolean()',
      'num' => 'Ack.double()',
      _ => null,
    };
  }

  String? _specialSchemaFor(DartType type) {
    if (_isDartCoreType(type, 'DateTime')) {
      return 'Ack.string().datetime()';
    }
    if (_isDartCoreType(type, 'Uri')) {
      return 'Ack.string().uri()';
    }
    if (_isDartCoreType(type, 'Duration')) {
      return 'Ack.integer()';
    }
    return null;
  }

  bool _isEnum(DartType type) => type.element3 is EnumElement2;

  String? _schemableSchemaReferenceFor(DartType type) {
    final typeName = type.getDisplayString(withNullability: false);
    final element = type.element3;
    if (element is InterfaceElement2) {
      final annotation = firstSchemableAnnotationOf(element);
      if (annotation == null) {
        return null;
      }

      final schemaVariableName = schemaVariableNameForElement(element);
      final prefix =
          _importPrefixForElement(element) ??
          _prefixForDisplayName(typeName, element.name3);
      if (prefix == null) {
        return schemaVariableName;
      }

      return '$prefix.$schemaVariableName';
    }

    final knownModel = _knownModelForDisplayType(typeName);
    if (knownModel != null) {
      return schemaVariableNameForSchemaClassName(knownModel.schemaClassName);
    }
    return null;
  }

  ModelInfo? _knownModelForDisplayType(String displayType) {
    final baseTypeName = _baseTypeName(displayType);
    return allModels.cast<ModelInfo?>().firstWhere(
      (model) => model?.className == baseTypeName,
      orElse: () => null,
    );
  }

  String _baseTypeName(String displayType) {
    final genericIndex = displayType.indexOf('<');
    final withoutGenerics = genericIndex == -1
        ? displayType
        : displayType.substring(0, genericIndex);
    final segments = withoutGenerics.split('.');
    return segments.isEmpty ? withoutGenerics : segments.last;
  }

  String? _prefixForDisplayName(String displayName, String? elementName) {
    if (elementName == null) return null;

    final genericIndex = displayName.indexOf('<');
    final trimmedDisplayName = genericIndex == -1
        ? displayName
        : displayName.substring(0, genericIndex);

    final suffix = '.$elementName';
    if (!trimmedDisplayName.endsWith(suffix)) {
      return null;
    }

    return trimmedDisplayName.substring(
      0,
      trimmedDisplayName.length - suffix.length,
    );
  }

  String? _importPrefixForElement(InterfaceElement2 element) {
    final library = currentLibrary;
    if (library == null) {
      return null;
    }

    for (final import in library.firstFragment.libraryImports2) {
      final prefix = import.prefix2?.element.name3;
      if (prefix == null || prefix.isEmpty) {
        continue;
      }

      final importedElement = import.namespace.get2(element.name3 ?? '');
      if (importedElement == element) {
        return prefix;
      }

      final exportedElement = import.importedLibrary2?.exportNamespace.get2(
        element.name3 ?? '',
      );
      if (exportedElement == element) {
        return prefix;
      }
    }

    return null;
  }

  DartType? _firstTypeArgument(DartType type) {
    if (type is! ParameterizedType || type.typeArguments.isEmpty) {
      return null;
    }

    return type.typeArguments.first;
  }

  bool _isDartCoreType(DartType type, String typeName) {
    final element = type.element3;
    return element?.name3 == typeName &&
        element?.library2?.name3 == 'dart.core';
  }
}
