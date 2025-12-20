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
/// ### Primitive Schemas (No Extension Type Generated)
///
/// For primitive schemas (String, int, double, bool), extension types are
/// **not generated**. This is a design decision because:
/// 1. They provide minimal value (no getters to generate)
/// 2. Users can use `schema.safeParse()` directly
/// 3. Reduces generated code bloat
///
/// ```dart
/// @AckType()
/// final passwordSchema = Ack.string().minLength(8);
///
/// // NO extension type is generated for primitive schemas.
/// // Use the schema directly:
/// final result = passwordSchema.safeParse('mySecurePassword123');
/// if (result.isOk) {
///   print(result.value.length);  // 19
/// }
/// ```
///
/// ### Literal Schemas (No Extension Type Generated)
/// ```dart
/// @AckType()
/// final statusSchema = Ack.literal('active');
///
/// // NO extension type is generated.
/// // Use the schema directly for validation:
/// final result = statusSchema.safeParse('active');  // ✅ Valid
/// statusSchema.parse('inactive');                   // ❌ Throws AckException
/// ```
///
/// ### EnumString Schemas (No Extension Type Generated)
/// ```dart
/// @AckType()
/// final roleSchema = Ack.enumString(['admin', 'user', 'guest']);
///
/// // NO extension type is generated.
/// // Use the schema directly:
/// final role = roleSchema.parse('admin');
/// ```
///
/// ### EnumValues Schemas (No Extension Type Generated)
/// ```dart
/// enum UserRole { admin, user, guest }
///
/// @AckType()
/// final roleSchema = Ack.enumValues(UserRole.values);
///
/// // NO extension type is generated.
/// // Use the schema directly:
/// final role = roleSchema.parse(UserRole.admin);
/// print(role.name);   // 'admin'
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
/// Extension types are **only generated for object schemas**:
/// - **Object schemas**: `Ack.object({...})` → `extension type XType(Map<String, Object?>)`
///
/// The following schema types are supported but **do not generate extension types**
/// (use the schema directly via `safeParse()`):
/// - **String schemas**: `Ack.string()`
/// - **Integer schemas**: `Ack.integer()`
/// - **Double schemas**: `Ack.double()`
/// - **Boolean schemas**: `Ack.boolean()`
/// - **List schemas**: `Ack.list(T)`
/// - **Literal schemas**: `Ack.literal('value')`
/// - **EnumString schemas**: `Ack.enumString([...])`
/// - **EnumValues schemas**: `Ack.enumValues<T>([...])`
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
