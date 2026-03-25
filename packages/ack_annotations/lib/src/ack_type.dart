import 'package:meta/meta_meta.dart';

/// Annotation to generate extension types for validated data.
///
/// **Note:** This annotation should only be used on schema variables and getters,
/// not on classes. Use [@AckModel] to generate schemas from classes; if you need
/// extension types, define the schema in source and annotate it with [@AckType].
///
/// Can be applied to:
/// - Schema variable declarations (extracts types from schema AST)
/// - Schema getters (extracts types from returned schema)
///
/// Extension types wrap the validated [Map<String, dynamic>] returned by
/// schema validation, providing typed getters for each field without runtime
/// overhead.
///
/// ## Usage on Schema Variables
///
/// ### Object Schemas
/// ```dart
/// @AckType()
/// final userSchema = Ack.object({
///   'name': Ack.string(),
///   'age': Ack.integer(),
///   'email': Ack.string().optional().nullable(),
/// });
///
/// // Generated extension type:
/// extension type UserType(Map<String, Object?> _data)
///     implements Map<String, Object?> {
///   static UserType parse(Object? data) { ... }
///   static SchemaResult<UserType> safeParse(Object? data) { ... }
///
///   String get name => _data['name'] as String;
///   int get age => _data['age'] as int;
///   String? get email => _data['email'] as String?;
///
///   Map<String, Object?> toJson() => _data;
///   UserType copyWith({...}) { ... }
/// }
///
/// // Usage:
/// final user = UserType.parse({'name': 'Alice', 'age': 30});
/// print(user.name);  // Type-safe String access
/// print(user.age);   // Type-safe int access
/// ```
///
/// ### Primitive Schemas
///
/// Non-nullable primitive schemas (String, int, double, bool) generate
/// extension types that implement the underlying primitive type. These are
/// thin wrappers that add `parse()`/`safeParse()` factories while keeping the
/// primitive API available.
///
/// Nullable primitive schemas (for example, `Ack.string().nullable()`) do not
/// generate extension types.
///
/// ```dart
/// @AckType()
/// final passwordSchema = Ack.string().minLength(8);
///
/// // Generated extension type:
/// // extension type PasswordType(String _value) implements String { ... }
///
/// final password = PasswordType.parse('mySecurePassword123');
/// print(password.length);  // 19
/// ```
///
/// ### Literal Schemas
/// ```dart
/// @AckType()
/// final statusSchema = Ack.literal('active');
///
/// // Extension type is generated, wrapping the validated literal value:
/// final status = StatusType.parse('active'); // ✅ Valid
/// statusSchema.parse('inactive');            // ❌ Throws AckException
/// ```
///
/// ### EnumString Schemas
/// ```dart
/// @AckType()
/// final roleSchema = Ack.enumString(['admin', 'user', 'guest']);
///
/// // Extension type is generated:
/// final role = RoleType.parse('admin');
/// ```
///
/// ### EnumValues Schemas
/// ```dart
/// enum UserRole { admin, user, guest }
///
/// @AckType()
/// final roleSchema = Ack.enumValues(UserRole.values);
///
/// // Extension type is generated:
/// final role = RoleType.parse(UserRole.admin);
/// print(role.name); // 'admin'
/// ```
///
/// ## Benefits
///
/// - **Type Safety**: No runtime casts needed, compile-time type checking
/// - **Zero Cost**: Extension types have no runtime overhead
/// - **Ergonomics**: IDE autocomplete and type inference
/// - **Immutability**: Read-only view prevents accidental mutation
/// - **Validation Integrity**: Cannot bypass schema validation
///
/// ## Generated Features
///
/// For each annotated model, the generator creates:
/// - Type-safe getters for all fields
/// - `parse(data)` factory for validation + wrapping
/// - `safeParse(data)` for error handling
/// - `toJson()` for serialization
/// - `copyWith()` for immutable updates on object wrappers whose fields can be
///   safely reparsed from their public getter values
/// - Value equality (`==`, `hashCode`)
/// - `toString()` for debugging
///
/// ## Nested Types
///
/// When using schema variables, nested schemas automatically generate nested types:
/// ```dart
/// @ackType
/// final addressSchema = Ack.object({
///   'street': Ack.string(),
///   'city': Ack.string(),
/// });
///
/// @ackType
/// final userSchema = Ack.object({
///   'name': Ack.string(),
///   'address': addressSchema,  // Nested schema reference
/// });
///
/// final user = UserType.parse(data);
/// print(user.address.city);  // Type-safe chaining with AddressType
/// ```
///
/// ## Collections
///
/// Lists of primitives return `List<T>`, and lists of nested schemas return
/// `List<TType>`. Transformed element schemas are also supported:
/// ```dart
/// @ackType
/// final blogPostSchema = Ack.object({
///   'tags': Ack.list(Ack.string()),      // List<String>
///   'comments': Ack.list(commentSchema), // List<CommentType>
///   'links': Ack.list(Ack.uri()),        // List<Uri>
/// });
/// ```
///
/// ## Supported Schema Types
///
/// Extension types are generated for all supported schema types:
///
/// | Schema Type | Generated Extension Type |
/// |-------------|--------------------------|
/// | `Ack.object({...})` | `XType(Map<String, Object?>)` with field getters, conditional copyWith, toJson |
/// | `Ack.string()` | `XType(String)` implements String |
/// | `Ack.integer()` | `XType(int)` implements int |
/// | `Ack.double()` | `XType(double)` implements double |
/// | `Ack.boolean()` | `XType(bool)` implements bool |
/// | `Ack.list(T)` | `XType(List<T>)` implements List<T> |
/// | `Ack.literal('value')` | `XType(String)` implements String |
/// | `Ack.enumString([...])` | `XType(String)` implements String |
/// | `Ack.enumValues<T>([...])` | `XType(T)` implements T |
/// | `Ack.uri()` | `XType(Uri)` implements Uri |
/// | `Ack.date()` / `Ack.datetime()` | `XType(DateTime)` implements DateTime |
/// | `Ack.duration()` | `XType(Duration)` implements Duration |
/// | `Ack.<schema>().transform<T>(...)` | `XType(T)` implements T when `T` is explicit |
///
/// All extension types include `parse()` and `safeParse()` factory methods.
/// `toJson()` returns the validated representation value that the schema
/// produced. For transformed schemas, that means the transformed value
/// (for example `Uri`, `DateTime`, or a custom `T`), not the original wire
/// format.
///
/// ## Unsupported Schema Types
///
/// The following schema types are not currently supported for `@AckType`:
/// - **`Ack.any()`** - Not supported (defeats type safety purpose)
/// - **`Ack.anyOf()`** - Not supported (requires union types/sealed classes)
/// - **Transformed object schemas** - `Ack.object({...}).transform<T>()` and
///   `objectSchema.transform<T>()` are not supported
/// - **Transformed discriminated schemas** - `Ack.discriminated(...).transform<T>()`
///   and `discriminatedSchema.transform<T>()` are not supported
///
/// ## Method Chaining Support
///
/// Extension types work with most schema modifiers:
/// - ✅ **`.optional()`** - Supported, affects validation
/// - ⚠️ **`.nullable()`** - Extension type is NOT generated (see Limitations)
/// - ✅ **`.withDefault()`** - Supported, provides fallback value
/// - ✅ **`.refine()`** - Supported, adds custom validation
/// - ✅ **`.transform<T>()`** - Supported for non-object schemas when `T` is explicit
///
/// ```dart
/// @AckType()
/// final optionalAge = Ack.integer().min(0).optional(); // ✅ Works
///
/// @AckType()
/// final refinedAge = Ack.integer()
///   .min(0)
///   .refine((age) => age < 150, message: 'Too old'); // ✅ Works
///
/// @AckType()
/// final transformedLink = Ack.string()
///   .transform<Uri>((value) => Uri.parse(value!)); // ✅ Works
///
/// @AckType()
/// final directUri = Ack.uri(); // ✅ Works
///
/// final validatedOnly = Ack.string().uri(); // Still represents String
/// ```
///
/// ## Limitations
///
/// - **Class annotations**: `@AckType` is not supported on classes.
/// - **Cross-file schema references**: Direct imports, prefixed imports, and
///   re-exported schema refs are supported.
///   - ✅ Direct import: `'address': addressSchema` → getter returns `AddressType`
///   - ✅ Prefixed import: `'address': models.addressSchema` → getter returns
///     `models.AddressType`
///   - ✅ Re-export: `'address': addressSchema` through an export works
///   - Cross-file transformed refs require the transformed representation types
///     to be visible from the consuming library.
///   - Direct-import transformed refs may fail when a representation type name
///     collides with a different visible type in the consuming library.
///   - Source-qualified transformed representation types such as `dep.Color`
///     are not supported across library boundaries.
/// - **Nullable schema variables**: Extension types are not generated for schemas
///   marked with `.nullable()` because the representation is non-nullable.
///   - Use the schema directly for nullable validation.
/// - **Object wrappers with transformed-backed fields**: `copyWith()` is not
///   generated for object wrappers, including discriminated branches, when any
///   field is backed by `Ack.uri()`, `Ack.date()`, `Ack.datetime()`,
///   `Ack.duration()`, or `.transform<T>(...)`.
/// - **List element modifiers**: List element nullability from chained
///   modifiers may not be fully inferred:
///   - ✅ `Ack.list(Ack.string())` → `List<String>`
///   - ⚠️ `Ack.list(Ack.string().nullable())` → `List<String>` (element
///     nullability lost; expected `List<String?>`)
/// - **Explicit transform output required**: use `.transform<T>(...)`, not
///   `.transform(...)`, so the generator can infer the representation type.
/// - **Constraint-only string helpers stay String**: `Ack.string().uri()`,
///   `Ack.string().date()`, and `Ack.string().datetime()` validate format but do
///   not change the generated representation type.
/// - **Dart version**: Requires Dart 3.3+ for extension type support
///
/// See also: [AckModel], [AckField]
@Target({TargetKind.topLevelVariable, TargetKind.getter})
class AckType {
  /// Optional custom name for the generated extension type.
  ///
  /// If not provided, the type name is derived from the schema variable name:
  /// - "userSchema" → "UserType"
  /// - "passwordSchema" → "PasswordType"
  ///
  /// If provided, the custom name is used with "Type" suffix:
  /// - @AckType(name: 'CustomUser') → "CustomUserType"
  /// - @AckType(name: 'MyPassword') → "MyPasswordType"
  final String? name;

  /// Creates an annotation to generate extension types for validated data.
  ///
  /// The [name] parameter allows you to customize the generated type name.
  /// If omitted, the name is derived from the schema variable name.
  ///
  /// The value must be a valid Dart identifier (letters, numbers, underscores)
  /// and should omit the trailing "Type" suffix.
  ///
  /// Examples:
  /// ```dart
  /// @AckType()
  /// final passwordSchema = Ack.string().minLength(8);
  ///
  /// @AckType(name: 'CustomPassword')
  /// final customPasswordSchema = Ack.string().minLength(8);
  /// // Generates: extension type CustomPasswordType(String _value)
  /// ```
  const AckType({this.name});
}
