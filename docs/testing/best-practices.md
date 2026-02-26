# Testing Best Practices

This guide covers patterns, conventions, and common pitfalls for testing Reacton applications. Following these practices will keep your test suite fast, reliable, and maintainable.

## Test Organization

### File Structure

Mirror your source tree inside `test/`:

```
lib/
  reactons/
    counter_reacton.dart
    auth_reacton.dart
  features/
    checkout/
      checkout_reactons.dart
      checkout_page.dart
test/
  reactons/
    counter_reacton_test.dart
    auth_reacton_test.dart
  features/
    checkout/
      checkout_reactons_test.dart
      checkout_page_test.dart
  integration/
    checkout_flow_test.dart
```

### Naming Conventions

Use descriptive `group()` and `test()` names that read like sentences:

```dart
group('counterReacton', () {
  test('starts at zero', () { ... });
  test('increments by one', () { ... });
  test('does not go below zero when decrementing', () { ... });
});

group('filteredTodosReacton', () {
  test('returns all todos when filter is "all"', () { ... });
  test('returns only completed todos when filter is "done"', () { ... });
  test('updates when the source todo list changes', () { ... });
});
```

**Do:**
- Start with the reacton or feature name as the `group`
- Describe the expected behavior in plain English
- Include the condition that triggers the behavior

**Don't:**
- Use generic names like `test('works')` or `test('test 1')`
- Repeat the group name inside each test name

### Grouping by Behavior

```dart
group('AuthModule', () {
  group('login', () {
    test('sets token on success', () { ... });
    test('sets error on invalid credentials', () { ... });
    test('clears previous error before retrying', () { ... });
  });

  group('logout', () {
    test('clears token', () { ... });
    test('clears user profile', () { ... });
    test('resets cart state', () { ... });
  });
});
```

## What to Test vs What Not to Test

### Test These

| Category | Example |
|----------|---------|
| Initial values | `expect(store.get(counterReacton), 0)` |
| Computed derivations | Setting sources and checking computed output |
| State machine transitions | Valid transitions, invalid transitions (no-op) |
| Async states | Loading, data, error for `asyncReacton` |
| Effects and side effects | `createEffect` triggers on the correct changes |
| Persistence round-trips | Write, "restart", read back |
| Edge cases | Empty lists, null values, boundary numbers |
| Cross-module interactions | Auth state affects cart checkout |

### Don't Test These

| Category | Why |
|----------|-----|
| Reacton library internals | Reacton's own test suite covers this |
| Flutter framework behavior | Testing `Text` renders a string is not your job |
| Third-party API responses | Mock the API, test your reacton logic |
| Exact recomputation count | Implementation detail; test the result instead |
| Private helper functions | Test through the public reacton API |

## Test Isolation

Every test must start with a clean slate. Create a fresh `TestReactonStore` in `setUp`:

```dart
void main() {
  late TestReactonStore store;

  setUp(() {
    store = TestReactonStore();
  });

  test('first test', () {
    store.set(counterReacton, 10);
    expect(store.get(counterReacton), 10);
  });

  test('second test does not see state from first', () {
    // This is a fresh store — counter is back to 0
    expect(store.get(counterReacton), 0);
  });
}
```

::: danger Never share a store across tests
Shared mutable state is the most common cause of flaky tests. If test A sets `counterReacton` to 5 and test B assumes it starts at 0, the suite will break when test order changes.
:::

### Isolating Async Reactons

Override async reactons with synchronous values to keep unit tests fast and deterministic:

```dart
setUp(() {
  store = TestReactonStore(overrides: [
    AsyncReactonTestOverride.data(userProfileReacton, testUser),
    AsyncReactonTestOverride.data(postsReacton, [testPost1, testPost2]),
  ]);
});
```

## Async Test Patterns

### Completing Futures

For async reactons that fetch data, use `store.waitFor()` to wait for the async operation to complete:

```dart
test('loads weather data', () async {
  store.set(cityReacton, 'London');

  await store.waitFor(weatherReacton);

  final weather = store.get(weatherReacton);
  expect(weather.hasData, isTrue);
  expect(weather.valueOrNull?.city, 'London');
});
```

### Testing Loading States

```dart
test('shows loading then data', () async {
  final states = <AsyncValue<Weather>>[];
  store.subscribe(weatherReacton, (v) => states.add(v));

  store.set(cityReacton, 'Paris');
  await store.waitFor(weatherReacton);

  expect(states.first.isLoading, isTrue);
  expect(states.last.hasData, isTrue);
});
```

### Fake Timers

For debounce and throttle tests, use `fakeAsync` to control time:

```dart
import 'package:fake_async/fake_async.dart';

test('debouncer waits before emitting', () {
  fakeAsync((async) {
    final store = TestReactonStore();
    final values = <String>[];
    store.subscribe(searchResultsReacton, (v) => values.add(v));

    store.set(searchQueryReacton, 'flu');
    store.set(searchQueryReacton, 'flut');
    store.set(searchQueryReacton, 'flutter');

    // No emission yet — debounce is 300ms
    expect(values, isEmpty);

    async.elapse(Duration(milliseconds: 300));

    // Only the final value triggers the search
    expect(values.length, 1);
  });
});
```

### Testing Error States

```dart
test('handles API failure gracefully', () async {
  // Configure mock to throw
  MockWeatherApi.shouldFail = true;

  store.set(cityReacton, 'InvalidCity');
  await store.waitFor(weatherReacton);

  final weather = store.get(weatherReacton);
  expect(weather.hasError, isTrue);
  expect(weather.error, isA<ApiException>());
});
```

## CI/CD Integration Tips

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run a specific test file
flutter test test/reactons/counter_reacton_test.dart

# Run tests matching a pattern
flutter test --name "counterReacton"
```

### GitHub Actions Example

```yaml
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      - run: flutter pub get
      - run: flutter test --coverage
      - run: flutter pub run reacton_cli analyze
      - uses: codecov/codecov-action@v4
        with:
          file: coverage/lcov.info
```

### Pre-commit Hooks

Add a quick smoke test to your pre-commit workflow:

```bash
# In .husky/pre-commit or equivalent
flutter test --tags smoke
```

Tag your critical tests:

```dart
@Tags(['smoke'])
void main() {
  test('app boots without error', () {
    final store = TestReactonStore();
    expect(store.get(appReadyReacton), isTrue);
  });
}
```

## Coverage Strategies

### What to Aim For

- **Reacton logic (computed, effects, sagas):** 90%+ coverage
- **Widget integration:** 70-80% coverage for key user flows
- **Tooling and boilerplate:** Don't chase coverage on generated code

### Generating Coverage Reports

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Excluding Files from Coverage

Add to your `pubspec.yaml` or a `.lcov` ignore file:

```yaml
# In analysis_options.yaml
analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
```

## Common Anti-Patterns

### 1. Testing Through the UI When a Unit Test Suffices

```dart
// BAD: Spinning up a full widget tree to test math
testWidgets('total is correct', (tester) async {
  await tester.pumpWidget(
    ReactonScope(child: MaterialApp(home: CartPage())),
  );
  // ...find text, tap buttons, verify...
});

// GOOD: Test the reacton directly
test('total is correct', () {
  final store = TestReactonStore();
  store.set(priceReacton, 10.0);
  store.set(quantityReacton, 3);
  expect(store.get(totalReacton), 30.0);
});
```

### 2. Over-Mocking

```dart
// BAD: Mocking everything, testing nothing
test('fetches user', () {
  final mockStore = MockReactonStore();
  when(mockStore.get(userReacton)).thenReturn(testUser);
  expect(mockStore.get(userReacton), testUser); // This tests mockito, not your code
});

// GOOD: Use TestReactonStore with real reacton logic
test('fetches user', () async {
  final store = TestReactonStore();
  store.set(authTokenReacton, 'valid-token');
  await store.waitFor(userReacton);
  expect(store.get(userReacton).hasData, isTrue);
});
```

### 3. Non-Deterministic Tests

```dart
// BAD: Depending on wall-clock time
test('debounce works', () async {
  store.set(queryReacton, 'hello');
  await Future.delayed(Duration(milliseconds: 350));
  expect(store.get(resultsReacton), isNotEmpty);
});

// GOOD: Use fakeAsync
test('debounce works', () {
  fakeAsync((async) {
    store.set(queryReacton, 'hello');
    async.elapse(Duration(milliseconds: 350));
    expect(store.get(resultsReacton), isNotEmpty);
  });
});
```

### 4. Giant Test Functions

```dart
// BAD: One test doing 15 things
test('the whole app works', () {
  store.set(authTokenReacton, 'token');
  expect(store.get(isLoggedInReacton), true);
  store.set(cartItemsReacton, ['A']);
  expect(store.get(canCheckoutReacton), true);
  // ... 50 more lines ...
});

// GOOD: Focused tests in groups
group('checkout flow', () {
  test('requires login', () { ... });
  test('requires non-empty cart', () { ... });
  test('enables checkout when both conditions met', () { ... });
});
```

### 5. Forgetting Cleanup

```dart
// BAD: Subscription leak
test('tracks updates', () {
  store.subscribe(counterReacton, (v) => values.add(v));
  // Subscription is never cancelled — may affect next test
});

// GOOD: Always unsubscribe
test('tracks updates', () {
  final unsub = store.subscribe(counterReacton, (v) => values.add(v));
  store.set(counterReacton, 1);
  expect(values, [1]);
  unsub();
});
```

### 6. Testing Implementation Instead of Behavior

```dart
// BAD: Checking how many times something recomputed
test('computed efficiency', () {
  var count = 0;
  final myComputed = computed((read) {
    count++;
    return read(sourceReacton);
  });
  store.get(myComputed);
  store.get(myComputed);
  expect(count, 1); // Fragile — depends on caching internals
});

// GOOD: Verify the value is correct
test('computed returns expected value', () {
  store.set(sourceReacton, 42);
  expect(store.get(myComputed), 42);
});
```

## Checklist

Before merging a PR, verify:

- [ ] Every new reacton has at least one test for its initial value
- [ ] Computed reactons are tested with multiple source combinations
- [ ] Async reactons are tested for loading, data, and error states
- [ ] State machines are tested for valid and invalid transitions
- [ ] Effects and sagas have integration tests for their full flow
- [ ] No tests depend on execution order
- [ ] All subscriptions are cleaned up in tests
- [ ] CI passes with `flutter test --coverage`

## What's Next

- [Unit Testing](./unit-testing) -- Core unit testing patterns
- [Widget Testing](./widget-testing) -- Testing Flutter widgets with Reacton
- [Integration Testing](./integration-testing) -- Multi-module test patterns
