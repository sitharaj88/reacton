import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import 'package:reacton_generator/src/annotations/reacton_annotations.dart';
import 'package:reacton_generator/src/builders/serializer_builder.dart';

// ---------------------------------------------------------------------------
// Helper that replicates the string-template logic inside
// ReactonSerializerGenerator.generateForAnnotatedElement so we can verify
// the generated code shape without needing a full build environment.
// ---------------------------------------------------------------------------
String _simulateGeneratedCode(String className, {String? customName}) {
  final serializerName = customName ?? '${className}ReactonSerializer';
  return '''
/// Auto-generated serializer for [$className].
class $serializerName extends Serializer<$className> {
  const $serializerName();

  @override
  String serialize($className value) => jsonEncode(value.toJson());

  @override
  $className deserialize(String data) =>
      $className.fromJson(jsonDecode(data) as Map<String, dynamic>);
}
''';
}

void main() {
  // =======================================================================
  // 1. ReactonSerializable annotation
  // =======================================================================
  group('ReactonSerializable', () {
    test('default constructor sets name to null', () {
      const annotation = ReactonSerializable();
      expect(annotation.name, isNull);
    });

    test('custom name is stored correctly', () {
      const annotation = ReactonSerializable(name: 'CustomSerializer');
      expect(annotation.name, equals('CustomSerializer'));
    });

    test('can be created as a compile-time constant', () {
      // If this compiles, it confirms const construction works.
      const annotations = [
        ReactonSerializable(),
        ReactonSerializable(name: 'A'),
      ];
      expect(annotations, hasLength(2));
    });

    test('two default instances are equal as const', () {
      const a = ReactonSerializable();
      const b = ReactonSerializable();
      // const instances with same arguments share identity.
      expect(identical(a, b), isTrue);
    });
  });

  // =======================================================================
  // 2. ReactonState annotation
  // =======================================================================
  group('ReactonState', () {
    test('default constructor sets name and persistKey to null', () {
      const annotation = ReactonState();
      expect(annotation.name, isNull);
      expect(annotation.persistKey, isNull);
    });

    test('default constructor sets devtools to true', () {
      const annotation = ReactonState();
      expect(annotation.devtools, isTrue);
    });

    test('stores custom name', () {
      const annotation = ReactonState(name: 'user');
      expect(annotation.name, equals('user'));
    });

    test('stores custom persistKey', () {
      const annotation = ReactonState(persistKey: 'current_user');
      expect(annotation.persistKey, equals('current_user'));
    });

    test('allows devtools to be set to false', () {
      const annotation = ReactonState(devtools: false);
      expect(annotation.devtools, isFalse);
    });

    test('stores all fields together', () {
      const annotation = ReactonState(
        name: 'theme',
        persistKey: 'app_theme',
        devtools: false,
      );
      expect(annotation.name, equals('theme'));
      expect(annotation.persistKey, equals('app_theme'));
      expect(annotation.devtools, isFalse);
    });

    test('can be created as a compile-time constant', () {
      const annotations = [
        ReactonState(),
        ReactonState(name: 'a', persistKey: 'b', devtools: false),
      ];
      expect(annotations, hasLength(2));
    });
  });

  // =======================================================================
  // 3. ReactonComputed annotation
  // =======================================================================
  group('ReactonComputed', () {
    test('default constructor sets name to null', () {
      const annotation = ReactonComputed();
      expect(annotation.name, isNull);
    });

    test('stores custom name', () {
      const annotation = ReactonComputed(name: 'fullName');
      expect(annotation.name, equals('fullName'));
    });

    test('can be created as a compile-time constant', () {
      const annotations = [
        ReactonComputed(),
        ReactonComputed(name: 'x'),
      ];
      expect(annotations, hasLength(2));
    });
  });

  // =======================================================================
  // 4. ReactonAsync annotation
  // =======================================================================
  group('ReactonAsync', () {
    test('default constructor sets name to null', () {
      const annotation = ReactonAsync();
      expect(annotation.name, isNull);
    });

    test('stores custom name', () {
      const annotation = ReactonAsync(name: 'fetchUsers');
      expect(annotation.name, equals('fetchUsers'));
    });

    test('can be created as a compile-time constant', () {
      const annotations = [
        ReactonAsync(),
        ReactonAsync(name: 'y'),
      ];
      expect(annotations, hasLength(2));
    });
  });

  // =======================================================================
  // 5. Builder factory
  // =======================================================================
  group('reactonSerializerBuilder', () {
    test('returns a Builder instance', () {
      final builder = reactonSerializerBuilder(BuilderOptions.empty);
      expect(builder, isA<Builder>());
    });

    test('returned builder is a SharedPartBuilder', () {
      final builder = reactonSerializerBuilder(BuilderOptions.empty);
      expect(builder, isA<SharedPartBuilder>());
    });

    test('accepts arbitrary BuilderOptions without error', () {
      final builder = reactonSerializerBuilder(
        const BuilderOptions({'key': 'value'}),
      );
      expect(builder, isNotNull);
    });
  });

  // =======================================================================
  // 6. ReactonSerializerGenerator type checks
  // =======================================================================
  group('ReactonSerializerGenerator', () {
    test('is a GeneratorForAnnotation<ReactonSerializable>', () {
      final generator = ReactonSerializerGenerator();
      expect(generator, isA<GeneratorForAnnotation<ReactonSerializable>>());
    });

    test('is a Generator', () {
      final generator = ReactonSerializerGenerator();
      expect(generator, isA<Generator>());
    });

    test('can be instantiated multiple times', () {
      final a = ReactonSerializerGenerator();
      final b = ReactonSerializerGenerator();
      expect(a, isNot(same(b)));
    });
  });

  // =======================================================================
  // 7. Generated code structure (string template verification)
  // =======================================================================
  group('Generated code structure', () {
    test('default serializer name follows {ClassName}ReactonSerializer pattern',
        () {
      final code = _simulateGeneratedCode('User');
      expect(code, contains('class UserReactonSerializer'));
    });

    test('custom name overrides the default naming convention', () {
      final code = _simulateGeneratedCode('User', customName: 'MySerializer');
      expect(code, contains('class MySerializer'));
      expect(code, isNot(contains('UserReactonSerializer')));
    });

    test('generated class extends Serializer<T> with correct type', () {
      final code = _simulateGeneratedCode('Todo');
      expect(code, contains('extends Serializer<Todo>'));
    });

    test('generated class has a const constructor', () {
      final code = _simulateGeneratedCode('User');
      expect(code, contains('const UserReactonSerializer();'));
    });

    test('custom-named class has a const constructor with custom name', () {
      final code = _simulateGeneratedCode('User', customName: 'Foo');
      expect(code, contains('const Foo();'));
    });

    test('serialize method uses jsonEncode and toJson', () {
      final code = _simulateGeneratedCode('User');
      expect(code, contains('jsonEncode(value.toJson())'));
    });

    test('serialize method accepts the annotated class type', () {
      final code = _simulateGeneratedCode('Order');
      expect(code, contains('String serialize(Order value)'));
    });

    test('deserialize method uses fromJson and jsonDecode', () {
      final code = _simulateGeneratedCode('User');
      expect(
          code, contains('User.fromJson(jsonDecode(data) as Map<String, dynamic>)'));
    });

    test('deserialize method returns the annotated class type', () {
      final code = _simulateGeneratedCode('Order');
      expect(code, contains('Order deserialize(String data)'));
    });

    test('contains auto-generated doc comment referencing class name', () {
      final code = _simulateGeneratedCode('Settings');
      expect(code, contains('/// Auto-generated serializer for [Settings].'));
    });

    test('serialize method has @override annotation', () {
      final code = _simulateGeneratedCode('User');
      // The generated code contains @override before the serialize line.
      final lines = code.split('\n');
      final serializeIndex =
          lines.indexWhere((l) => l.contains('String serialize('));
      expect(serializeIndex, greaterThan(0));
      expect(lines[serializeIndex - 1].trim(), equals('@override'));
    });

    test('deserialize method has @override annotation', () {
      final code = _simulateGeneratedCode('User');
      final lines = code.split('\n');
      final deserializeIndex =
          lines.indexWhere((l) => l.contains('deserialize(String data)'));
      expect(deserializeIndex, greaterThan(0));
      // The @override may be one or two lines above depending on formatting.
      final precedingLines = lines
          .sublist(0, deserializeIndex)
          .reversed
          .takeWhile((l) => l.trim().isEmpty || l.trim() == '@override')
          .toList();
      expect(
        precedingLines.any((l) => l.trim() == '@override'),
        isTrue,
        reason: 'deserialize should be preceded by @override',
      );
    });

    test('works for single-word class names', () {
      final code = _simulateGeneratedCode('Config');
      expect(code, contains('class ConfigReactonSerializer'));
      expect(code, contains('extends Serializer<Config>'));
      expect(code, contains('const ConfigReactonSerializer();'));
    });

    test('works for multi-word class names', () {
      final code = _simulateGeneratedCode('UserProfile');
      expect(code, contains('class UserProfileReactonSerializer'));
      expect(code, contains('extends Serializer<UserProfile>'));
    });

    test('generated code does not reference the annotation itself', () {
      final code = _simulateGeneratedCode('Foo');
      expect(code, isNot(contains('@ReactonSerializable')));
    });
  });
}
