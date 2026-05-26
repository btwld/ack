# flutter_codec

Flutter value codecs built on ACK schemas.

Includes enum codecs and value codecs for `Color`, `Offset`, `Radius`,
`Alignment` / `AlignmentDirectional` / `AlignmentGeometry`, and
`EdgeInsets` / `EdgeInsetsDirectional` / `EdgeInsetsGeometry`, plus composite
painting codecs for borders, shadows, gradients, `TextStyle`, and
`BoxDecoration`.

`BoxDecoration.image` is currently deferred: decode accepts only missing or
`null` image values, and encode emits `"image": null`.
