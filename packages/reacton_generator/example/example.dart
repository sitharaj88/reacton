import 'package:reacton_generator/reacton_generator.dart';

/// A model class annotated for automatic serializer generation.
///
/// Run `dart run build_runner build` to generate `example.reacton.g.dart`
/// containing a `UserReactonSerializer` class.
@ReactonSerializable()
class User {
  final String name;
  final int age;

  User({required this.name, required this.age});

  factory User.fromJson(Map<String, dynamic> json) => User(
        name: json['name'] as String,
        age: json['age'] as int,
      );

  Map<String, dynamic> toJson() => {'name': name, 'age': age};
}

/// Use @ReactonState to add metadata for static graph analysis.
/// The graph analyzer detects reacton declarations automatically,
/// but this annotation enables persistence and DevTools options.
@ReactonState(name: 'currentUser', persistKey: 'user_v1')
final userReacton = null; // placeholder; real usage would import reacton

/// Use @ReactonComputed for computed reacton metadata.
@ReactonComputed(name: 'userDisplay')
final userDisplayReacton = null; // placeholder

void main() {
  print('Reacton Generator - code generation for Reacton');
  print('');
  print('Annotations:');
  print('  @ReactonSerializable()  Auto-generate serializers');
  print('  @ReactonState()         Static graph analysis metadata');
  print('  @ReactonComputed()      Computed reacton metadata');
  print('  @ReactonAsync()         Async reacton metadata');
  print('');
  print('Run: dart run build_runner build');
}
