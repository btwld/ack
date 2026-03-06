import 'package:ack_annotations/ack_annotations.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import '../models/field_info.dart';
import '../models/model_info.dart';
import '../models/type_provider_info.dart';
import '../utils/annotation_utils.dart';
import '../utils/doc_comment_utils.dart';
import '../utils/type_resolver.dart';
import 'field_analyzer.dart';

/// Analyzes classes annotated with `@Schemable`.
class ModelAnalyzer {
  final _fieldAnalyzer = FieldAnalyzer();

  ModelInfo analyze(ClassElement2 element, ConstantReader annotation) {
    final schemaName = _readOptionalString(annotation, 'schemaName');
    final schemaClassName = schemaName ?? '${element.name3}Schema';
    final description =
        _readOptionalString(annotation, 'description') ??
        parseDocComment(element.documentationComment);
    final additionalProperties =
        annotation.peek('additionalProperties')?.boolValue ?? false;
    final additionalPropertiesField = _readOptionalString(
      annotation,
      'additionalPropertiesField',
    );
    final discriminatedKey = _readOptionalString(
      annotation,
      'discriminatedKey',
    );
    final discriminatedValue = _readOptionalString(
      annotation,
      'discriminatedValue',
    );
    final caseStyle = _readCaseStyle(annotation);
    final typeProviders = _readTypeProviders(element, annotation);
    final typeResolver = SchemableTypeResolver(
      typeProviders: typeProviders,
      currentLibrary: element.library2,
    );

    _validateDiscriminatedTypeUsage(
      element,
      discriminatedKey,
      discriminatedValue,
    );

    final constructor = _selectSchemaConstructor(element);
    final fields = <FieldInfo>[];

    for (final parameter in constructor.formalParameters) {
      if (!parameter.isNamed) {
        throw ArgumentError(
          'Only named constructor parameters are supported. '
          'Parameter "${parameter.name3}" in ${_constructorLabel(element, constructor)} '
          'must be named.',
        );
      }

      final fieldInfo = _analyzeField(
        element,
        constructor,
        parameter,
        caseStyle,
        typeResolver,
      );

      if (additionalPropertiesField != null &&
          fieldInfo.name == additionalPropertiesField) {
        continue;
      }

      fields.add(fieldInfo);
    }

    if (additionalPropertiesField != null) {
      _validateAdditionalPropertiesField(
        element,
        additionalPropertiesField,
        additionalProperties,
      );
    }

    return ModelInfo(
      className: element.name3!,
      schemaClassName: schemaClassName,
      description: description,
      fields: fields,
      additionalProperties: additionalProperties,
      additionalPropertiesField: additionalPropertiesField,
      typeProviders: typeProviders,
      discriminatorKey: discriminatedKey,
      discriminatorValue: discriminatedValue,
      subtypeNames: null,
    );
  }

  void _validateFieldType(
    ClassElement2 element,
    ConstructorElement2 constructor,
    FieldInfo field,
    SchemableTypeResolver typeResolver,
  ) {
    try {
      typeResolver.schemaExpressionFor(field.type);
    } on UnsupportedSchemaTypeError catch (error) {
      throw ArgumentError(
        'Unsupported type "${error.typeName}" for parameter "${field.name}" '
        'in ${_constructorLabel(element, constructor)}. '
        'Annotate the type with @Schemable() or register a schema provider with '
        '@Schemable(useProviders: const [YourProvider]).',
      );
    }
  }

  FieldInfo _analyzeField(
    ClassElement2 element,
    ConstructorElement2 constructor,
    FormalParameterElement parameter,
    CaseStyle caseStyle,
    SchemableTypeResolver typeResolver,
  ) {
    final fieldInfo = _fieldAnalyzer.analyze(parameter, caseStyle: caseStyle);
    _validateFieldType(element, constructor, fieldInfo, typeResolver);

    return fieldInfo.copyWith(
      schemaExpressionOverride: typeResolver.schemaExpressionFor(
        fieldInfo.type,
      ),
    );
  }

  ConstructorElement2 _selectSchemaConstructor(ClassElement2 element) {
    final annotatedConstructors = element.constructors2
        .where(
          (constructor) =>
              schemaConstructorChecker.hasAnnotationOfExact(constructor),
        )
        .toList();

    if (annotatedConstructors.length > 1) {
      throw ArgumentError(
        'Class ${element.name3} has multiple @SchemaConstructor annotations. '
        'Annotate exactly one constructor.',
      );
    }

    final selected = annotatedConstructors.isNotEmpty
        ? annotatedConstructors.single
        : element.constructors2.cast<ConstructorElement2?>().firstWhere(
            (constructor) => constructor?.name3 == 'new',
            orElse: () => null,
          );

    if (selected == null) {
      throw ArgumentError(
        'Class ${element.name3} does not have a default unnamed constructor. '
        'Annotate the intended constructor with @SchemaConstructor().',
      );
    }

    if (selected.isFactory) {
      throw ArgumentError(
        '${_constructorLabel(element, selected)} cannot be a factory constructor. '
        'Use a generative constructor for @Schemable classes.',
      );
    }

    return selected;
  }

  List<TypeProviderInfo> _readTypeProviders(
    ClassElement2 element,
    ConstantReader annotation,
  ) {
    final rawProviders = annotation.peek('useProviders')?.listValue ?? const [];
    final typeProviders = <TypeProviderInfo>[];
    final seenTargetTypes = <String, String>{};

    for (final rawProvider in rawProviders) {
      final providerType = rawProvider.toTypeValue();
      final providerElement = providerType?.element3;
      if (providerType == null || providerElement is! InterfaceElement2) {
        throw ArgumentError(
          'Invalid schema provider registration on ${element.name3}. '
          'Each `useProviders` entry must be a provider type.',
        );
      }

      final providerName = providerElement.name3;
      if (providerName == null) {
        throw ArgumentError(
          'Failed to resolve schema provider type for ${element.name3}.',
        );
      }

      if (providerElement is! ClassElement2 || providerElement.isAbstract) {
        throw ArgumentError(
          'Schema provider $providerName must be a concrete class and cannot be abstract.',
        );
      }

      final defaultConstructor = providerElement.constructors2
          .cast<ConstructorElement2?>()
          .firstWhere(
            (constructor) =>
                constructor?.name3 == 'new' &&
                constructor?.formalParameters.isEmpty == true,
            orElse: () => null,
          );

      if (defaultConstructor == null || !defaultConstructor.isConst) {
        throw ArgumentError(
          'Schema provider $providerName must declare a const unnamed constructor '
          'with no parameters.',
        );
      }

      final providerInterface = providerElement.allSupertypes
          .cast<InterfaceType?>()
          .firstWhere(
            (supertype) =>
                supertype?.element3.name3 == 'SchemaProvider' &&
                supertype?.typeArguments.isNotEmpty == true,
            orElse: () => null,
          );

      if (providerInterface == null) {
        throw ArgumentError(
          'Schema provider $providerName must implement SchemaProvider<T>.',
        );
      }

      final targetType = providerInterface.typeArguments.first;
      final targetTypeName = targetType.getDisplayString(
        withNullability: false,
      );
      final targetTypeKey = typeIdentityKey(targetType);
      _validateProviderTargetType(providerName, targetType);
      _validateProviderSchemaType(providerElement, providerName, targetType);

      final existingProvider = seenTargetTypes[targetTypeKey];
      if (existingProvider != null) {
        throw ArgumentError(
          'Schema providers $existingProvider and $providerName both handle '
          '$targetTypeName. Register only one provider per target type.',
        );
      }

      seenTargetTypes[targetTypeKey] = providerName;
      typeProviders.add(
        TypeProviderInfo(
          providerTypeName: providerName,
          targetType: targetType,
          accessor: _providerAccessorFor(element.library2, providerElement),
        ),
      );
    }

    return typeProviders;
  }

  String? _readOptionalString(ConstantReader annotation, String fieldName) {
    final reader = annotation.peek(fieldName);
    if (reader == null || reader.isNull) {
      return null;
    }
    return reader.stringValue;
  }

  CaseStyle _readCaseStyle(ConstantReader annotation) {
    final reader = annotation.peek('caseStyle');
    if (reader == null || reader.isNull) {
      return CaseStyle.none;
    }

    final index = reader.objectValue.getField('index')?.toIntValue();
    if (index == null || index < 0 || index >= CaseStyle.values.length) {
      return CaseStyle.none;
    }

    return CaseStyle.values[index];
  }

  void _validateAdditionalPropertiesField(
    ClassElement2 element,
    String fieldName,
    bool additionalProperties,
  ) {
    final field = element.fields2.cast<FieldElement2?>().firstWhere(
      (candidate) => candidate?.name3 == fieldName,
      orElse: () => null,
    );

    if (field == null) {
      throw ArgumentError(
        'additionalPropertiesField "$fieldName" not found in class ${element.name3}',
      );
    }

    if (!additionalProperties) {
      throw ArgumentError(
        'additionalProperties must be true when additionalPropertiesField is specified',
      );
    }

    final fieldType = field.type.getDisplayString();
    final isValidType = switch (fieldType) {
      String type when type.startsWith('Map<String,') => true,
      String type when type.startsWith('Map<String, dynamic>') => true,
      String type when type.startsWith('Map<String, Object?>') => true,
      _ => false,
    };

    if (!isValidType) {
      throw ArgumentError(
        'additionalPropertiesField "$fieldName" must be of type '
        'Map<String, dynamic> or Map<String, Object?>, got $fieldType',
      );
    }
  }

  void _validateProviderSchemaType(
    InterfaceElement2 providerElement,
    String providerName,
    DartType targetType,
  ) {
    final targetTypeName = targetType.getDisplayString(withNullability: false);
    final targetTypeKey = typeIdentityKey(targetType);
    final schemaGetter = providerElement.getters2
        .cast<GetterElement?>()
        .firstWhere((getter) => getter?.name3 == 'schema', orElse: () => null);

    if (schemaGetter == null) {
      throw ArgumentError(
        'Schema provider $providerName must declare a `schema` getter.',
      );
    }

    final schemaType = _ackSchemaInterfaceFor(schemaGetter.returnType);
    if (schemaType == null || schemaType.typeArguments.isEmpty) {
      throw ArgumentError(
        'Schema provider $providerName must return AckSchema<$targetTypeName> '
        'from `schema`.',
      );
    }

    final providedType = schemaType.typeArguments.first;
    final providedTypeName = providedType.getDisplayString(
      withNullability: false,
    );
    if (typeIdentityKey(providedType) != targetTypeKey) {
      throw ArgumentError(
        'Schema provider $providerName must return AckSchema<$targetTypeName> '
        'from `schema`, but returns AckSchema<$providedTypeName>.',
      );
    }
  }

  void _validateProviderTargetType(String providerName, DartType targetType) {
    final targetElement = targetType.element3;
    if (targetElement is! InterfaceElement2) {
      return;
    }

    if (firstSchemableAnnotationOf(targetElement) == null) {
      return;
    }

    final targetTypeName = targetType.getDisplayString(withNullability: false);
    throw ArgumentError(
      'Schema provider $providerName cannot target $targetTypeName because '
      '$targetTypeName already has a generated schema. Remove the provider '
      'registration or stop annotating $targetTypeName with @Schemable().',
    );
  }

  InterfaceType? _ackSchemaInterfaceFor(DartType type) {
    if (type is! InterfaceType) {
      return null;
    }

    if (type.element3.name3 == 'AckSchema' && type.typeArguments.isNotEmpty) {
      return type;
    }

    return type.allSupertypes.cast<InterfaceType?>().firstWhere(
      (supertype) =>
          supertype?.element3.name3 == 'AckSchema' &&
          supertype?.typeArguments.isNotEmpty == true,
      orElse: () => null,
    );
  }

  String _providerAccessorFor(
    LibraryElement2? currentLibrary,
    InterfaceElement2 providerElement,
  ) {
    final providerName = providerElement.name3;
    if (providerName == null) {
      throw ArgumentError('Failed to resolve provider element name.');
    }

    final prefix = importPrefixForElement(currentLibrary, providerElement);
    if (prefix == null) {
      return 'const $providerName()';
    }

    return 'const $prefix.$providerName()';
  }

  void _validateDiscriminatedTypeUsage(
    ClassElement2 element,
    String? discriminatedKey,
    String? discriminatedValue,
  ) {
    if (discriminatedKey != null && discriminatedValue != null) {
      throw ArgumentError(
        'Class ${element.name3} cannot have both discriminatedKey and '
        'discriminatedValue.',
      );
    }

    if (discriminatedKey != null && !element.isSealed) {
      throw ArgumentError(
        'discriminatedKey can only be used on sealed classes. '
        'Class ${element.name3} must be declared sealed.',
      );
    }

    if (discriminatedValue != null && element.isAbstract) {
      throw ArgumentError(
        'discriminatedValue can only be used on concrete classes. '
        'Class ${element.name3} is abstract.',
      );
    }
  }

  /// Builds discriminator relationships after all models have been analyzed.
  List<ModelInfo> buildDiscriminatorRelationships(
    List<ModelInfo> modelInfos,
    List<ClassElement2> elements,
  ) {
    final updatedModelInfos = <ModelInfo>[];
    final canonicalDiscriminatorKeysByBaseClass = <String, String>{};
    final elementsByName = <String, ClassElement2>{
      for (final element in elements)
        if (element.name3 != null) element.name3!: element,
    };

    final baseClasses = <ModelInfo>[];
    final subtypes = <ModelInfo>[];

    for (final modelInfo in modelInfos) {
      if (modelInfo.isFromSchemaVariable) {
        updatedModelInfos.add(modelInfo);
        continue;
      }

      if (modelInfo.isDiscriminatedBase) {
        baseClasses.add(modelInfo);
      } else if (modelInfo.isDiscriminatedSubtype) {
        subtypes.add(modelInfo);
      } else {
        updatedModelInfos.add(modelInfo);
      }
    }

    for (final baseClass in baseClasses) {
      final matchingSubtypeNames = <String, String>{};
      final matchingSubtypes = <ModelInfo>[];

      for (final subtype in subtypes) {
        final subtypeElement = elementsByName[subtype.className];
        if (subtypeElement == null) {
          throw ArgumentError(
            'Subtype class ${subtype.className} not found in annotated elements.',
          );
        }

        if (_isSubtypeOf(subtypeElement, baseClass.className)) {
          final discriminatorValue = subtype.discriminatorValue!;
          if (matchingSubtypeNames.containsKey(discriminatorValue)) {
            throw ArgumentError(
              'Duplicate discriminator value "$discriminatorValue" found in '
              '${subtype.className} and ${matchingSubtypeNames[discriminatorValue]}.',
            );
          }

          matchingSubtypeNames[discriminatorValue] = subtype.className;
          matchingSubtypes.add(subtype);
        }
      }

      if (matchingSubtypeNames.isEmpty) {
        throw ArgumentError(
          'Sealed discriminated root ${baseClass.className} has no annotated leaves.',
        );
      }

      final canonicalDiscriminatorKey = _canonicalDiscriminatorKey(
        baseClass,
        matchingSubtypes,
      );
      canonicalDiscriminatorKeysByBaseClass[baseClass.className] =
          canonicalDiscriminatorKey;

      updatedModelInfos.add(
        ModelInfo(
          className: baseClass.className,
          schemaClassName: baseClass.schemaClassName,
          description: baseClass.description,
          fields: baseClass.fields,
          additionalProperties: baseClass.additionalProperties,
          additionalPropertiesField: baseClass.additionalPropertiesField,
          typeProviders: baseClass.typeProviders,
          discriminatorKey: canonicalDiscriminatorKey,
          discriminatorValue: null,
          subtypeNames: matchingSubtypeNames,
        ),
      );
    }

    for (final subtype in subtypes) {
      String? parentDiscriminatorKey;
      String? parentBaseClassName;

      for (final baseClass in baseClasses) {
        final subtypeElement = elementsByName[subtype.className];
        if (subtypeElement == null) {
          throw ArgumentError(
            'Subtype class ${subtype.className} not found in annotated elements.',
          );
        }

        if (_isSubtypeOf(subtypeElement, baseClass.className)) {
          parentBaseClassName = baseClass.className;
          parentDiscriminatorKey =
              canonicalDiscriminatorKeysByBaseClass[baseClass.className] ??
              baseClass.discriminatorKey;
          break;
        }
      }

      if (parentDiscriminatorKey == null || parentBaseClassName == null) {
        throw ArgumentError(
          'Class ${subtype.className} declares discriminatedValue but does not '
          'extend a sealed @Schemable root in the same library.',
        );
      }

      updatedModelInfos.add(
        ModelInfo(
          className: subtype.className,
          schemaClassName: subtype.schemaClassName,
          description: subtype.description,
          fields: subtype.fields,
          additionalProperties: subtype.additionalProperties,
          additionalPropertiesField: subtype.additionalPropertiesField,
          typeProviders: subtype.typeProviders,
          discriminatorKey: parentDiscriminatorKey,
          discriminatorValue: subtype.discriminatorValue,
          subtypeNames: null,
          discriminatedBaseClassName: parentBaseClassName,
        ),
      );
    }

    return updatedModelInfos;
  }

  String _canonicalDiscriminatorKey(
    ModelInfo baseClass,
    List<ModelInfo> matchingSubtypes,
  ) {
    final declaredKey = baseClass.discriminatorKey!;
    final resolvedKeys =
        matchingSubtypes
            .map(
              (subtype) => _resolvedDiscriminatorJsonKey(subtype, declaredKey),
            )
            .toSet()
            .toList()
          ..sort();

    if (resolvedKeys.length != 1) {
      final formattedKeys = resolvedKeys.map((key) => '"$key"').join(', ');
      throw ArgumentError(
        'Discriminated root ${baseClass.className} resolves conflicting '
        'discriminator keys for "$declaredKey": $formattedKeys. Ensure all '
        'subtypes expose the same JSON key for the discriminator field.',
      );
    }

    return resolvedKeys.single;
  }

  String _resolvedDiscriminatorJsonKey(ModelInfo subtype, String declaredKey) {
    for (final field in subtype.fields) {
      if (field.jsonKey == declaredKey) {
        return declaredKey;
      }
    }

    for (final field in subtype.fields) {
      if (field.name == declaredKey) {
        return field.jsonKey;
      }
    }

    return declaredKey;
  }

  bool _isSubtypeOf(ClassElement2 element, String baseClassName) {
    return element.allSupertypes.any(
      (supertype) => supertype.element3.name3 == baseClassName,
    );
  }

  String _constructorLabel(
    ClassElement2 element,
    ConstructorElement2 constructor,
  ) {
    if (constructor.name3 == null || constructor.name3 == 'new') {
      return '${element.name3}()';
    }

    return '${element.name3}.${constructor.name3}()';
  }
}
