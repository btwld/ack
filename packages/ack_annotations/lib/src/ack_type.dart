import 'package:meta/meta_meta.dart';

/// Annotation to generate extension types for validated data.
///
/// Can be applied to:
/// - Classes annotated with [@AckModel] (extracts types from class fields)
/// - Schema variable declarations (extracts types from schema AST)
/// - Schema getters (extracts types from returned schema)
///
/// Extension types wrap the validated [Map<String, dynamic>] returned by
/// schema validation, providing typed getters for each field without runtime
/// overhead.
///
/// ## Usage on Classes
///
/// ```dart
/// @AckModel()
/// @AckType()
/// class User {
///   final String name;
///   final int age;
///   final String? email;
/// }
/// ```
///
/// ## Usage on Schema Variables (Preferred)
///
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
/// Extension types automatically wrap nested custom types:
/// ```dart
/// @AckModel() @AckType()
/// class Address {
///   final String street;
///   final String city;
/// }
///
/// @AckModel() @AckType()
/// class User {
///   final String name;
///   final Address address;  // Returns AddressType
/// }
///
/// final user = UserType.parse(data);
/// print(user.address.city);  // Type-safe chaining
/// ```
///
/// ## Collections
///
/// Lists of primitives return `List<T>`, lists of objects return lazy `Iterable<TType>`:
/// ```dart
/// @AckModel() @AckType()
/// class BlogPost {
///   final List<String> tags;        // List<String>
///   final List<Comment> comments;   // Iterable<CommentType>
/// }
/// ```
///
/// ## Limitations
///
/// - **Generic classes**: Cannot be used on generic classes
/// - **Discriminated base types**: Cannot be used on discriminated base types (use on subtypes instead)
/// - **Cross-file schema references**: Schema references must be in the same file
///   - ✅ Same file: `'address': addressSchema` → getter returns `AddressType`
///   - ❌ Cross-file: `'address': addressSchema` → getter returns `Map<String, Object?>`
/// - **Dart version**: Requires Dart 3.3+ for extension type support
/// - **Schema types**: Currently only `Ack.object({...})` schemas supported
///   - Primitive schemas (Ack.string(), Ack.integer()) not yet supported
///
/// See also: [AckModel], [AckField]
@Target({TargetKind.classType, TargetKind.topLevelVariable, TargetKind.getter})
class AckType {
  /// Creates an annotation to generate extension types for validated data.
  const AckType();
}
