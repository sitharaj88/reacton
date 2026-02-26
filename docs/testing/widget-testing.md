# Widget Testing

The `reacton_test` package provides extensions on `WidgetTester` that make it easy to pump widgets wrapped in a `ReactonScope` with optional overrides.

## Setup

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  reacton_test: ^0.1.0
```

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_reacton/flutter_reacton.dart';
import 'package:reacton_test/reacton_test.dart';
```

## pumpReacton

The primary helper is `pumpReacton`, an extension on `WidgetTester`. It wraps your widget in a `ReactonScope` and `MaterialApp` so you can focus on the widget under test.

```dart
Future<void> pumpReacton(
  Widget widget, {
  List<TestOverride>? overrides,
  ReactonStore? store,
})
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `widget` | `Widget` | required | The widget to test |
| `overrides` | `List<TestOverride>?` | `null` | Value overrides for reactons |
| `store` | `ReactonStore?` | `null` | Custom store (creates `TestReactonStore` if not provided) |

### Basic Usage

```dart
testWidgets('displays counter value', (tester) async {
  await tester.pumpReacton(
    const CounterPage(),
    overrides: [ReactonTestOverride(counterReacton, 42)],
  );

  expect(find.text('42'), findsOneWidget);
});
```

### With a Custom Store

If you need access to the store before pumping (e.g., to register effects or set up subscriptions), pass your own `TestReactonStore`:

```dart
testWidgets('uses custom store', (tester) async {
  final store = TestReactonStore(overrides: [
    ReactonTestOverride(counterReacton, 10),
  ]);

  await tester.pumpReacton(
    const CounterPage(),
    store: store,
  );

  expect(find.text('10'), findsOneWidget);
});
```

## Accessing the Store

After pumping, you can access the store to set values and check state:

```dart
testWidgets('accesses store from tester', (tester) async {
  await tester.pumpReacton(const CounterPage());

  final store = tester.reactonStore;
  expect(store.get(counterReacton), 0);
});
```

The `reactonStore` getter looks up the `ReactonScope` in the widget tree and returns its store.

## setReactonAndPump

Set a reacton value and pump in one call:

```dart
Future<void> setReactonAndPump<T>(WritableReacton<T> reacton, T value)
```

```dart
testWidgets('increments counter', (tester) async {
  await tester.pumpReacton(const CounterPage());

  expect(find.text('0'), findsOneWidget);

  await tester.setReactonAndPump(counterReacton, 5);

  expect(find.text('5'), findsOneWidget);
});
```

## updateReactonAndPump

Update a reacton value using a function and pump:

```dart
Future<void> updateReactonAndPump<T>(
  WritableReacton<T> reacton,
  T Function(T) updater,
)
```

```dart
testWidgets('increments by one', (tester) async {
  await tester.pumpReacton(
    const CounterPage(),
    overrides: [ReactonTestOverride(counterReacton, 10)],
  );

  expect(find.text('10'), findsOneWidget);

  await tester.updateReactonAndPump(counterReacton, (c) => c + 1);

  expect(find.text('11'), findsOneWidget);
});
```

## Using ReactonScope Directly

For more control, you can use `ReactonScope` with overrides directly in your test, without the pump helper:

```dart
testWidgets('manual ReactonScope setup', (tester) async {
  await tester.pumpWidget(
    ReactonScope(
      overrides: [
        ReactonOverride(counterReacton, 99),
      ],
      child: MaterialApp(
        home: const CounterPage(),
      ),
    ),
  );

  expect(find.text('99'), findsOneWidget);
});
```

::: tip
`pumpReacton` always wraps your widget in a `MaterialApp(home: widget)`, so you do not need to provide one yourself. If your widget requires a specific `MaterialApp` configuration (theme, locale, etc.), use the manual `ReactonScope` approach instead.
:::

## Testing Async Reactons in Widgets

Override async reactons with synchronous states to avoid real network calls:

```dart
testWidgets('shows weather data', (tester) async {
  await tester.pumpReacton(
    const WeatherPage(),
    overrides: [
      AsyncReactonTestOverride.data(
        weatherReacton,
        Weather(temp: 72, condition: 'Sunny'),
      ),
    ],
  );

  expect(find.text('72'), findsOneWidget);
  expect(find.text('Sunny'), findsOneWidget);
});

testWidgets('shows loading state', (tester) async {
  await tester.pumpReacton(
    const WeatherPage(),
    overrides: [
      AsyncReactonTestOverride.loading(weatherReacton),
    ],
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});

testWidgets('shows error state', (tester) async {
  await tester.pumpReacton(
    const WeatherPage(),
    overrides: [
      AsyncReactonTestOverride.error(
        weatherReacton,
        Exception('Network error'),
      ),
    ],
  );

  expect(find.text('Network error'), findsOneWidget);
});
```

## Testing ReactonListener

`ReactonListener` triggers side effects without rebuilding. Test it by changing the reacton value and verifying the callback:

```dart
testWidgets('listener fires on error', (tester) async {
  await tester.pumpReacton(
    ReactonListener<String?>(
      reacton: errorReacton,
      listener: (context, error) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      },
      child: const Scaffold(body: Text('Content')),
    ),
  );

  await tester.setReactonAndPump(errorReacton, 'Something went wrong');
  await tester.pump(); // Allow SnackBar animation

  expect(find.text('Something went wrong'), findsOneWidget);
});
```

## Testing ReactonConsumer

```dart
testWidgets('consumer watches multiple reactons', (tester) async {
  await tester.pumpReacton(
    ReactonConsumer(
      builder: (context, ref) {
        final count = ref.watch(counterReacton);
        final name = ref.watch(nameReacton);
        return Text('$name: $count');
      },
    ),
    overrides: [
      ReactonTestOverride(counterReacton, 5),
      ReactonTestOverride(nameReacton, 'Alice'),
    ],
  );

  expect(find.text('Alice: 5'), findsOneWidget);
});
```

## What's Next

- [Assertions](./assertions) -- Fluent assertion helpers for stores
- [Effect Testing](./effect-testing) -- Tracking side effects
- [Unit Testing](./unit-testing) -- TestReactonStore and overrides
