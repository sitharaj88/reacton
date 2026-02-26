# Migrating from GetX

A side-by-side guide for migrating from GetX to Reacton. GetX bundles state management, routing, and dependency injection into one package. This guide focuses on the state management layer; routing and DI are out of scope.

## Concept Mapping

| GetX | Reacton | Notes |
|------|---------|-------|
| `var count = 0.obs` | `reacton(0)` | Simple writable state |
| `Rx<T>` / `RxString`, `RxInt` | `reacton<T>()` | Single generic API for all types |
| `Obx(() => ...)` | `ReactonBuilder` / `context.watch()` | Reactive widget rebuild |
| `GetxController` | `ReactonModule` | No base class for simple state |
| `Get.put()` / `Get.find()` | `context.read()` | Read without subscribing |
| `GetBuilder<T>` | `ReactonConsumer` | Multi-reacton builder |
| `ever()` | `createEffect()` | React to state changes |
| `once()` | `createEffect()` + guard | Fire-once side effect |
| `debounce()` | `Debouncer` | Debounced state changes |
| `interval()` | `Throttler` | Throttled state changes |
| `GetConnect` | `asyncReacton` + `QueryReacton` | Declarative async data |
| `Get.lazyPut()` | Top-level `reacton()` | Lazy by default |
| `StateMixin<T>` | `asyncReacton<T>()` | Loading / success / error states |
| `GetView<T>` | `StatelessWidget` | No special base class needed |

## Side-by-Side Examples

### Simple State (Obs / Rx)

**GetX:**

```dart
class CounterController extends GetxController {
  var count = 0.obs;
  void increment() => count++;
}

// Register:
Get.put(CounterController());

// In widget:
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CounterController>();
    return Obx(() => Text('${ctrl.count}'));
  }
}

// Modify:
Get.find<CounterController>().increment();
```

**Reacton:**

```dart
final counterReacton = reacton(0, name: 'counter');

// In widget:
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.watch(counterReacton);
    return Text('$count');
  }
}

// Modify:
context.update(counterReacton, (c) => c + 1);
```

::: tip
Reacton does not require a controller class for simple state. Declare a top-level `reacton()` and use it directly. No registration step, no `Get.put()`, no `Get.find()`.
:::

### Reactive Widgets (Obx vs ReactonBuilder)

**GetX:**

```dart
Obx(() => Text('${controller.firstName} ${controller.lastName}'));
```

**Reacton:**

```dart
// Option A: context.watch (preferred)
Builder(builder: (context) {
  final first = context.watch(firstNameReacton);
  final last = context.watch(lastNameReacton);
  return Text('$first $last');
});

// Option B: ReactonBuilder
ReactonBuilder(
  reacton: fullNameReacton,
  builder: (context, fullName) => Text(fullName),
);
```

### GetxController with Business Logic

**GetX:**

```dart
class TodoController extends GetxController {
  var todos = <Todo>[].obs;
  var filter = TodoFilter.all.obs;

  List<Todo> get filteredTodos {
    return switch (filter.value) {
      TodoFilter.all => todos,
      TodoFilter.active => todos.where((t) => !t.done).toList(),
      TodoFilter.done => todos.where((t) => t.done).toList(),
    };
  }

  void add(String title) {
    todos.add(Todo(title: title));
  }

  void toggle(String id) {
    final idx = todos.indexWhere((t) => t.id == id);
    todos[idx] = todos[idx].copyWith(done: !todos[idx].done);
  }

  @override
  void onInit() {
    super.onInit();
    ever(filter, (_) => update());
  }
}
```

**Reacton:**

```dart
final todosReacton = reacton<List<Todo>>([], name: 'todos');
final filterReacton = reacton(TodoFilter.all, name: 'filter');

final filteredTodosReacton = computed((read) {
  final todos = read(todosReacton);
  final filter = read(filterReacton);
  return switch (filter) {
    TodoFilter.all => todos,
    TodoFilter.active => todos.where((t) => !t.done).toList(),
    TodoFilter.done => todos.where((t) => t.done).toList(),
  };
}, name: 'filteredTodos');

// In widget or callback:
context.update(todosReacton, (todos) => [...todos, Todo(title: title)]);

context.update(todosReacton, (todos) => todos.map((t) {
  if (t.id == id) return t.copyWith(done: !t.done);
  return t;
}).toList());
```

::: tip
Reacton's `computed()` automatically tracks dependencies. There is no need for `ever()` to manually wire up change listeners between observables -- the dependency graph handles it.
:::

### Workers: ever, once, debounce, interval

**GetX:**

```dart
class SearchController extends GetxController {
  var query = ''.obs;
  var results = <Result>[].obs;

  @override
  void onInit() {
    super.onInit();

    // React to every change
    ever(query, (q) => print('Query changed: $q'));

    // React only once
    once(query, (q) => print('First query: $q'));

    // Debounced search
    debounce(query, (q) async {
      results.value = await SearchApi.search(q);
    }, time: Duration(milliseconds: 300));

    // Throttled analytics
    interval(query, (q) {
      Analytics.track('search', {'query': q});
    }, time: Duration(seconds: 2));
  }
}
```

**Reacton:**

```dart
final queryReacton = reacton('', name: 'query');
final resultsReacton = reacton<List<Result>>([], name: 'results');

// React to every change
final logEffect = createEffect(
  (read) => read(queryReacton),
  effect: (query) => print('Query changed: $query'),
);

// React only once
var _hasFired = false;
final onceEffect = createEffect(
  (read) => read(queryReacton),
  effect: (query) {
    if (!_hasFired && query.isNotEmpty) {
      _hasFired = true;
      print('First query: $query');
    }
  },
);

// Debounced search
final debouncedSearch = Debouncer<String>(
  duration: Duration(milliseconds: 300),
  onValue: (query) async {
    final data = await SearchApi.search(query);
    store.set(resultsReacton, data);
  },
);
// Wire up: createEffect((read) => read(queryReacton), effect: debouncedSearch.call);

// Throttled analytics
final throttledAnalytics = Throttler<String>(
  duration: Duration(seconds: 2),
  onValue: (query) => Analytics.track('search', {'query': query}),
);
```

### GetConnect / API Calls

**GetX:**

```dart
class UserProvider extends GetConnect {
  Future<Response<User>> getUser(String id) => get('/users/$id');
}

class UserController extends GetxController with StateMixin<User> {
  final UserProvider provider;
  UserController(this.provider);

  void fetchUser(String id) async {
    change(null, status: RxStatus.loading());
    final response = await provider.getUser(id);
    if (response.hasError) {
      change(null, status: RxStatus.error(response.statusText));
    } else {
      change(response.body, status: RxStatus.success());
    }
  }
}

// In widget:
controller.obx(
  (user) => Text(user!.name),
  onLoading: CircularProgressIndicator(),
  onError: (error) => Text('Error: $error'),
);
```

**Reacton:**

```dart
final userIdReacton = reacton<String?>(null, name: 'userId');

final userReacton = asyncReacton<User>((read) async {
  final id = read(userIdReacton);
  if (id == null) throw StateError('No user ID');
  return await api.getUser(id);
}, name: 'user');

// In widget:
final user = context.watch(userReacton);
return user.when(
  loading: () => CircularProgressIndicator(),
  data: (u) => Text(u.name),
  error: (e, _) => Text('Error: $e'),
);
```

::: tip
With `asyncReacton`, loading/error/data states are handled automatically. No `StateMixin`, no manual `change()` calls.
:::

### Dependency Injection: Get.put / Get.find

**GetX:**

```dart
// Registration
Get.put(AuthService());
Get.lazyPut(() => UserRepository(Get.find<AuthService>()));

// Usage
final authService = Get.find<AuthService>();
```

**Reacton:**

```dart
// Reactons are globally declared — no registration step
final authTokenReacton = reacton<String?>(null, name: 'authToken');

// Modules group related reactons
class AuthModule extends ReactonModule {
  @override
  List<ReactonRef> get reactons => [authTokenReacton];

  @override
  void onInit(ReactonStore store) {
    // Initialization logic
  }
}

// Usage in widgets
final token = context.read(authTokenReacton);
```

### GetBuilder (Manual Update)

**GetX:**

```dart
class ProfileController extends GetxController {
  String name = '';
  void updateName(String n) {
    name = n;
    update(); // Manual trigger
  }
}

GetBuilder<ProfileController>(
  builder: (ctrl) => Text(ctrl.name),
);
```

**Reacton:**

```dart
final nameReacton = reacton('', name: 'name');

// In widget:
ReactonConsumer(
  builder: (context) {
    final name = context.watch(nameReacton);
    return Text(name);
  },
);

// Modify:
context.set(nameReacton, 'New Name');
```

## Full Migration Example

Below is a complete GetX feature (a notes list with search) migrated to Reacton.

### Before (GetX)

```dart
// ---------- note_controller.dart ----------
class NoteController extends GetxController {
  var notes = <Note>[].obs;
  var searchQuery = ''.obs;

  List<Note> get filteredNotes {
    if (searchQuery.value.isEmpty) return notes;
    return notes
        .where((n) => n.title.toLowerCase().contains(searchQuery.value.toLowerCase()))
        .toList();
  }

  void addNote(Note note) => notes.add(note);

  void deleteNote(String id) => notes.removeWhere((n) => n.id == id);

  @override
  void onInit() {
    super.onInit();
    ever(notes, (_) => _saveToStorage());
  }

  Future<void> _saveToStorage() async {
    final data = notes.map((n) => n.toJson()).toList();
    await GetStorage().write('notes', data);
  }
}

// ---------- notes_page.dart ----------
class NotesPage extends GetView<NoteController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              onChanged: (v) => controller.searchQuery.value = v,
              decoration: InputDecoration(hintText: 'Search...'),
            ),
          ),
        ),
      ),
      body: Obx(() {
        final notes = controller.filteredNotes;
        return ListView.builder(
          itemCount: notes.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(notes[i].title),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => controller.deleteNote(notes[i].id),
            ),
          ),
        );
      }),
    );
  }
}
```

### After (Reacton)

```dart
// ---------- note_reactons.dart ----------
final notesReacton = reacton<List<Note>>([], name: 'notes');
final searchQueryReacton = reacton('', name: 'searchQuery');

final filteredNotesReacton = computed((read) {
  final notes = read(notesReacton);
  final query = read(searchQueryReacton);
  if (query.isEmpty) return notes;
  return notes
      .where((n) => n.title.toLowerCase().contains(query.toLowerCase()))
      .toList();
}, name: 'filteredNotes');

// Persist notes on every change
final persistEffect = createEffect(
  (read) => read(notesReacton),
  effect: (notes) async {
    final data = notes.map((n) => n.toJson()).toList();
    await storage.write('notes', jsonEncode(data));
  },
);

// ---------- notes_page.dart ----------
class NotesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              onChanged: (v) => context.set(searchQueryReacton, v),
              decoration: InputDecoration(hintText: 'Search...'),
            ),
          ),
        ),
      ),
      body: Builder(builder: (context) {
        final notes = context.watch(filteredNotesReacton);
        return ListView.builder(
          itemCount: notes.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(notes[i].title),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => context.update(
                notesReacton,
                (list) => list.where((n) => n.id != notes[i].id).toList(),
              ),
            ),
          ),
        );
      }),
    );
  }
}
```

## Testing Migration

**GetX:**

```dart
test('adds a note', () {
  final controller = NoteController();
  controller.addNote(Note(id: '1', title: 'Test'));
  expect(controller.notes.length, 1);
});
```

**Reacton:**

```dart
test('adds a note', () {
  final store = TestReactonStore();
  store.update(notesReacton, (notes) => [...notes, Note(id: '1', title: 'Test')]);
  expect(store.get(notesReacton).length, 1);
});
```

## Migration Checklist

- [ ] Replace `GetMaterialApp` with `ReactonScope` wrapping `MaterialApp`
- [ ] Replace `.obs` variables with `reacton()` declarations
- [ ] Replace `Obx(() => ...)` with `context.watch()` or `ReactonBuilder`
- [ ] Replace `GetxController` classes with top-level reactons and `ReactonModule`
- [ ] Replace `Get.put()` / `Get.find()` with `context.read()` / `context.watch()`
- [ ] Replace `GetBuilder` with `ReactonConsumer`
- [ ] Replace `ever()` with `createEffect()`
- [ ] Replace `debounce()` with `Debouncer`
- [ ] Replace `interval()` with `Throttler`
- [ ] Replace `GetConnect` / `StateMixin` with `asyncReacton()`
- [ ] Replace `GetStorage` with Reacton persistence (`ReactonOptions.persistKey`)
- [ ] Replace `ProviderContainer` / `Get.testMode` in tests with `TestReactonStore`

## What's Next

- [From Riverpod](./from-riverpod) -- Migration guide from Riverpod
- [From BLoC](./from-bloc) -- Migration guide from BLoC
- [From Provider](./from-provider) -- Migration guide from Provider
