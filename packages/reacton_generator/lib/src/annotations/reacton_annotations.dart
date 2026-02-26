/// Annotate a class to auto-generate a Reacton serializer.
///
/// The class must have a `toJson()` method and a `fromJson()` constructor.
///
/// ```dart
/// @ReactonSerializable()
/// class User {
///   final String name;
///   final int age;
///
///   User({required this.name, required this.age});
///
///   factory User.fromJson(Map<String, dynamic> json) => User(
///     name: json['name'] as String,
///     age: json['age'] as int,
///   );
///
///   Map<String, dynamic> toJson() => {'name': name, 'age': age};
/// }
/// ```
///
/// Generated output (in `.reacton.g.dart`):
/// ```dart
/// class UserReactonSerializer extends Serializer<User> {
///   @override
///   String serialize(User value) => jsonEncode(value.toJson());
///   @override
///   User deserialize(String data) => User.fromJson(jsonDecode(data));
/// }
/// ```
class ReactonSerializable {
  /// Optional custom serializer name.
  final String? name;

  const ReactonSerializable({this.name});
}

/// Annotate a reacton declaration for static graph analysis.
///
/// This annotation is optional - reactons are detected automatically.
/// Use it to provide additional metadata for the graph analyzer.
///
/// ```dart
/// @ReactonState(name: 'user', persistKey: 'current_user')
/// final userReacton = reacton<User?>(null);
/// ```
class ReactonState {
  /// Debug name for the reacton.
  final String? name;

  /// Persistence key for auto-persistence.
  final String? persistKey;

  /// Whether this reacton should be included in DevTools.
  final bool devtools;

  const ReactonState({this.name, this.persistKey, this.devtools = true});
}

/// Annotate a computed reacton for static analysis.
class ReactonComputed {
  final String? name;
  const ReactonComputed({this.name});
}

/// Annotate an async reacton for static analysis.
class ReactonAsync {
  final String? name;
  const ReactonAsync({this.name});
}
