import 'package:meta/meta.dart';
import '../middleware/middleware.dart';
import '../persistence/serializer.dart';

/// Unique identity for a reacton, used as a key in the store.
///
/// Each call to [reacton()], [computed()], [asyncReacton()], etc. creates a unique
/// [ReactonRef] that identifies the reacton throughout its lifetime.
class ReactonRef {
  static int _counter = 0;

  /// Unique numeric identifier.
  final int id;

  /// Optional debug name for DevTools and logging.
  final String? debugName;

  ReactonRef({this.debugName}) : id = _counter++;

  @override
  int get hashCode => id;

  @override
  bool operator ==(Object other) => other is ReactonRef && other.id == id;

  @override
  String toString() => debugName ?? 'reacton_$id';
}

/// Configuration options for reactons.
class ReactonOptions<T> {
  /// If true, the reacton's value is kept even when no watchers remain.
  final bool keepAlive;

  /// Debounce writes by this duration.
  final Duration? debounce;

  /// Serializer for persistence.
  final Serializer<T>? serializer;

  /// Key for persistent storage. If set, the reacton is auto-persisted.
  final String? persistKey;

  /// Middleware chain applied to this reacton.
  final List<Middleware<T>> middleware;

  /// Custom equality function. Uses `==` by default.
  final bool Function(T prev, T next)? equals;

  const ReactonOptions({
    this.keepAlive = false,
    this.debounce,
    this.serializer,
    this.persistKey,
    this.middleware = const [],
    this.equals,
  });
}

/// Type of reader function used by computed reactons and effects.
typedef ReactonReader = T Function<T>(ReactonBase<T> reacton);

/// Base class for all reactons in the Reacton reactive system.
///
/// A reacton is the smallest unit of reactive state. It has a unique [ref]
/// that identifies it and optional [options] for configuration.
@immutable
abstract class ReactonBase<T> {
  /// Unique identity of this reacton.
  final ReactonRef ref;

  /// Configuration options.
  final ReactonOptions<T>? options;

  ReactonBase({String? name, this.options}) : ref = ReactonRef(debugName: name);

  /// Internal constructor that reuses an existing [ReactonRef].
  ///
  /// Used by the session recorder to create lightweight shims that
  /// share a ref identity with an already-registered reacton, enabling
  /// subscription by ref without access to the original instance.
  ReactonBase.fromRef(this.ref, {this.options});

  /// Whether values are considered equal (prevents unnecessary propagation).
  bool equals(T a, T b) {
    if (options?.equals != null) {
      return options!.equals!(a, b);
    }
    return a == b;
  }
}
