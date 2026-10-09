import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:ack_benchmarks/adapters.dart';

// This worker is controlled by a separate VM-service client. It neither starts
// a service nor collects heap statistics. A heap census between replies is
// heap state, not allocated bytes per operation. Snapshot/reply work happens
// outside the reported CPU-sampling window, but can affect that heap state.
const _modes = {'validate', 'decode-only', 'decode+validate', 'clone'};
const _maxOperations = 100000000;
const _maxWarmupMilliseconds = 30000;

Object? _canonical(Object? value) => switch (value) {
  Map<String, Object?> map => {
    for (final key in map.keys.toList()..sort()) key: _canonical(map[key]),
  },
  List<Object?> list => list.map(_canonical).toList(),
  _ => value,
};

String _canonicalJson(Object? value) => jsonEncode(_canonical(value));

final class _Workload {
  _Workload({
    required this.validator,
    required this.inputs,
    required this.expectedValid,
    required this.mode,
  }) : encoded = inputs.map(jsonEncode).toList(growable: false);

  final PreparedValidator validator;
  final List<Object?> inputs;
  final List<bool> expectedValid;
  final List<String> encoded;
  final String mode;
  Object? _lastDecoded;

  bool get validates => mode == 'validate' || mode == 'decode+validate';

  // Select the operation once, before any measurement. The adapter itself
  // retains its actual parse result; only decode baselines retain this field.
  late final bool Function(int) operation = switch (mode) {
    'validate' => (index) => validator.validate(inputs[index]),
    'decode+validate' => (index) => validator.validate(
      jsonDecode(encoded[index]),
    ),
    'decode-only' => (index) {
      _lastDecoded = jsonDecode(encoded[index]);
      return true;
    },
    'clone' => (index) {
      _lastDecoded = jsonDecode(jsonEncode(inputs[index]));
      return true;
    },
    _ => throw StateError('Unexpected mode: $mode'),
  };

  Object? output() => validates ? validator.output() : _lastDecoded;

  Object? snapshot() => validates ? validator.snapshot() : _lastDecoded;

  // Full cycles preserve mixed-validity proportions; a partial final cycle
  // is also supported and included in the expected checksum.
  int expectedChecksum(int count) {
    if (!validates) return count;
    final cycle = expectedValid.fold<int>(
      0,
      (sum, valid) => sum + (valid ? 1 : 2),
    );
    var checksum = (count ~/ inputs.length) * cycle;
    for (var index = 0; index < count % inputs.length; index++) {
      checksum += expectedValid[index] ? 1 : 2;
    }
    return checksum;
  }

  int runOperations(int count) {
    final run = operation;
    final inputCount = inputs.length;
    var checksum = 0;
    var index = 0;
    for (var done = 0; done < count; done++) {
      checksum += run(index) ? 1 : 2;
      index++;
      if (index == inputCount) index = 0;
    }
    return checksum;
  }

  JsonObject preflight() {
    final run = operation;
    var validityChecks = 0;
    var modeChecks = 0;
    for (var index = 0; index < inputs.length; index++) {
      final input = inputs[index];
      final before = _canonicalJson(input);
      for (var repeat = 0; repeat < 2; repeat++) {
        // Retain the fresh decoded input during this untimed check so mutation
        // is detectable even when an adapter returns a separate parsed value.
        final validationInput = mode == 'decode+validate'
            ? jsonDecode(encoded[index])
            : input;
        final modeValid = mode == 'decode+validate'
            ? validator.validate(validationInput)
            : run(index);
        final expected = validates ? expectedValid[index] : true;
        if (modeValid != expected) {
          throw StateError('Incorrect mode validity at input $index.');
        }
        if (modeValid && _canonicalJson(output()) != before) {
          throw StateError('Mode changed output at input $index.');
        }
        if (_canonicalJson(input) != before ||
            _canonicalJson(validationInput) != before) {
          throw StateError('Mode mutated input $index.');
        }
        if (validates) validityChecks++;
        modeChecks++;
      }
    }
    return {'validityChecks': validityChecks, 'modeChecks': modeChecks};
  }

  JsonObject consumeSnapshot() {
    // Never include a potentially large output in the protocol. Consume it
    // after timing, while keeping the actual native/decoded result reachable.
    final bytes = utf8.encode(jsonEncode(snapshot()));
    var hash = 0x811c9dc5;
    for (final byte in bytes) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return {'sinkBytes': bytes.length, 'sinkHash': hash};
  }
}

_Workload _prepare(String path, String engine, String caseName, String mode) {
  // Do not retain the whole corpus graph in the idle control loop. Only the
  // selected schema's prepared adapter and this case's input vectors survive.
  final corpus = jsonDecode(File(path).readAsStringSync()) as JsonObject;
  final schemas = corpus['schemas'] as JsonObject;
  final cases = (corpus['cases'] as List<Object?>).cast<JsonObject>();
  final matches = cases.where((entry) => entry['name'] == caseName).toList();
  if (matches.length != 1) {
    throw ArgumentError('Expected one corpus case named "$caseName".');
  }
  final selected = matches.single;
  final entries = (selected['inputs'] as List<Object?>).cast<JsonObject>();
  if (entries.isEmpty) throw ArgumentError('Corpus case has no inputs.');
  return _Workload(
    validator: prepare(engine, schemas[selected['schema']] as JsonObject),
    inputs: [for (final entry in entries) entry['value']],
    expectedValid: [for (final entry in entries) entry['valid'] as bool],
    mode: mode,
  );
}

int _positiveInt(JsonObject command, String key, int maximum) {
  final value = command[key];
  if (value is! int || value < 1 || value > maximum) {
    throw FormatException('$key must be an integer from 1 to $maximum.');
  }
  return value;
}

JsonObject _result(
  String event,
  _Workload workload,
  int count,
  int checksum,
  int startMicros,
  int endMicros,
  Stopwatch timer,
) {
  final expected = workload.expectedChecksum(count);
  if (checksum != expected) {
    throw StateError('Timed checksum $checksum did not match $expected.');
  }
  return {
    'event': event,
    'operations': count,
    'count': count,
    'checksum': checksum,
    'expectedChecksum': expected,
    'startMicros': startMicros,
    'endMicros': endMicros,
    'elapsedMicros': timer.elapsedMicroseconds,
    'elapsedTicks': timer.elapsedTicks,
    'stopwatchFrequency': timer.frequency,
    ...workload.consumeSnapshot(),
  };
}

JsonObject _warmup(_Workload workload, int milliseconds) {
  var count = 0;
  var checksum = 0;
  final timer = Stopwatch()..start();
  final startMicros = Timeline.now;
  // Poll time between complete corpus cycles, not inside every operation.
  // Finishing a cycle can overshoot the requested wall-time target.
  do {
    checksum += workload.runOperations(workload.inputs.length);
    count += workload.inputs.length;
  } while (timer.elapsedMilliseconds < milliseconds);
  final endMicros = Timeline.now;
  timer.stop();
  return {
    ..._result(
      'warmup',
      workload,
      count,
      checksum,
      startMicros,
      endMicros,
      timer,
    ),
    'requestedMilliseconds': milliseconds,
  };
}

JsonObject _measure(_Workload workload, int operations) {
  final timer = Stopwatch()..start();
  final startMicros = Timeline.now;
  final checksum = workload.runOperations(operations);
  final endMicros = Timeline.now;
  timer.stop();
  return _result(
    'measure',
    workload,
    operations,
    checksum,
    startMicros,
    endMicros,
    timer,
  );
}

void _reply(JsonObject message) => stdout.writeln(jsonEncode(message));

/// Line protocol: warmup, measure, exit. Launch with an external VM service.
///
/// Usage: `profile_worker.dart <corpus.json> <engine> <case> <mode>`
/// The clone mode is JSON encode/decode round-trip cloning: it performs no
/// schema validation and does not supply ACK's immutable snapshot semantics.
Future<void> main(List<String> arguments) async {
  if (arguments.length != 4) {
    throw ArgumentError(
      'Usage: profile_worker.dart <corpus.json> <engine> <case> <mode>',
    );
  }
  final [path, engine, caseName, mode] = arguments;
  if (!engines.contains(engine) || engine == 'acanthis') {
    throw ArgumentError(
      'Use an admitted engine: ack, ack-json-schema, validart, json-schema. '
      'Acanthis remains excluded by the benchmark correctness gate.',
    );
  }
  if (!_modes.contains(mode)) {
    throw ArgumentError('Mode must be one of: ${_modes.join(', ')}.');
  }

  final workload = _prepare(path, engine, caseName, mode);
  final checks = workload.preflight();
  _reply({
    'event': 'ready',
    'protocolVersion': 1,
    'isolateId': Service.getIsolateId(Isolate.current),
    'engine': engine,
    'case': caseName,
    'mode': mode,
    'inputCount': workload.inputs.length,
    'runtime': Platform.version,
    'heapMeasurement': 'heap-state-only; not allocation bytes per operation',
    'cloneSemantics':
        'JSON round-trip; no validation or immutability guarantee',
    'maxOperations': _maxOperations,
    'maxWarmupMilliseconds': _maxWarmupMilliseconds,
    ...checks,
    ...workload.consumeSnapshot(),
  });

  // Awaiting a command leaves the selected inputs, schema and last result live
  // while the external client inspects heap state or samples the prior window.
  await for (final line
      in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.trim().isEmpty) continue;
    try {
      final decoded = jsonDecode(line);
      if (decoded is! JsonObject) {
        throw const FormatException('Command must be a JSON object.');
      }
      switch (decoded['command']) {
        case 'warmup':
          final milliseconds = _positiveInt(
            decoded,
            'milliseconds',
            _maxWarmupMilliseconds,
          );
          _reply(_warmup(workload, milliseconds));
        case 'measure':
          final operations = _positiveInt(
            decoded,
            'operations',
            _maxOperations,
          );
          _reply(_measure(workload, operations));
        case 'exit':
          _reply({'event': 'exit'});
          return;
        default:
          throw const FormatException('Use warmup, measure, or exit.');
      }
    } on FormatException catch (error) {
      _reply({'event': 'error', 'message': error.message});
    }
  }
}
