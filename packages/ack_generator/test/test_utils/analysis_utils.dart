import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';

/// Utility to resolve Dart source into analyzable elements
Future<LibraryElement> resolveSource(
  String source, {
  Map<String, String>? additionalAssets,
}) async {
  final assets = {
    'test_pkg|lib/test.dart': source,
    if (additionalAssets != null) ...additionalAssets,
  };

  final resolver = await resolveAsset(
    AssetId('test_pkg', 'lib/test.dart'),
    (id) async {
      if (assets.containsKey(id.toString())) {
        return assets[id.toString()]!;
      }
      throw AssetNotFoundException(id);
    },
    // Provide a minimal logger
    logger: null,
  );

  return resolver.findLibraryByName('test') ?? 
         (throw StateError('Could not find library'));
}

/// Helper to get class element by name
ClassElement getClass(LibraryElement library, String name) {
  final type = library.getClass(name);
  if (type == null) {
    throw StateError('Could not find class $name in library');
  }
  return type;
}

/// Helper to get the first class in a library
ClassElement getFirstClass(LibraryElement library) {
  final classes = library.topLevelElements.whereType<ClassElement>();
  if (classes.isEmpty) {
    throw StateError('No classes found in library');
  }
  return classes.first;
}

/// Create a LibraryReader from source
Future<LibraryReader> createLibraryReader(String source) async {
  final library = await resolveSource(source);
  return LibraryReader(library);
}
