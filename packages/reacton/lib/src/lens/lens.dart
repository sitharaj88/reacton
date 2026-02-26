/// Bidirectional optics (lenses) for the Reacton reactive state system.
///
/// Lenses provide composable, type-safe, bidirectional views into nested
/// state. A lens focuses on a part of a larger data structure and can
/// both read the focused value and write it back, propagating changes
/// through the reactive graph.
///
/// ## Overview
///
/// ```dart
/// final userReacton = reacton(User(name: 'Alice', address: Address(city: 'NYC')));
/// final addressLens = lens(userReacton, (u) => u.address, (u, a) => u.copyWith(address: a));
/// final cityLens = addressLens.then(get: (a) => a.city, set: (a, c) => a.copyWith(city: c));
///
/// // Using the lens extension (recommended):
/// store.read(cityLens);          // 'NYC'
/// store.write(cityLens, 'LA');   // Updates user.address.city, propagates reactively
///
/// // Also works with standard store API after initialization:
/// store.get(cityLens);           // 'NYC'
/// store.set(cityLens, 'LA');     // Redirects write through the lens setter
/// ```
///
/// Lenses integrate seamlessly with the existing Reacton infrastructure:
/// they work with `store.get()`, `store.set()`, `store.subscribe()`,
/// `context.watch()`, and `context.set()` out of the box, provided the
/// lens has been initialized via any `read`/`write`/`subscribeLens` call
/// or a direct `store.get(lens)` after the source is live.
library;

import '../core/reacton_base.dart';
import '../core/writable_reacton.dart';
import '../store/store.dart';
import '../utils/disposable.dart';

// =============================================================================
// _SourceReader -- mutable box for store-bound source access
// =============================================================================

/// A mutable container that holds a function for reading the current source
/// value from the store.
///
/// This box is populated by [ReactonStoreLens._ensureLensInitialized] and
/// used by the [onWrite] callback to obtain the current source value when
/// `store.set(lens, value)` is called. The indirection is necessary because
/// [onWrite] is a final field set in the constructor, but the store
/// reference is only available at initialization time.
class _SourceReader<S> {
  /// A function that returns the current source value from the store.
  /// `null` until the lens is initialized in a store.
  S Function()? read;
}

/// Builds the [WritableReacton.onWrite] callback for a lens.
///
/// The [reader] box is captured by the returned closure. When the lens
/// is later initialized in a store, the store extension populates
/// [reader.read] so the closure can obtain the current source value.
void Function(void Function<V>(WritableReacton<V>, V), T) _buildOnWrite<S, T>(
  WritableReacton<S> source,
  S Function(S, T) setter,
  _SourceReader<S> reader,
) {
  return (void Function<V>(WritableReacton<V>, V) set, T newFocused) {
    final readSource = reader.read;
    if (readSource != null) {
      // Normal path: read the live source value from the store and apply
      // the setter to produce the updated source.
      final currentSource = readSource();
      final newSource = setter(currentSource, newFocused);
      set<S>(source, newSource);
    } else {
      // Fallback path: the lens has not been initialized in a store yet.
      // Use the source's initial value as the base. In normal usage this
      // path is not reached because the store extension calls
      // _ensureLensInitialized before any write.
      final newSource = setter(source.initialValue, newFocused);
      set<S>(source, newSource);
    }
  };
}

// =============================================================================
// ReactonLens -- the core bidirectional optic
// =============================================================================

/// A bidirectional, reactive lens that focuses on a part of a reacton's state.
///
/// `ReactonLens<S, T>` reads from and writes to a [WritableReacton<S>] by
/// extracting a value of type `T` via [getter] and producing an updated `S`
/// via [setter]. Because it extends [WritableReacton<T>], it plugs directly
/// into the existing store infrastructure -- `store.get()`, `store.set()`,
/// `store.subscribe()`, and Flutter's `context.watch()` / `context.set()`
/// all work without modification.
///
/// ### How writes propagate
///
/// The lens supplies an [onWrite] callback to [WritableReacton]. When
/// `store.set(lens, value)` is called, the store detects [onWrite] and
/// delegates to it instead of writing the value directly. The callback
/// reads the current source value via a store-bound reader, applies
/// [setter] to produce a new source, and writes that back via
/// `set(source, newSource)`. This triggers the normal reactive graph
/// propagation, which in turn notifies all subscribers of the source --
/// including the lens itself via its source subscription.
///
/// ### Equality gating
///
/// To avoid unnecessary widget rebuilds, the lens compares focused values
/// using either a custom equality function or the default `==` operator.
/// Subscribers are only notified when the focused value actually changes.
///
/// ### Initialization
///
/// A lens must be initialized in a store before it can correctly read/write.
/// The [ReactonStoreLens] extension handles this automatically when you
/// call `store.read(lens)`, `store.write(lens, value)`,
/// `store.subscribeLens(lens, ...)`, or `store.modify(lens, ...)`.
/// After initialization, the standard `store.get(lens)` and
/// `store.set(lens, value)` work transparently.
///
/// ```dart
/// final nameLens = lens(
///   userReacton,
///   (u) => u.name,
///   (u, n) => u.copyWith(name: n),
///   name: 'user.name',
/// );
/// ```
class ReactonLens<S, T> extends WritableReacton<T> {
  /// The source reacton this lens focuses into.
  final WritableReacton<S> source;

  /// Extracts the focused value from the source.
  final T Function(S) getter;

  /// Produces an updated source value given the current source and a new
  /// focused value.
  final S Function(S current, T newValue) setter;

  /// Custom equality for the focused value. When `null`, uses `==`.
  final bool Function(T, T)? _equals;

  /// Mutable box that gets populated with a store-bound reader during
  /// initialization. Used by [onWrite] to read the current source value.
  final _SourceReader<S> _sourceReader;

  /// Creates a lens focusing on part of [source].
  ///
  /// Prefer the top-level [lens()] factory for a terser API.
  factory ReactonLens({
    required WritableReacton<S> source,
    required T Function(S) getter,
    required S Function(S current, T newValue) setter,
    String? name,
    bool Function(T, T)? equals,
  }) {
    final reader = _SourceReader<S>();
    return ReactonLens._withReader(
      source: source,
      getter: getter,
      setter: setter,
      sourceReader: reader,
      name: name,
      equals: equals,
    );
  }

  /// Internal generative constructor called by the factory and by subclass
  /// constructors.
  ///
  /// Every call site MUST supply a [sourceReader] that is the exact same
  /// object captured by the [onWrite] closure. The static helper
  /// [_createLensArgs] handles this for subclasses.
  ReactonLens._withReader({
    required this.source,
    required this.getter,
    required this.setter,
    required _SourceReader<S> sourceReader,
    String? name,
    bool Function(T, T)? equals,
  })  : _equals = equals,
        _sourceReader = sourceReader,
        super(
          getter(source.initialValue),
          name: name ??
              '${source.ref.debugName ?? 'reacton_${source.ref.id}'}:lens',
          onWrite: _buildOnWrite<S, T>(source, setter, sourceReader),
        );

  @override
  bool equals(T a, T b) {
    if (_equals != null) return _equals!(a, b);
    return a == b;
  }

  // ---------------------------------------------------------------------------
  // Composition
  // ---------------------------------------------------------------------------

  /// Compose this lens with a second focus to drill deeper.
  ///
  /// Returns a [ComposedLens] from `S` to `C` that chains the getters
  /// forward and the setters in reverse.
  ///
  /// ```dart
  /// final addressLens = lens(user, (u) => u.address, (u, a) => u.copyWith(address: a));
  /// final cityLens = addressLens.then(
  ///   get: (a) => a.city,
  ///   set: (a, c) => a.copyWith(city: c),
  /// );
  /// ```
  ComposedLens<S, T, C> then<C>({
    required C Function(T) get,
    required T Function(T, C) set,
    String? name,
    bool Function(C, C)? equals,
  }) {
    return ComposedLens<S, T, C>(
      outer: this,
      innerGetter: get,
      innerSetter: set,
      name: name,
      equals: equals,
    );
  }
}

// =============================================================================
// ComposedLens -- composition of two lenses
// =============================================================================

/// A lens formed by composing two lenses in sequence.
///
/// Given an outer lens `A -> B` and inner optics `B -> C`, [ComposedLens]
/// produces a lens `A -> C` whose getter chains forward and whose setter
/// chains in reverse.
///
/// ```dart
/// // outer: User -> Address
/// // inner: Address -> String (city)
/// // composed: User -> String (city)
/// final cityLens = addressLens.then(
///   get: (a) => a.city,
///   set: (a, c) => a.copyWith(city: c),
/// );
/// ```
///
/// Composition can be chained to arbitrary depth. Each step is type-safe.
class ComposedLens<A, B, C> extends ReactonLens<A, C> {
  /// The outer (first) lens in the composition chain.
  final ReactonLens<A, B> outer;

  /// Creates a composed lens from [outer] and an inner getter/setter pair.
  ComposedLens({
    required this.outer,
    required C Function(B) innerGetter,
    required B Function(B, C) innerSetter,
    String? name,
    super.equals,
  }) : super._withReader(
          source: outer.source,
          sourceReader: _SourceReader<A>(),
          getter: (A a) => innerGetter(outer.getter(a)),
          setter: (A a, C c) {
            final b = outer.getter(a);
            final newB = innerSetter(b, c);
            return outer.setter(a, newB);
          },
          name: name ?? '${outer.ref.debugName ?? 'lens'}:composed',
        );
}

// =============================================================================
// ListItemLens -- lens into a specific list index
// =============================================================================

/// A lens that focuses on a single element of a [List] by index.
///
/// Reading through this lens returns the element at [index]. Writing through
/// it produces a new list with the element at [index] replaced.
///
/// Throws [RangeError] at read/write time if [index] is out of bounds.
///
/// ```dart
/// final todosReacton = reacton<List<Todo>>([Todo('Buy milk'), Todo('Walk dog')]);
/// final firstTodoLens = listLens(todosReacton, 0);
///
/// store.read(firstTodoLens); // Todo('Buy milk')
/// store.write(firstTodoLens, Todo('Buy oat milk'));
/// ```
class ListItemLens<T> extends ReactonLens<List<T>, T> {
  /// The zero-based index into the source list.
  final int index;

  /// Creates a lens focusing on element [index] of [source].
  ListItemLens({
    required super.source,
    required this.index,
    String? name,
  }) : super._withReader(
          sourceReader: _SourceReader<List<T>>(),
          getter: (list) {
            RangeError.checkValidIndex(index, list, 'index', list.length);
            return list[index];
          },
          setter: (list, value) {
            RangeError.checkValidIndex(index, list, 'index', list.length);
            final copy = List<T>.of(list);
            copy[index] = value;
            return copy;
          },
          name: name ??
              '${source.ref.debugName ?? 'reacton_${source.ref.id}'}[$index]',
        );
}

// =============================================================================
// MapEntryLens -- lens into a specific map key
// =============================================================================

/// A lens that focuses on a single entry of a [Map] by key.
///
/// Reading returns the value for [key], or `null` if the key is absent.
/// Writing produces a new map with [key] set to the provided value. Setting
/// `null` removes the key from the map.
///
/// ```dart
/// final settingsReacton = reacton<Map<String, String>>({'theme': 'dark'});
/// final themeLens = mapLens(settingsReacton, 'theme');
///
/// store.read(themeLens); // 'dark'
/// store.write(themeLens, 'light');
/// ```
class MapEntryLens<K, V> extends ReactonLens<Map<K, V>, V?> {
  /// The key this lens focuses on.
  final K key;

  /// Creates a lens focusing on [key] within [source].
  MapEntryLens({
    required super.source,
    required this.key,
    String? name,
  }) : super._withReader(
          sourceReader: _SourceReader<Map<K, V>>(),
          getter: (map) => map[key],
          setter: (map, value) {
            final copy = Map<K, V>.of(map);
            if (value == null) {
              copy.remove(key);
            } else {
              copy[key] = value;
            }
            return copy;
          },
          name: name ??
              '${source.ref.debugName ?? 'reacton_${source.ref.id}'}[$key]',
        );
}

// =============================================================================
// FilteredListLens -- lens into a filtered sub-list
// =============================================================================

/// A lens that focuses on the subset of a list matching a [predicate].
///
/// **Read**: Returns a new list containing only elements for which
/// [predicate] returns `true`, preserving source order.
///
/// **Write**: Merges updated elements back into the source list.
/// Elements matching the predicate are replaced (by index in the
/// filtered sub-list) with corresponding elements from the written value.
/// Elements that do not match the predicate are left untouched.
///
/// If the written list is shorter than the current filtered view, excess
/// matching elements are removed from the source. If it is longer, the
/// extra elements are appended to the end of the source list.
///
/// ```dart
/// final todosReacton = reacton<List<Todo>>([
///   Todo('Buy milk', done: false),
///   Todo('Walk dog', done: true),
///   Todo('Read book', done: false),
/// ]);
///
/// final pendingLens = filteredListLens(todosReacton, (t) => !t.done);
/// store.read(pendingLens); // [Todo('Buy milk'), Todo('Read book')]
/// ```
class FilteredListLens<T> extends ReactonLens<List<T>, List<T>> {
  /// The predicate used to select elements from the source.
  final bool Function(T) predicate;

  /// Creates a lens that focuses on elements of [source] matching [predicate].
  FilteredListLens({
    required super.source,
    required this.predicate,
    String? name,
    bool Function(List<T>, List<T>)? equals,
  }) : super._withReader(
          sourceReader: _SourceReader<List<T>>(),
          getter: (list) => list.where(predicate).toList(),
          setter: (list, filtered) =>
              _mergeFiltered<T>(list, filtered, predicate),
          name: name ??
              '${source.ref.debugName ?? 'reacton_${source.ref.id}'}:filtered',
          equals: equals ?? _listShallowEquals,
        );
}

/// Merges a [filtered] list back into the [source] list.
///
/// Elements matching [predicate] in the source are replaced with
/// corresponding elements from [filtered]. Excess matches in the source
/// (when [filtered] is shorter) are removed. Extra elements in [filtered]
/// (when it is longer) are appended.
List<T> _mergeFiltered<T>(
  List<T> source,
  List<T> filtered,
  bool Function(T) predicate,
) {
  final result = <T>[];
  var filterIdx = 0;

  for (var i = 0; i < source.length; i++) {
    if (predicate(source[i])) {
      if (filterIdx < filtered.length) {
        result.add(filtered[filterIdx]);
        filterIdx++;
      }
      // else: matched element is dropped (filtered list is shorter)
    } else {
      result.add(source[i]);
    }
  }

  // Append remaining items from the filtered list
  while (filterIdx < filtered.length) {
    result.add(filtered[filterIdx]);
    filterIdx++;
  }

  return result;
}

/// Shallow equality for lists -- compares length and element identity.
bool _listShallowEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// =============================================================================
// Top-level factory functions
// =============================================================================

/// Creates a [ReactonLens] that focuses on part of a reacton's state.
///
/// The [get] function extracts the focused value from the source.
/// The [set] function produces an updated source given the current source
/// and a new focused value.
///
/// ```dart
/// final userReacton = reacton(User(name: 'Alice'));
/// final nameLens = lens(
///   userReacton,
///   (user) => user.name,
///   (user, name) => user.copyWith(name: name),
///   name: 'user.name',
/// );
///
/// store.read(nameLens);          // 'Alice'
/// store.write(nameLens, 'Bob');  // Updates the user reacton
/// ```
ReactonLens<S, T> lens<S, T>(
  WritableReacton<S> source,
  T Function(S) get,
  S Function(S, T) set, {
  String? name,
  bool Function(T, T)? equals,
}) {
  return ReactonLens<S, T>(
    source: source,
    getter: get,
    setter: set,
    name: name,
    equals: equals,
  );
}

/// Creates a [ListItemLens] that focuses on a specific element of a list
/// reacton by index.
///
/// ```dart
/// final items = reacton<List<String>>(['a', 'b', 'c']);
/// final second = listLens(items, 1);
///
/// store.read(second);         // 'b'
/// store.write(second, 'B');   // items becomes ['a', 'B', 'c']
/// ```
ListItemLens<T> listLens<T>(
  WritableReacton<List<T>> source,
  int index, {
  String? name,
}) {
  return ListItemLens<T>(
    source: source,
    index: index,
    name: name,
  );
}

/// Creates a [MapEntryLens] that focuses on a specific key of a map reacton.
///
/// ```dart
/// final config = reacton<Map<String, int>>({'retries': 3});
/// final retriesLens = mapLens(config, 'retries');
///
/// store.read(retriesLens);       // 3
/// store.write(retriesLens, 5);   // config becomes {'retries': 5}
/// ```
MapEntryLens<K, V> mapLens<K, V>(
  WritableReacton<Map<K, V>> source,
  K key, {
  String? name,
}) {
  return MapEntryLens<K, V>(
    source: source,
    key: key,
    name: name,
  );
}

/// Creates a [FilteredListLens] that focuses on a subset of a list reacton
/// matching a predicate.
///
/// ```dart
/// final numbers = reacton<List<int>>([1, 2, 3, 4, 5]);
/// final evens = filteredListLens(numbers, (n) => n.isEven);
///
/// store.read(evens);              // [2, 4]
/// store.write(evens, [20, 40]);   // numbers becomes [1, 20, 3, 40, 5]
/// ```
FilteredListLens<T> filteredListLens<T>(
  WritableReacton<List<T>> source,
  bool Function(T) predicate, {
  String? name,
  bool Function(List<T>, List<T>)? equals,
}) {
  return FilteredListLens<T>(
    source: source,
    predicate: predicate,
    name: name,
    equals: equals ?? _listShallowEquals,
  );
}

// =============================================================================
// ReactonStore extension -- lens-aware read/write/modify
// =============================================================================

/// Extension on [ReactonStore] providing lens-aware operations.
///
/// These methods handle the bidirectional plumbing: reading through the
/// getter, writing through the setter, and ensuring the underlying source
/// reacton is correctly updated so that the reactive graph propagates.
///
/// Uses the [Expando] pattern for per-store state, consistent with the
/// module system in `reacton_module.dart`.
extension ReactonStoreLens on ReactonStore {
  /// Per-store tracking of source subscriptions that keep lenses in sync.
  static final _lensState = Expando<_StoreLensState>('lensState');

  _StoreLensState _state() {
    var state = _lensState[this];
    if (state == null) {
      state = _StoreLensState();
      _lensState[this] = state;
    }
    return state;
  }

  /// Ensures the lens is initialized in the store and wired to its source.
  ///
  /// On first access this method:
  /// 1. Computes the initial focused value from the live source.
  /// 2. Stores it in the lens's slot via [forceSet].
  /// 3. Populates the lens's [_SourceReader] so that [onWrite] can read
  ///    the current source value from this store.
  /// 4. Subscribes to the source so that source mutations automatically
  ///    refresh the lens value (with equality gating).
  void _ensureLensInitialized<S, T>(ReactonLens<S, T> lensReacton) {
    final state = _state();
    if (state.initializedLenses.contains(lensReacton.ref)) return;

    state.initializedLenses.add(lensReacton.ref);

    // Compute the initial focused value from the live source.
    final sourceValue = get<S>(lensReacton.source);
    final focusedValue = lensReacton.getter(sourceValue);

    // Force-initialize the lens in the store (bypasses onWrite, middleware).
    forceSet<T>(lensReacton, focusedValue);

    // Populate the source reader so that onWrite can read the current
    // source value when store.set(lens, value) is called.
    lensReacton._sourceReader.read = () => get<S>(lensReacton.source);

    // Subscribe to the source so that source changes push updated focused
    // values into the lens slot.
    final unsub = subscribe<S>(lensReacton.source, (newSourceValue) {
      final oldFocused = getByRef(lensReacton.ref) as T;
      final newFocused = lensReacton.getter(newSourceValue);

      if (!lensReacton.equals(oldFocused, newFocused)) {
        // Write the new focused value and notify listeners.
        // We use setByRefId because it bypasses onWrite (avoiding recursive
        // writes back to the source) while still calling _notifyListeners
        // and markDirty, ensuring that subscribers to the lens are notified.
        setByRefId(lensReacton.ref.id, newFocused);
      }
    });

    state.subscriptions[lensReacton.ref] = unsub;
  }

  /// Read a value through a lens.
  ///
  /// Ensures the lens is initialized and wired to its source, then returns
  /// the current focused value.
  ///
  /// ```dart
  /// final city = store.read(cityLens);
  /// ```
  T read<S, T>(ReactonLens<S, T> lensReacton) {
    _ensureLensInitialized(lensReacton);
    return get<T>(lensReacton);
  }

  /// Write a value through a lens.
  ///
  /// Computes the new source value using the lens setter and writes it
  /// to the source reacton. The reactive graph then propagates the change,
  /// which in turn updates the lens value via its source subscription.
  ///
  /// ```dart
  /// store.write(cityLens, 'San Francisco');
  /// ```
  void write<S, T>(ReactonLens<S, T> lensReacton, T value) {
    _ensureLensInitialized(lensReacton);
    final currentSource = get<S>(lensReacton.source);
    final newSource = lensReacton.setter(currentSource, value);
    set<S>(lensReacton.source, newSource);
  }

  /// Update a value through a lens using a transformation function.
  ///
  /// Reads the current focused value, applies [updater], and writes the
  /// result back through the lens.
  ///
  /// ```dart
  /// store.modify(counterLens, (n) => n + 1);
  /// ```
  void modify<S, T>(ReactonLens<S, T> lensReacton, T Function(T) updater) {
    _ensureLensInitialized(lensReacton);
    final current = get<T>(lensReacton);
    write(lensReacton, updater(current));
  }

  /// Subscribe to focused value changes through a lens.
  ///
  /// The listener is only called when the focused value actually changes
  /// (gated by the lens's equality function). Returns an [Unsubscribe]
  /// callback to cancel the subscription.
  ///
  /// ```dart
  /// final unsub = store.subscribeLens(cityLens, (city) {
  ///   print('City changed to $city');
  /// });
  /// ```
  Unsubscribe subscribeLens<S, T>(
    ReactonLens<S, T> lensReacton,
    void Function(T) listener,
  ) {
    _ensureLensInitialized(lensReacton);
    return subscribe<T>(lensReacton, listener);
  }

  /// Remove a lens and clean up its source subscription.
  ///
  /// After calling this, the lens is no longer synchronized with its
  /// source. Subscribers are removed and the lens slot is freed.
  void removeLens<S, T>(ReactonLens<S, T> lensReacton) {
    final state = _state();
    final unsub = state.subscriptions.remove(lensReacton.ref);
    unsub?.call();
    state.initializedLenses.remove(lensReacton.ref);
    lensReacton._sourceReader.read = null;
    remove(lensReacton.ref);
  }
}

/// Per-store state for lens management.
///
/// Tracks which lenses have been initialized and holds the source
/// subscriptions so they can be cleaned up.
class _StoreLensState {
  /// Refs of lenses that have been initialized in this store.
  final Set<ReactonRef> initializedLenses = {};

  /// Source subscriptions keyed by lens ref, for cleanup.
  final Map<ReactonRef, Unsubscribe> subscriptions = {};
}

// =============================================================================
// Convenience extensions on ReactonLens for further composition
// =============================================================================

/// Extension providing shorthand composition operators on [ReactonLens].
extension ReactonLensComposition<S, T> on ReactonLens<S, T> {
  /// Compose this lens to focus on an element of a list that this lens
  /// returns.
  ///
  /// The caller must ensure that `T` is `List<E>` at the call site.
  /// A runtime cast is performed; a [TypeError] is thrown if the types
  /// do not match.
  ///
  /// ```dart
  /// final itemsLens = lens(state, (s) => s.items, (s, i) => s.copyWith(items: i));
  /// final firstItem = itemsLens.item(0);
  /// ```
  ComposedLens<S, List<E>, E> item<E>(int index) {
    final self = this as ReactonLens<S, List<E>>;
    return self.then<E>(
      get: (list) {
        RangeError.checkValidIndex(index, list, 'index', list.length);
        return list[index];
      },
      set: (list, value) {
        RangeError.checkValidIndex(index, list, 'index', list.length);
        final copy = List<E>.of(list);
        copy[index] = value;
        return copy;
      },
      name: '${ref.debugName ?? 'lens'}[$index]',
    );
  }

  /// Compose this lens to focus on an entry of a map that this lens returns.
  ///
  /// The caller must ensure that `T` is `Map<K, V>` at the call site.
  /// A runtime cast is performed; a [TypeError] is thrown if the types
  /// do not match.
  ///
  /// ```dart
  /// final metaLens = lens(state, (s) => s.metadata, (s, m) => s.copyWith(metadata: m));
  /// final versionLens = metaLens.entry('version');
  /// ```
  ComposedLens<S, Map<K, V>, V?> entry<K, V>(K key) {
    final self = this as ReactonLens<S, Map<K, V>>;
    return self.then<V?>(
      get: (map) => map[key],
      set: (map, value) {
        final copy = Map<K, V>.of(map);
        if (value == null) {
          copy.remove(key);
        } else {
          copy[key] = value;
        }
        return copy;
      },
      name: '${ref.debugName ?? 'lens'}[$key]',
    );
  }
}

// =============================================================================
// Integration aliases
// =============================================================================

/// Extension on [ReactonStore] providing convenience aliases for
/// lens-typed reactons.
///
/// These are thin wrappers around [ReactonStoreLens.read] and
/// [ReactonStoreLens.write] for contexts where the naming is clearer.
extension ReactonStoreLensIntegration on ReactonStore {
  /// Read a lens value, ensuring initialization.
  ///
  /// Equivalent to [ReactonStoreLens.read].
  T getLens<S, T>(ReactonLens<S, T> lensReacton) => read(lensReacton);

  /// Write a lens value, propagating through the setter to the source.
  ///
  /// Equivalent to [ReactonStoreLens.write].
  void setLens<S, T>(ReactonLens<S, T> lensReacton, T value) =>
      write(lensReacton, value);
}
