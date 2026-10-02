// ignore: deprecated_member_use
import 'package:ack/annotations.dart' show AckCaseStyle, AckModel, Schemable;
import 'package:ack/ack_generator_support.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:json_serializable/json_serializable.dart';
import 'package:source_gen/source_gen.dart';

import 'ack_runtime_type_helper.dart';

/// Delegates Ack-marked model classes to json_serializable.
///
/// Consumer builder options are ignored. Ack owns the configuration: each
/// class gets the `JsonSerializable` constant from `json_configs.dart` that
/// matches its `caseStyle`, and generated schema-first models use `none`. The
/// Ack annotations carry no json_annotation types.
final class AckJsonSerializableGenerator extends Generator {
  AckJsonSerializableGenerator()
    : _delegate = JsonSerializableGenerator.withDefaultHelpers(const [
        AckRuntimeTypeHelper(),
      ], config: const JsonSerializable(includeIfNull: false));

  final JsonSerializableGenerator _delegate;

  static final _configs = AssetId(
    'ack_generator',
    'lib/src/json/json_configs.dart',
  );

  static const _marker = TypeChecker.typeNamed(
    AckGeneratedJson,
    inPackage: 'ack',
  );
  // ignore: deprecated_member_use
  static const _model = TypeChecker.typeNamed(AckModel, inPackage: 'ack');
  static const _schemable = TypeChecker.typeNamed(Schemable, inPackage: 'ack');

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    // A failed model phase leaves helpers this part would call undefined.
    if (!await buildStep.canRead(
      buildStep.inputId.changeExtension('.ack.dart'),
    )) {
      return '';
    }
    final requests = <({Element element, AckCaseStyle caseStyle})>[];
    final claimed = <Element>{};
    for (final item in library.annotatedWith(_marker)) {
      requests.add((element: item.element, caseStyle: AckCaseStyle.none));
      claimed.add(item.element.baseElement);
    }

    for (final element in library.classes) {
      final annotation =
          _model.firstAnnotationOfExact(element) ??
          _schemable.firstAnnotationOfExact(element);
      if (annotation == null) continue;
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
        final branchAnnotation =
            _model.firstAnnotationOfExact(branch) ??
            _schemable.firstAnnotationOfExact(branch);
        _addModelRequest(
          requests,
          claimed,
          branch,
          branchAnnotation == null ? reader : ConstantReader(branchAnnotation),
        );
      }
    }

    if (requests.isEmpty) return '';

    final configs = await buildStep.resolver.libraryFor(_configs);
    final output = <String>[];
    for (final request in requests) {
      final config = configs
          .getTopLevelVariable(request.caseStyle.name)!
          .computeConstantValue();
      output.addAll(
        _delegate.generateForAnnotatedElement(
          request.element,
          ConstantReader(config),
          buildStep,
        ),
      );
    }
    return output.join('\n\n');
  }

  void _addModelRequest(
    List<({Element element, AckCaseStyle caseStyle})> requests,
    Set<Element> claimed,
    ClassElement element,
    ConstantReader annotation,
  ) {
    if (!claimed.add(element.baseElement)) return;
    final index = annotation
        .read('caseStyle')
        .objectValue
        .getField('index')!
        .toIntValue()!;
    requests.add((element: element, caseStyle: AckCaseStyle.values[index]));
  }
}
