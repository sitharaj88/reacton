import 'dart:convert';

/// Interface for serializing/deserializing reacton values for persistence.
///
/// Implement this for custom types to enable auto-persistence.
///
/// ```dart
/// class UserSerializer implements Serializer<User> {
///   @override
///   String serialize(User value) => jsonEncode(value.toJson());
///
///   @override
///   User deserialize(String data) => User.fromJson(jsonDecode(data));
/// }
/// ```
abstract class Serializer<T> {
  /// Serialize a value to a string for storage.
  String serialize(T value);

  /// Deserialize a string back to the original value.
  T deserialize(String data);
}

/// Built-in JSON serializer for types that support [toJson()].
class JsonSerializer<T> implements Serializer<T> {
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;

  const JsonSerializer({required this.fromJson, required this.toJson});

  @override
  String serialize(T value) => jsonEncode(toJson(value));

  @override
  T deserialize(String data) => fromJson(jsonDecode(data) as Map<String, dynamic>);
}

/// Serializer for primitive types (int, double, String, bool).
class PrimitiveSerializer<T> implements Serializer<T> {
  const PrimitiveSerializer();

  @override
  String serialize(T value) => jsonEncode(value);

  @override
  T deserialize(String data) => jsonDecode(data) as T;
}

/// Serializer for enum values.
class EnumSerializer<T extends Enum> implements Serializer<T> {
  final List<T> values;

  const EnumSerializer(this.values);

  @override
  String serialize(T value) => value.name;

  @override
  T deserialize(String data) => values.byName(data);
}

/// Serializer for List types.
class ListSerializer<T> implements Serializer<List<T>> {
  final Serializer<T> itemSerializer;

  const ListSerializer(this.itemSerializer);

  @override
  String serialize(List<T> value) {
    final items = value.map((e) => itemSerializer.serialize(e)).toList();
    return jsonEncode(items);
  }

  @override
  List<T> deserialize(String data) {
    final items = jsonDecode(data) as List;
    return items.map((e) => itemSerializer.deserialize(e.toString())).toList();
  }
}
