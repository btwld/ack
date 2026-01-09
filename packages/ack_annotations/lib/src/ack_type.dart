import 'package:meta/meta_meta.dart';

/// Annotation to generate extension types for validated data.
///
/// **Note:** This annotation should only be used on schema variables and getters,
/// not on classes. For classes, use [@AckModel] to generate the schema, then
/// use [@AckType] on the generated schema variable for extension types.
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
/// ```dart
/// @AckType()
/// final passwordSchema = Ack.string().minLength(8);
///
/// // Generated extension type:
/// extension type PasswordType(String _value) implements String {
///   static PasswordType parse(Object? data) { ... }
///   static SchemaResult<PasswordType> safeParse(Object? data) { ... }
/// }
///
/// // Usage - String methods work via implements:
/// final password = PasswordType.parse('mySecurePassword123');
/// print(password.length);        // 19
/// print(password.toUpperCase()); // 'MYSECUREPASSWORD123'
/// ```
///
/// ### Literal Schemas
/// ```dart
/// @AckType()
/// final statusSchema = Ack.literal('active');
///
/// // Generated:
/// extension type StatusType(String _value) implements String {
///   static StatusType parse(Object? data) { ... }
/// }
///
/// // Usage:
/// final status = StatusType.parse('active');  // ✅ Valid
/// print(status.toUpperCase());                // 'ACTIVE'
/// StatusType.parse('inactive');               // ❌ Throws AckException
/// ```
///
/// ### EnumString Schemas
/// ```dart
/// @AckType()
/// final roleSchema = Ack.enumString(['admin', 'user', 'guest']);
///
/// // Usage:
/// final role = RoleType.parse('admin');
/// print(role.contains('adm'));  // true - String methods work!
/// ```
///
/// ### EnumValues Schemas
/// ```dart
/// enum UserRole { admin, user, guest }
///
/// @AckType()
/// final roleSchema = Ack.enumValues(UserRole.values);
///
/// // Generated:
/// extension type RoleType(UserRole _value) implements UserRole {
///   static RoleType parse(Object? data) { ... }
/// }
///
/// // Usage:
/// final role = RoleType.parse(UserRole.admin);
/// print(role.name);   // 'admin' - Enum methods work!
/// print(role.index);  // 0
///
/// // Can parse from string or index too:
/// RoleType.parse('admin');  // ✅ Works
/// RoleType.parse(0);        // ✅ Works (index)
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
/// - `copyWith()` for immutable updates
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
/// Lists of primitives return `List<T>`, lists of nested schemas return lazy `Iterable<TType>`:
/// ```dart
/// @ackType
/// final blogPostSchema = Ack.object({
///   'tags': Ack.list(Ack.string()),      // List<String>
///   'comments': Ack.list(commentSchema), // Iterable<CommentType>
/// });
/// ```
///
/// ## Supported Schema Types
///
/// The following Ack schema types are currently supported:
/// - **Object schemas**: `Ack.object({...})` → `extension type XType(Map<String, Object?>)`
/// - **String schemas**: `Ack.string()` → `extension type XType(String)`
/// - **Integer schemas**: `Ack.integer()` → `extension type XType(int)`
/// - **Double schemas**: `Ack.double()` → `extension type XType(double)`
/// - **Boolean schemas**: `Ack.boolean()` → `extension type XType(bool)`
/// - **List schemas**: `Ack.list(T)` → `extension type XType(List<T>)`
/// - **Literal schemas**: `Ack.literal('value')` → `extension type XType(String)`
/// - **EnumString schemas**: `Ack.enumString([...])` → `extension type XType(String)`
/// - **EnumValues schemas**: `Ack.enumValues<T>([...])` → `extension type XType(T)`
///
/// ## Unsupported Schema Types
///
/// The following schema types are not currently supported for `@AckType`:
/// - **`Ack.any()`** - Not supported (defeats type safety purpose)
/// - **`Ack.anyOf()`** - Not supported (requires union types/sealed classes)
/// - **`Ack.discriminated()`** - Use @AckModel on discriminated classes instead
///
/// ## Method Chaining Support
///
/// Extension types work with most schema modifiers:
/// - ✅ **`.optional()`** - Supported, affects validation
/// - ✅ **`.nullable()`** - Supported, affects validation (extension type still wraps non-nullable value)
/// - ✅ **`.withDefault()`** - Supported, provides fallback value
/// - ✅ **`.refine()`** - Supported, adds custom validation
/// - ⚠️ **`.transform()`** - NOT recommended (changes output type, breaks extension type contract)
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
/// // @AckType()
/// // final transformed = Ack.string().transform((s) => s.length); // ❌ Don't use
/// //   → Extension type would wrap String, but transform returns int
/// ```
///
/// ## Limitations
///
/// - **Generic classes**: Cannot be used on generic classes
/// - **Discriminated base types**: Cannot be used on discriminated base types (use on subtypes instead)
/// - **Cross-file schema references**: Schema references must be in the same file
///   - ✅ Same file: `'address': addressSchema` → getter returns `AddressType`
///   - ❌ Cross-file: `'address': addressSchema` → getter returns `Map<String, Object?>`
/// - **Nullable primitives**: Extension types wrap non-nullable values even when schema is `.nullable()`
///   - The `.nullable()` modifier affects validation, not the extension type's representation
/// - **Transform modifier**: Not supported (changes output type)
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
