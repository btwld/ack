import 'dart:convert';
import 'dart:io';

import 'package:ack_benchmarks/adapters.dart';

JsonObject readObject(String path) =>
    jsonDecode(File(path).readAsStringSync()) as JsonObject;

Object? canonical(Object? value) => switch (value) {
  Map<String, Object?> map => {
    for (final key in map.keys.toList()..sort()) key: canonical(map[key]),
  },
  List<Object?> list => list.map(canonical).toList(),
  _ => value,
};

void main(List<String> arguments) {
  if (arguments.length != 2) {
    throw ArgumentError('Usage: worker <corpus.json> <job.json>');
  }
  final corpus = readObject(arguments[0]);
  final job = readObject(arguments[1]);
  final engine = job['engine'] as String;
  final schemas = corpus['schemas'] as JsonObject;
  final cases = (corpus['cases'] as List<Object?>).cast<JsonObject>();
  final validators = {
    for (final e in schemas.entries)
      e.key: prepare(engine, e.value as JsonObject),
  };
  var checks = 0;
  for (final c in cases) {
    final validator = validators[c['schema']]!;
    for (final entry in (c['inputs'] as List<Object?>).cast<JsonObject>()) {
      final input = entry['value'];
      final before = jsonEncode(canonical(input));
      for (var repetition = 0; repetition < 2; repetition++) {
        final valid = validator.validate(input);
        if (valid != entry['valid']) {
          throw StateError('$engine disagrees on ${c['name']}: $before');
        }
        if (valid && jsonEncode(canonical(validator.output())) != before) {
          throw StateError('$engine changed output on ${c['name']}');
        }
        if (jsonEncode(canonical(input)) != before) {
          throw StateError('$engine mutated input on ${c['name']}');
        }
        checks++;
      }
    }
  }

  final results = <JsonObject>[];
  if (job['checkOnly'] != true) {
    for (final name in (job['cases'] as List<Object?>).cast<String>()) {
      final c = cases.singleWhere((c) => c['name'] == name);
      final definition = schemas[c['schema']] as JsonObject;
      var validator = prepare(engine, definition);
      final entries = (c['inputs'] as List<Object?>).cast<JsonObject>();
      final inputs = [for (final e in entries) e['value']];
      final encoded = inputs.map(jsonEncode).toList();
      final phase = c['phase'] as String;
      final bool Function(int) operation = switch (phase) {
        'validate' => (i) => validator.validate(inputs[i]),
        'decode+validate' => (i) => validator.validate(jsonDecode(encoded[i])),
        'construct+validate' => (i) {
          validator = prepare(engine, definition);
          return validator.validate(inputs[i]);
        },
        _ => throw StateError('Unknown phase $phase'),
      };
      // One iteration is one payload, not one nested item. Full corpus cycles
      // keep mixed-validity ratios identical at every calibrated batch size.
      final expectedCycle = entries.fold<int>(
        0,
        (sum, e) => sum + (e['valid'] == true ? 1 : 2),
      );
      int batch(int cycles) {
        var checksum = 0;
        for (var cycle = 0; cycle < cycles; cycle++) {
          for (var i = 0; i < inputs.length; i++) {
            checksum += operation(i) ? 1 : 2;
          }
        }
        if (checksum != cycles * expectedCycle) {
          throw StateError('Invalid timed checksum for $engine / $name');
        }
        return checksum;
      }

      final sampleUs = (job['sampleMs'] as int) * 1000;
      final warmup = Stopwatch()..start();
      var cycles = 1;
      // Adaptive warmup: at least the requested wall time, then calibrate
      // using this same loop. Stopwatches are outside the per-operation loop.
      do {
        final timer = Stopwatch()..start();
        batch(cycles);
        timer.stop();
        if (timer.elapsedMicroseconds < sampleUs ~/ 2) cycles *= 2;
      } while (warmup.elapsedMilliseconds < (job['warmupMs'] as int));
      final samples = <JsonObject>[];
      var checksum = 0;
      for (var sample = 0; sample < (job['samples'] as int); sample++) {
        final timer = Stopwatch()..start();
        checksum += batch(cycles);
        timer.stop();
        samples.add({
          'iterations': cycles * inputs.length,
          'elapsedNs': timer.elapsedTicks * (1000000000 / timer.frequency),
        });
        // Meet the target even when JIT optimization continued after warmup.
        if (timer.elapsedMicroseconds < sampleUs ~/ 2) cycles *= 2;
      }
      results.add({
        'name': name,
        'schema': c['schema'],
        'phase': phase,
        'samples': samples,
        'checksum': checksum,
        'sinkBytes': utf8.encode(jsonEncode(validator.snapshot())).length,
      });
    }
  }
  stdout.writeln(
    jsonEncode({
      'engine': engine,
      'checks': checks,
      'runtime': Platform.version,
      'results': results,
    }),
  );
}
