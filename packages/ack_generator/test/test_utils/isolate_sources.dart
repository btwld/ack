import 'dart:typed_data';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';

final _isolateSources = _loadIsolateSources();

/// Loads immutable dependency bytes into a fresh filesystem for each case.
///
/// Visible package files must stay unchanged during the test isolate. A new
/// test invocation reloads them. Fixtures and generated output are never cached.
Future<TestReaderWriter> createTestReaderWriter() async {
  final sources = await _isolateSources;
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  for (final entry in sources.entries) {
    // Seed inputs without recording them as builder outputs. writeBytes copies
    // the bytes, so a case can also mutate its own read buffers independently.
    readerWriter.testing.writeBytes(entry.key, entry.value);
  }
  return readerWriter;
}

Future<Map<AssetId, Uint8List>> _loadIsolateSources() async {
  final readerWriter = TestReaderWriter();
  await readerWriter.testing.loadIsolateSources();
  return Map.unmodifiable({
    for (final id in readerWriter.testing.assets)
      id: readerWriter.testing.readBytes(id).asUnmodifiableView(),
  });
}
