import 'package:ack_annotations/ack_annotations.dart' show AckModel, Schemable;
import 'package:ack_annotations/ack_generator_support.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:json_serializable/json_serializable.dart';
import 'package:source_gen/source_gen.dart';

import 'ack_runtime_type_helper.dart';

/// Delegates Ack-marked model classes to json_serializable.
///
/// Consumer builder options are ignored. The class configuration comes from
/// the Ack-owned marker (`includeIfNull: false`) plus the same fixed
/// generator default.
final class AckJsonSerializableGenerator extends Generator {
  AckJsonSerializableGenerator()
    : _delegate = JsonSerializableGenerator.withDefaultHelpers(const [
        AckRuntimeTypeHelper(),
      ], config: const JsonSerializable(includeIfNull: false));

  final JsonSerializableGenerator _delegate;

  static const _marker = TypeChecker.typeNamed(
    AckGeneratedJson,
    inPackage: 'ack_annotations',
  );
  static const _model = TypeChecker.typeNamed(
    AckModel,
    inPackage: 'ack_annotations',
  );
  static const _schemable = TypeChecker.typeNamed(
    Schemable,
    inPackage: 'ack_annotations',
  );

  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final requests = <({Element element, ConstantReader config})>[];
    final claimed = <Element>{};
    var hasFactoryModel = false;
    for (final item in library.annotatedWith(_marker)) {
      requests.add((
        element: item.element,
        config: item.annotation.read('config'),
      ));
      claimed.add(item.element.baseElement);
    }

    for (final element in library.classes) {
      final annotation =
          _model.firstAnnotationOfExact(element) ??
          _schemable.firstAnnotationOfExact(element);
      if (annotation == null) continue;
      // Factory models serialize through the class-first runtime functions.
      if (element.unnamedConstructor?.isFactory == true) {
        hasFactoryModel = true;
        continue;
      }
      final reader = ConstantReader(annotation);
      if (!element.isSealed) {
        _addModelRequest(requests, claimed, element, reader);
        continue;
      }
      for (final branch in library.classes) {
        if (branch == element || branch.isAbstract || !branch.isConstructable) {
          continue;
        }
        final isSubtype = branch.allSupertypes.any(
          (type) => type.element.baseElement == element.baseElement,
        );
        if (!isSubtype) continue;
        final branchAnnotation = _model.firstAnnotationOfExact(branch);
        _addModelRequest(
          requests,
          claimed,
          branch,
          branchAnnotation == null ? reader : ConstantReader(branchAnnotation),
        );
      }
    }

    if (requests.isEmpty) {
      // Keep the required JSON part available in factory-only libraries.
      return hasFactoryModel
          ? '// Factory model serialization is generated in the Ack model part.'
          : '';
    }

    final output = <String>[];
    for (final request in requests) {
      output.addAll(
        _delegate.generateForAnnotatedElement(
          request.element,
          request.config,
          buildStep,
        ),
      );
    }
    return output.join('\n\n');
  }

  void _addModelRequest(
    List<({Element element, ConstantReader config})> requests,
    Set<Element> claimed,
    ClassElement element,
    ConstantReader annotation,
  ) {
    if (!claimed.add(element.baseElement)) return;
    requests.add((
      element: element,
      config: annotation.read('jsonSerializable'),
    ));
  }
}
