// Shared timing for scaling regressions.
double measure(Object? Function() action) {
  for (var i = 0; i < 3; i++) {
    action();
  }
  final samples = <double>[];
  for (var sample = 0; sample < 5; sample++) {
    final watch = Stopwatch()..start();
    var count = 0;
    do {
      action();
      count++;
    } while (watch.elapsedMilliseconds < 50);
    samples.add(watch.elapsedMicroseconds / count);
  }
  samples.sort();
  return samples[2];
}
