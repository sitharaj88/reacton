import '../core/reacton_base.dart';
import '../store/store.dart';

/// A module groups related reactons with lifecycle management.
///
/// Modules provide:
/// - Namespace isolation (prevents naming collisions across teams)
/// - Lifecycle management (onInit, onDispose)
/// - Lazy initialization (installed only when first accessed)
/// - Clean uninstallation (removes all module reactons)
///
/// ```dart
/// class CartModule extends ReactonModule {
///   late final items = register(reactonList<CartItem>([], name: 'cart.items'));
///   late final total = register(computed(
///     (read) => read(items).fold(0.0, (s, i) => s + i.price),
///     name: 'cart.total',
///   ));
///
///   @override
///   String get name => 'cart';
///
///   @override
///   void onInit(ReactonStore store) {
///     // Load initial data, set up effects, etc.
///   }
///
///   @override
///   void onDispose(ReactonStore store) {
///     // Cleanup resources
///   }
/// }
///
/// // Install
/// store.installModule(CartModule());
///
/// // Access
/// final cart = store.module<CartModule>();
/// store.get(cart.items);
///
/// // Uninstall
/// store.uninstallModule<CartModule>();
/// ```
abstract class ReactonModule {
  final List<ReactonBase> _registeredReactons = [];
  bool _isInitialized = false;

  /// The module name (used for debugging and namespacing).
  String get name;

  /// Whether this module has been initialized.
  bool get isInitialized => _isInitialized;

  /// All reactons registered to this module.
  List<ReactonBase> get registeredReactons => List.unmodifiable(_registeredReactons);

  /// Register a reacton as part of this module.
  ///
  /// Call this during field initialization with `late final`.
  /// The reacton will be tracked for lifecycle management.
  T register<T extends ReactonBase>(T reacton) {
    _registeredReactons.add(reacton);
    return reacton;
  }

  /// Called when the module is installed into a store.
  /// Override to perform initialization (load data, create effects, etc.).
  void onInit(ReactonStore store) {}

  /// Called when the module is uninstalled from a store.
  /// Override to perform cleanup.
  void onDispose(ReactonStore store) {}
}

/// Extension on [ReactonStore] for module management.
extension ReactonStoreModules on ReactonStore {
  // Module storage key
  static final _modules = Expando<Map<Type, ReactonModule>>('modules');

  Map<Type, ReactonModule> _getModules() {
    var modules = _modules[this];
    if (modules == null) {
      modules = {};
      _modules[this] = modules;
    }
    return modules;
  }

  /// Install a module into this store.
  ///
  /// The module's [onInit] will be called and all its reactons
  /// will be initialized in the store.
  ///
  /// Throws [StateError] if a module of the same type is already installed.
  T installModule<T extends ReactonModule>(T module) {
    final modules = _getModules();
    if (modules.containsKey(T)) {
      throw StateError(
        'Module of type $T is already installed. '
        'Uninstall it first with uninstallModule<$T>().',
      );
    }

    modules[T] = module;
    module._isInitialized = true;

    // Initialize all registered reactons in the store
    for (final reacton in module.registeredReactons) {
      get(reacton);
    }

    module.onInit(this);
    return module;
  }

  /// Get an installed module by type.
  ///
  /// Throws [StateError] if the module is not installed.
  T module<T extends ReactonModule>() {
    final modules = _getModules();
    final mod = modules[T];
    if (mod == null) {
      throw StateError(
        'Module of type $T is not installed. '
        'Install it first with installModule<$T>(...).',
      );
    }
    return mod as T;
  }

  /// Check if a module is installed.
  bool hasModule<T extends ReactonModule>() {
    return _getModules().containsKey(T);
  }

  /// Uninstall a module, removing all its reactons from the store.
  void uninstallModule<T extends ReactonModule>() {
    final modules = _getModules();
    final mod = modules[T];
    if (mod == null) {
      throw StateError('Module of type $T is not installed.');
    }

    // Call dispose
    mod.onDispose(this);

    // Remove all module reactons from the store
    for (final reacton in mod.registeredReactons) {
      remove(reacton.ref);
    }

    mod._isInitialized = false;
    modules.remove(T);
  }

  /// Get all installed modules.
  Iterable<ReactonModule> get installedModules => _getModules().values;

  /// Get the count of installed modules.
  int get moduleCount => _getModules().length;
}
