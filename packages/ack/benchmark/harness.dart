/// Shared timing for the files in this directory.
///
/// JIT numbers drift with warmup, so measure an AOT build:
///
/// ```sh
/// dart compile exe benchmark/<name>.dart -o build/<name>
/// build/<name>
/// ```
library;

const draft = 'https://json-schema.org/draft/2020-12/schema';

/// Throws when a benchmark case does not succeed, so a failing case cannot be
/// timed as if it were the success path.
void check(String name, bool ok) {
  if (!ok) throw StateError('$name did not validate');
}

/// Warms up for 300 ms, then reports the best and median of 15 samples of
/// at least 50 ms each.
void report(String name, Object? Function() body) {
  Object? sink;
  final warmup = Stopwatch()..start();
  var batch = 1;
  while (warmup.elapsedMilliseconds < 300) {
    for (var i = 0; i < batch; i++) {
      sink = body();
    }
    batch *= 2;
  }
  final calibrate = Stopwatch()..start();
  var perSample = 0;
  while (calibrate.elapsedMilliseconds < 50) {
    sink = body();
    perSample++;
  }
  final samples = <double>[];
  for (var s = 0; s < 15; s++) {
    final watch = Stopwatch()..start();
    for (var i = 0; i < perSample; i++) {
      sink = body();
    }
    samples.add(watch.elapsedMicroseconds / perSample);
  }
  samples.sort();
  if (identical(sink, _never)) print('');
  print(
    '  ${name.padRight(36)} best ${_format(samples.first).padLeft(10)}'
    '   median ${_format(samples[samples.length ~/ 2]).padLeft(10)}',
  );
}

final _never = Object();

String _format(double us) => us >= 1000
    ? '${(us / 1000).toStringAsFixed(2)} ms'
    : '${us.toStringAsFixed(2)} µs';
