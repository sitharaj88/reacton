import '../core/reacton_base.dart';

/// A function that can be called to clean up an effect.
typedef EffectCleanup = void Function();

/// An effect node that runs side effects when dependencies change.
///
/// Effects are created via the top-level [effect()] function and
/// automatically track their dependencies.
class EffectNode {
  /// Unique identity for this effect.
  final ReactonRef ref;

  /// The effect function.
  final EffectCleanup? Function(ReactonReader read) _run;

  /// Cleanup function from the last run.
  EffectCleanup? cleanup;

  EffectNode(this._run, {String? name})
      : ref = ReactonRef(debugName: name ?? 'effect');

  /// Run the effect and return the cleanup function.
  EffectCleanup? run(ReactonReader read) => _run(read);
}

/// Create a side effect that automatically tracks its dependencies.
///
/// The effect function receives a [read] function. Any reactons read
/// during execution become dependencies - the effect re-runs when
/// they change.
///
/// Optionally return a cleanup function that runs before the next
/// execution or when the effect is disposed.
///
/// ```dart
/// final dispose = effect((read) {
///   final count = read(counterReacton);
///   print('Counter changed to: $count');
///   return () => print('Cleaning up');
/// });
///
/// // Later: dispose the effect
/// dispose();
/// ```
EffectNode createEffect(
  EffectCleanup? Function(ReactonReader read) fn, {
  String? name,
}) {
  return EffectNode(fn, name: name);
}
