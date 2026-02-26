import 'dart:async';

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';

import '../annotations/reacton_annotations.dart';

/// Builder factory for the serializer generator.
Builder reactonSerializerBuilder(BuilderOptions options) =>
    SharedPartBuilder([ReactonSerializerGenerator()], 'reacton');

/// Generates `Serializer<T>` implementations for classes annotated
/// with `@ReactonSerializable()`.
class ReactonSerializerGenerator
    extends GeneratorForAnnotation<ReactonSerializable> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@ReactonSerializable can only be applied to classes.',
        element: element,
      );
    }

    final className = element.name;
    final customName = annotation.peek('name')?.stringValue;
    final serializerName = customName ?? '${className}ReactonSerializer';

    // Verify the class has toJson() and fromJson()
    final hasToJson = element.methods.any((m) => m.name == 'toJson');
    final hasFromJson = element.constructors.any((c) => c.name == 'fromJson');

    if (!hasToJson) {
      throw InvalidGenerationSourceError(
        '@ReactonSerializable requires a `toJson()` method on $className.',
        element: element,
      );
    }

    if (!hasFromJson) {
      throw InvalidGenerationSourceError(
        '@ReactonSerializable requires a `fromJson` factory constructor on $className.',
        element: element,
      );
    }

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
}
