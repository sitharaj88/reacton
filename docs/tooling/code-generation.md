# Code Generation

The `reacton_generator` package provides build_runner generators for automatic serializer generation and static dependency graph analysis. Annotations mark classes and reacton declarations for processing.

## Setup

Add the generator and build_runner to your project:

```yaml
dependencies:
  reacton: ^0.1.0

dev_dependencies:
  reacton_generator: ^0.1.0
  build_runner: ^2.4.0
```

Configure `build.yaml` in your project root:

```yaml
targets:
  $default:
    builders:
      reacton_generator|reacton_serializer:
        enabled: true
      reacton_generator|reacton_graph_analyzer:
        enabled: true
```

Run the generator:

```bash
dart run build_runner build
```

Or for continuous development:

```bash
dart run build_runner watch
```

## Annotations

### @ReactonSerializable()

Annotate a class to auto-generate a `Serializer<T>` implementation. The class must have a `toJson()` method and a `fromJson()` factory constructor.

```dart
import 'package:reacton_generator/reacton_generator.dart';

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
```

**Generated output** (in `.reacton.g.dart`):

```dart
class UserReactonSerializer extends Serializer<User> {
  @override
  String serialize(User value) => jsonEncode(value.toJson());

  @override
  User deserialize(String data) => User.fromJson(jsonDecode(data));
}
```

**Usage with a persistent reacton:**

```dart
final userReacton = reacton<User?>(
  null,
  name: 'currentUser',
  options: ReactonOptions(
    persistKey: 'current_user',
    serializer: UserReactonSerializer(),
  ),
);
```

#### Optional `name` Parameter

Override the generated serializer class name:

```dart
@ReactonSerializable(name: 'CustomUserSerializer')
class User { ... }
```

Generates `CustomUserSerializer` instead of `UserReactonSerializer`.

### @ReactonState()

Annotate a reacton declaration to provide additional metadata for the graph analyzer and DevTools. This annotation is optional -- reactons are detected automatically by the graph analyzer.

```dart
@ReactonState(name: 'user', persistKey: 'current_user')
final userReacton = reacton<User?>(null);
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | `String?` | `null` | Debug name for the reacton |
| `persistKey` | `String?` | `null` | Persistence key for auto-persistence |
| `devtools` | `bool` | `true` | Whether to include in DevTools |

### @ReactonComputed()

Annotate a computed reacton for static analysis:

```dart
@ReactonComputed(name: 'filteredTodos')
final filteredTodosReacton = computed((read) {
  final todos = read(todosReacton);
  final filter = read(filterReacton);
  return todos.where((t) => t.matches(filter)).toList();
});
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | `String?` | `null` | Debug name for the computed reacton |

### @ReactonAsync()

Annotate an async reacton for static analysis:

```dart
@ReactonAsync(name: 'weather')
final weatherReacton = asyncReacton<Weather>((read) async {
  final city = read(selectedCityReacton);
  return await weatherApi.getWeather(city);
});
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | `String?` | `null` | Debug name for the async reacton |

## Graph Analyzer

The `ReactonGraphAnalyzerBuilder` is a build_runner builder that performs static analysis of all Dart files in `lib/`. It produces `.reacton_graph.json` files in the build cache.

### How It Works

1. Scans all `.dart` files in `lib/`
2. Parses the AST to find top-level variable declarations using `reacton()`, `computed()`, `asyncReacton()`, `selector()`, or `family()`
3. For each declaration, extracts the reacton name, type, kind, source file, and dependencies (by finding `read()` calls in the initializer)
4. Writes a `.reacton_graph.json` file for each source file that contains reacton declarations

### Output Format

Each `.reacton_graph.json` contains an array of `ReactonDeclaration` objects:

```json
[
  {
    "name": "filteredTodosReacton",
    "type": "dynamic",
    "reactonKind": "computed",
    "source": "lib/reactons/todos.dart",
    "dependencies": ["todosReacton", "filterReacton"]
  },
  {
    "name": "todosReacton",
    "type": "dynamic",
    "reactonKind": "reacton",
    "source": "lib/reactons/todos.dart",
    "dependencies": []
  }
]
```

### ReactonDeclaration Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | `String` | Variable name of the reacton |
| `type` | `String` | Dart type (from static analysis) |
| `reactonKind` | `String` | One of: `reacton`, `computed`, `asyncReacton`, `selector`, `family` |
| `source` | `String` | Source file path |
| `dependencies` | `List<String>` | Names of reactons read via `read()` calls |

### Consuming Graph Data

The graph JSON files are consumed by:

- **DevTools** -- The `reacton_devtools` extension uses graph data for visualization
- **CLI** -- The `reacton graph` command can use pre-analyzed graph data for faster results
- **VS Code Extension** -- Uses graph data for code lens, hover info, and the dependency graph panel

::: tip
The graph analyzer detects dependencies by finding `read(someReacton)` calls in the function body of `computed()` and `selector()` declarations. If you use indirect patterns (e.g., extracting the read call to a helper function), the analyzer may not detect all dependencies.
:::

## Complete Example

```dart
// lib/models/user.dart
import 'package:reacton_generator/reacton_generator.dart';

@ReactonSerializable()
class User {
  final String name;
  final String email;

  User({required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) => User(
    name: json['name'] as String,
    email: json['email'] as String,
  );

  Map<String, dynamic> toJson() => {'name': name, 'email': email};
}
```

```dart
// lib/reactons/user_reactons.dart
import 'package:reacton/reacton.dart';
import 'package:reacton_generator/reacton_generator.dart';
import '../models/user.dart';
import '../models/user.reacton.g.dart'; // generated

@ReactonState(persistKey: 'current_user')
final currentUserReacton = reacton<User?>(
  null,
  name: 'currentUser',
  options: ReactonOptions(
    persistKey: 'current_user',
    serializer: UserReactonSerializer(), // generated
  ),
);

@ReactonComputed()
final userDisplayNameReacton = computed((read) {
  final user = read(currentUserReacton);
  return user?.name ?? 'Guest';
}, name: 'userDisplayName');
```

After running `dart run build_runner build`, the generated serializer is ready to use and the graph analyzer has produced dependency metadata.

## What's Next

- [Lint Rules](./lint-rules) -- Catch anti-patterns at analysis time
- [DevTools](./devtools) -- Visualize the dependency graph at runtime
- [CLI](./cli) -- Use `reacton graph` to visualize from the command line
