// Internal helpers shared by [textStyleCodec] and [strutStyleCodec] for
// unfolding Flutter's `packages/<pkg>/<family>` storage back to the
// user-supplied `(fontFamily, fontFamilyFallback, package)` triple.
//
// Flutter folds `package` into `fontFamily` at construction
// (`fontFamily = package == null ? fontFamily : 'packages/$package/$fontFamily'`)
// and stores the original `package` privately, so codecs have to recover
// the split heuristically when all referenced families share the same
// `packages/<pkg>/` prefix.

/// Unfolds Flutter's `packages/<pkg>/<family>` storage back to the
/// `(fontFamily, fontFamilyFallback, package)` triple when all referenced
/// families share the same prefix. Falls back to the stored (prefixed) form
/// when the prefix is missing or inconsistent.
///
/// A package is only recovered when the primary [family] is non-null. With a
/// null family the constructor would re-fold `package` into the literal string
/// `'packages/<pkg>/null'` (it interpolates the null family), corrupting the
/// round-trip; keeping the fallback verbatim with `package: null` reproduces
/// the original exactly because decode then performs no folding.
///
/// Note: a literal `fontFamily: 'packages/<pkg>/<x>'` supplied without a
/// `package:` argument is indistinguishable from the folded
/// `(fontFamily: '<x>', package: '<pkg>')` form (the original `_package` is
/// private and is compared by `TextStyle` equality). It is intentionally
/// interpreted as package-qualified — the common case — so such a literal
/// does not round-trip under `TextStyle` equality, though the resolved font
/// family string is preserved.
({String? family, List<String>? fallback, String? packageName})
unpackFontFamily(String? family, List<String>? fallback) {
  final pkg = _sharedPackagePrefix([if (family != null) family, ...?fallback]);
  if (pkg == null || family == null) {
    return (family: family, fallback: fallback, packageName: null);
  }

  final prefix = 'packages/$pkg/';
  String strip(String f) =>
      f.startsWith(prefix) ? f.substring(prefix.length) : f;
  return (
    family: strip(family),
    fallback: fallback?.map(strip).toList(),
    packageName: pkg,
  );
}

// Returns the package name shared by every `packages/<name>/<family>` entry
// in `families`, or null if any entry lacks the prefix or disagrees.
String? _sharedPackagePrefix(List<String> families) {
  const prefix = 'packages/';
  String? shared;
  for (final family in families) {
    if (!family.startsWith(prefix)) return null;

    final rest = family.substring(prefix.length);
    final separator = rest.indexOf('/');
    if (separator <= 0 || separator == rest.length - 1) return null;

    final name = rest.substring(0, separator);
    if (shared == null) {
      shared = name;
    } else if (shared != name) {
      return null;
    }
  }
  return shared;
}
