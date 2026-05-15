/// Returns whether [uri] is absolute and includes an authority component.
///
/// This intentionally checks for an authority component, not a host. Dart URI
/// values such as `file:///tmp/report.txt` have an authority component but no
/// host, and ACK treats them consistently on parse and encode.
bool isAbsoluteUriWithAuthority(Uri uri) => uri.hasScheme && uri.hasAuthority;
