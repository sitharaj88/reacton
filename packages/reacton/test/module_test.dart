import 'package:test/test.dart';
import 'package:reacton/reacton.dart';

// ---------------------------------------------------------------------------
// Test modules
// ---------------------------------------------------------------------------

/// A simple counter module for testing.
class CounterModule extends ReactonModule {
  late final counter = register(reacton(0, name: 'counter.value'));
  late final doubleCounter = register(computed(
    (read) => read(counter) * 2,
    name: 'counter.double',
  ));

  @override
  String get name => 'counter';

  bool initCalled = false;
  bool disposeCalled = false;

  @override
  void onInit(ReactonStore store) {
    initCalled = true;
  }

  @override
  void onDispose(ReactonStore store) {
    disposeCalled = true;
  }
}

/// A cart module that demonstrates list reacton registration.
class CartModule extends ReactonModule {
  late final items = register(reactonList<String>([], name: 'cart.items'));

  @override
  String get name => 'cart';

  bool initCalled = false;
  bool disposeCalled = false;

  @override
  void onInit(ReactonStore store) {
    initCalled = true;
  }

  @override
  void onDispose(ReactonStore store) {
    disposeCalled = true;
  }
}

/// A minimal module with no reactons and no lifecycle overrides.
class EmptyModule extends ReactonModule {
  @override
  String get name => 'empty';
}

/// A module that registers reactons and reads them in onInit.
class EagerModule extends ReactonModule {
  late final value = register(reacton('hello', name: 'eager.value'));

  String? capturedValue;

  @override
  String get name => 'eager';

  @override
  void onInit(ReactonStore store) {
    capturedValue = store.get(value);
  }
}

void main() {
  group('ReactonModule', () {
    late ReactonStore store;

    setUp(() {
      store = ReactonStore();
    });

    tearDown(() {
      store.dispose();
    });

    // -----------------------------------------------------------------------
    // Module installation
    // -----------------------------------------------------------------------
    group('installModule()', () {
      test('installs a module into the store', () {
        final module = CounterModule();
        store.installModule<CounterModule>(module);

        expect(store.hasModule<CounterModule>(), isTrue);
      });

      test('returns the installed module', () {
        final module = CounterModule();
        final result = store.installModule<CounterModule>(module);
        expect(result, same(module));
      });

      test('calls onInit during installation', () {
        final module = CounterModule();
        expect(module.initCalled, isFalse);

        store.installModule<CounterModule>(module);
        expect(module.initCalled, isTrue);
      });

      test('sets isInitialized to true', () {
        final module = CounterModule();
        expect(module.isInitialized, isFalse);

        store.installModule<CounterModule>(module);
        expect(module.isInitialized, isTrue);
      });

      test('initializes all registered reactons in the store', () {
        final module = CounterModule();
        store.installModule<CounterModule>(module);

        // The counter reacton should be readable without explicit initialization
        expect(store.get(module.counter), 0);
        expect(store.get(module.doubleCounter), 0);
      });

      test('module can read reacton values in onInit', () {
        final module = EagerModule();
        store.installModule<EagerModule>(module);

        expect(module.capturedValue, 'hello');
      });
    });

    // -----------------------------------------------------------------------
    // Module registration of reactons
    // -----------------------------------------------------------------------
    group('register()', () {
      test('register tracks reactons in the module', () {
        final module = CounterModule();
        // Access the late fields to trigger registration
        // Access late fields to trigger registration
        module.counter;
        module.doubleCounter;

        expect(module.registeredReactons, hasLength(2));
      });

      test('registeredReactons returns an unmodifiable list', () {
        final module = CounterModule();
        module.counter;

        expect(
          () => (module.registeredReactons as List).add(reacton(0)),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('register returns the registered reacton', () {
        final module = EmptyModule();
        final r = reacton(42, name: 'test');
        final result = module.register(r);
        expect(result, same(r));
      });
    });

    // -----------------------------------------------------------------------
    // Accessing modules from store
    // -----------------------------------------------------------------------
    group('module<T>()', () {
      test('returns the installed module by type', () {
        final module = CounterModule();
        store.installModule<CounterModule>(module);

        final retrieved = store.module<CounterModule>();
        expect(retrieved, same(module));
      });

      test('throws StateError for uninstalled module', () {
        expect(
          () => store.module<CounterModule>(),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('not installed'),
          )),
        );
      });
    });

    // -----------------------------------------------------------------------
    // hasModule
    // -----------------------------------------------------------------------
    group('hasModule()', () {
      test('returns false when module is not installed', () {
        expect(store.hasModule<CounterModule>(), isFalse);
      });

      test('returns true when module is installed', () {
        store.installModule<CounterModule>(CounterModule());
        expect(store.hasModule<CounterModule>(), isTrue);
      });

      test('returns false after module is uninstalled', () {
        store.installModule<CounterModule>(CounterModule());
        store.uninstallModule<CounterModule>();
        expect(store.hasModule<CounterModule>(), isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // Multiple modules
    // -----------------------------------------------------------------------
    group('multiple modules', () {
      test('different module types can be installed simultaneously', () {
        final counter = CounterModule();
        final cart = CartModule();

        store.installModule<CounterModule>(counter);
        store.installModule<CartModule>(cart);

        expect(store.hasModule<CounterModule>(), isTrue);
        expect(store.hasModule<CartModule>(), isTrue);
        expect(store.moduleCount, 2);
      });

      test('modules operate independently', () {
        final counter = CounterModule();
        final cart = CartModule();

        store.installModule<CounterModule>(counter);
        store.installModule<CartModule>(cart);

        store.set(counter.counter, 42);
        store.listAdd(cart.items, 'item1');

        expect(store.get(counter.counter), 42);
        expect(store.get(cart.items), ['item1']);
      });

      test('uninstalling one module does not affect another', () {
        final counter = CounterModule();
        final cart = CartModule();

        store.installModule<CounterModule>(counter);
        store.installModule<CartModule>(cart);

        store.set(counter.counter, 10);
        store.listAdd(cart.items, 'widget');

        store.uninstallModule<CounterModule>();

        expect(store.hasModule<CounterModule>(), isFalse);
        expect(store.hasModule<CartModule>(), isTrue);
        expect(store.get(cart.items), ['widget']);
      });
    });

    // -----------------------------------------------------------------------
    // Duplicate module installation
    // -----------------------------------------------------------------------
    group('duplicate module installation', () {
      test('throws StateError when installing same module type twice', () {
        store.installModule<CounterModule>(CounterModule());

        expect(
          () => store.installModule<CounterModule>(CounterModule()),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('already installed'),
              contains('CounterModule'),
            ),
          )),
        );
      });

      test('can reinstall after uninstalling', () {
        store.installModule<CounterModule>(CounterModule());
        store.uninstallModule<CounterModule>();

        final newModule = CounterModule();
        store.installModule<CounterModule>(newModule);

        expect(store.hasModule<CounterModule>(), isTrue);
        expect(store.module<CounterModule>(), same(newModule));
      });
    });

    // -----------------------------------------------------------------------
    // Module uninstallation
    // -----------------------------------------------------------------------
    group('uninstallModule()', () {
      test('calls onDispose during uninstallation', () {
        final module = CounterModule();
        store.installModule<CounterModule>(module);

        expect(module.disposeCalled, isFalse);
        store.uninstallModule<CounterModule>();
        expect(module.disposeCalled, isTrue);
      });

      test('sets isInitialized to false after uninstallation', () {
        final module = CounterModule();
        store.installModule<CounterModule>(module);
        expect(module.isInitialized, isTrue);

        store.uninstallModule<CounterModule>();
        expect(module.isInitialized, isFalse);
      });

      test('removes the module from the store', () {
        store.installModule<CounterModule>(CounterModule());
        store.uninstallModule<CounterModule>();
        expect(store.hasModule<CounterModule>(), isFalse);
      });

      test('throws StateError when uninstalling a module that is not installed',
          () {
        expect(
          () => store.uninstallModule<CounterModule>(),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('not installed'),
          )),
        );
      });

      test('removes module reactons from the store', () {
        final module = CounterModule();
        store.installModule<CounterModule>(module);

        // Verify reactons are present
        expect(store.get(module.counter), 0);
        final counterRef = module.counter.ref;

        store.uninstallModule<CounterModule>();

        // Verify reacton has been removed from the store
        expect(store.getByRef(counterRef), isNull);
      });

      test('decrements moduleCount after uninstallation', () {
        store.installModule<CounterModule>(CounterModule());
        store.installModule<CartModule>(CartModule());
        expect(store.moduleCount, 2);

        store.uninstallModule<CounterModule>();
        expect(store.moduleCount, 1);

        store.uninstallModule<CartModule>();
        expect(store.moduleCount, 0);
      });
    });

    // -----------------------------------------------------------------------
    // Module lifecycle ordering
    // -----------------------------------------------------------------------
    group('lifecycle ordering', () {
      test('onInit is called after isInitialized is set to true', () {
        bool? wasInitializedDuringOnInit;

        final module = _LifecycleCheckModule(
          onInitCallback: (self) {
            wasInitializedDuringOnInit = self.isInitialized;
          },
        );

        store.installModule<_LifecycleCheckModule>(module);
        expect(wasInitializedDuringOnInit, isTrue);
      });

      test('onDispose is called before isInitialized is set to false', () {
        bool? wasInitializedDuringOnDispose;

        final module = _LifecycleCheckModule(
          onDisposeCallback: (self) {
            wasInitializedDuringOnDispose = self.isInitialized;
          },
        );

        store.installModule<_LifecycleCheckModule>(module);
        store.uninstallModule<_LifecycleCheckModule>();

        // onDispose is called before _isInitialized is set to false
        // (Looking at the source: onDispose is called, then _isInitialized = false)
        expect(wasInitializedDuringOnDispose, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // installedModules
    // -----------------------------------------------------------------------
    group('installedModules', () {
      test('returns empty iterable when no modules installed', () {
        expect(store.installedModules, isEmpty);
      });

      test('returns all installed modules', () {
        final counter = CounterModule();
        final cart = CartModule();
        store.installModule<CounterModule>(counter);
        store.installModule<CartModule>(cart);

        final modules = store.installedModules.toList();
        expect(modules, hasLength(2));
        expect(modules, containsAll([counter, cart]));
      });
    });

    // -----------------------------------------------------------------------
    // moduleCount
    // -----------------------------------------------------------------------
    group('moduleCount', () {
      test('returns 0 when no modules installed', () {
        expect(store.moduleCount, 0);
      });

      test('reflects the number of installed modules', () {
        store.installModule<CounterModule>(CounterModule());
        expect(store.moduleCount, 1);

        store.installModule<CartModule>(CartModule());
        expect(store.moduleCount, 2);
      });
    });

    // -----------------------------------------------------------------------
    // Empty module
    // -----------------------------------------------------------------------
    group('empty module', () {
      test('can install a module with no reactons', () {
        final empty = EmptyModule();
        store.installModule<EmptyModule>(empty);

        expect(store.hasModule<EmptyModule>(), isTrue);
        expect(empty.registeredReactons, isEmpty);
        expect(empty.isInitialized, isTrue);
      });

      test('can uninstall a module with no reactons', () {
        store.installModule<EmptyModule>(EmptyModule());
        store.uninstallModule<EmptyModule>();
        expect(store.hasModule<EmptyModule>(), isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // Module reacton interaction through store
    // -----------------------------------------------------------------------
    group('module reacton interaction', () {
      test('module reactons can be read and written via the store', () {
        final module = CounterModule();
        store.installModule<CounterModule>(module);

        expect(store.get(module.counter), 0);

        store.set(module.counter, 10);
        expect(store.get(module.counter), 10);
      });

      test('computed module reactons react to changes', () {
        final module = CounterModule();
        store.installModule<CounterModule>(module);

        store.set(module.counter, 5);
        expect(store.get(module.doubleCounter), 10);

        store.set(module.counter, 7);
        expect(store.get(module.doubleCounter), 14);
      });

      test('can subscribe to module reactons', () {
        final module = CounterModule();
        store.installModule<CounterModule>(module);

        final values = <int>[];
        store.subscribe(module.counter, (v) => values.add(v));

        store.set(module.counter, 1);
        store.set(module.counter, 2);
        store.set(module.counter, 3);

        expect(values, [1, 2, 3]);
      });
    });

    // -----------------------------------------------------------------------
    // Module name
    // -----------------------------------------------------------------------
    group('module name', () {
      test('exposes the module name', () {
        final module = CounterModule();
        expect(module.name, 'counter');
      });

      test('each module has its own name', () {
        final counter = CounterModule();
        final cart = CartModule();
        expect(counter.name, 'counter');
        expect(cart.name, 'cart');
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Helper module for lifecycle ordering tests
// ---------------------------------------------------------------------------

class _LifecycleCheckModule extends ReactonModule {
  final void Function(_LifecycleCheckModule self)? onInitCallback;
  final void Function(_LifecycleCheckModule self)? onDisposeCallback;

  _LifecycleCheckModule({this.onInitCallback, this.onDisposeCallback});

  @override
  String get name => 'lifecycleCheck';

  @override
  void onInit(ReactonStore store) {
    onInitCallback?.call(this);
  }

  @override
  void onDispose(ReactonStore store) {
    onDisposeCallback?.call(this);
  }
}
