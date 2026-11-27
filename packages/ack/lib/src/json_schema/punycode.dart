part of '../schemas/schema.dart';

// RFC 3492 Punycode, used to convert IDNA A-labels (`xn--...`) to and from
// U-labels. It is a small, fixed algorithm, so Ack implements it directly
// instead of depending on a package.

const _punycodeBase = 36;
const _punycodeTMin = 1;
const _punycodeTMax = 26;
const _punycodeSkew = 38;
const _punycodeDamp = 700;
const _punycodeInitialBias = 72;
const _punycodeInitialN = 0x80;
const _punycodeMaxInt = 0x7fffffff;

int _punycodeAdapt(int delta, int numPoints, {required bool firstTime}) {
  var value = firstTime ? delta ~/ _punycodeDamp : delta ~/ 2;
  value += value ~/ numPoints;
  var k = 0;
  while (value > ((_punycodeBase - _punycodeTMin) * _punycodeTMax) ~/ 2) {
    value ~/= _punycodeBase - _punycodeTMin;
    k += _punycodeBase;
  }
  return k +
      (_punycodeBase - _punycodeTMin + 1) * value ~/ (value + _punycodeSkew);
}

int _punycodeThreshold(int k, int bias) {
  if (k <= bias) return _punycodeTMin;
  if (k >= bias + _punycodeTMax) return _punycodeTMax;
  return k - bias;
}

/// Decodes a Punycode string (without the `xn--` prefix).
///
/// Throws a [FormatException] for input that is not valid Punycode.
String _punycodeDecode(String input) {
  final delimiter = input.lastIndexOf('-');
  final output = <int>[];
  if (delimiter > 0) {
    for (final unit in input.codeUnits.take(delimiter)) {
      if (unit >= 0x80) {
        throw const FormatException('Non-basic code point before delimiter');
      }
      output.add(unit);
    }
  }
  var n = _punycodeInitialN;
  var i = 0;
  var bias = _punycodeInitialBias;
  var index = delimiter > 0 ? delimiter + 1 : 0;
  while (index < input.length) {
    final oldI = i;
    var w = 1;
    for (var k = _punycodeBase; ; k += _punycodeBase) {
      if (index >= input.length) {
        throw const FormatException('Truncated Punycode input');
      }
      final digit = _punycodeDigitValue(input.codeUnitAt(index++));
      if (digit >= _punycodeBase) {
        throw const FormatException('Invalid Punycode digit');
      }
      if (digit > (_punycodeMaxInt - i) ~/ w) {
        throw const FormatException('Punycode overflow');
      }
      i += digit * w;
      final t = _punycodeThreshold(k, bias);
      if (digit < t) break;
      if (w > _punycodeMaxInt ~/ (_punycodeBase - t)) {
        throw const FormatException('Punycode overflow');
      }
      w *= _punycodeBase - t;
    }
    final length = output.length + 1;
    bias = _punycodeAdapt(i - oldI, length, firstTime: oldI == 0);
    if (i ~/ length > _punycodeMaxInt - n) {
      throw const FormatException('Punycode overflow');
    }
    n += i ~/ length;
    i %= length;
    if (n > 0x10ffff || (n >= 0xd800 && n <= 0xdfff)) {
      throw const FormatException('Punycode decodes to an invalid code point');
    }
    output.insert(i++, n);
  }
  return String.fromCharCodes(output);
}

/// Encodes [input] as Punycode (without the `xn--` prefix).
String _punycodeEncode(String input) {
  final runes = input.runes.toList();
  final output = StringBuffer();
  for (final rune in runes) {
    if (rune < 0x80) output.writeCharCode(rune);
  }
  final basicCount = output.length;
  var handled = basicCount;
  if (basicCount > 0) output.write('-');
  var n = _punycodeInitialN;
  var delta = 0;
  var bias = _punycodeInitialBias;
  while (handled < runes.length) {
    var m = 0x10ffff + 1;
    for (final rune in runes) {
      if (rune >= n && rune < m) m = rune;
    }
    delta += (m - n) * (handled + 1);
    n = m;
    for (final rune in runes) {
      if (rune < n) delta++;
      if (rune != n) continue;
      var q = delta;
      for (var k = _punycodeBase; ; k += _punycodeBase) {
        final t = _punycodeThreshold(k, bias);
        if (q < t) break;
        output.writeCharCode(
          _punycodeDigitChar(t + (q - t) % (_punycodeBase - t)),
        );
        q = (q - t) ~/ (_punycodeBase - t);
      }
      output.writeCharCode(_punycodeDigitChar(q));
      bias = _punycodeAdapt(
        delta,
        handled + 1,
        firstTime: handled == basicCount,
      );
      delta = 0;
      handled++;
    }
    delta++;
    n++;
  }
  return output.toString();
}

int _punycodeDigitValue(int unit) {
  if (unit >= 0x30 && unit <= 0x39) return unit - 0x30 + 26; // 0-9
  if (unit >= 0x41 && unit <= 0x5a) return unit - 0x41; // A-Z
  if (unit >= 0x61 && unit <= 0x7a) return unit - 0x61; // a-z
  return _punycodeBase;
}

int _punycodeDigitChar(int digit) =>
    digit < 26 ? 0x61 + digit : 0x30 + digit - 26;
