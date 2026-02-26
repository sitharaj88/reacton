import '../core/reacton_base.dart';
import '../core/writable_reacton.dart';
import '../store/store.dart';

/// A state branch - an isolated copy-on-write overlay on the parent store.
///
/// Changes made to a branch do not affect the parent store until
/// explicitly merged. This enables speculative updates, A/B testing,
/// and preview features.
///
/// ```dart
/// final branch = store.createBranch('dark-theme-preview');
/// branch.set(themeReacton, ThemeData.dark());
/// // Preview without affecting main state
/// print(branch.get(themeReacton)); // dark theme
/// print(store.get(themeReacton));  // still light theme
///
/// // Apply changes
/// store.mergeBranch(branch);
/// ```
class StateBranch {
  /// Name of this branch.
  final String name;

  /// The parent store this branch was created from.
  final ReactonStore parentStore;

  /// Copy-on-write overrides (only stores values that differ from parent).
  final Map<ReactonRef, dynamic> _overrides = {};

  /// When this branch was created.
  final DateTime createdAt;

  bool _merged = false;
  bool _discarded = false;

  StateBranch(this.name, this.parentStore) : createdAt = DateTime.now();

  /// Whether this branch has been merged or discarded.
  bool get isClosed => _merged || _discarded;

  /// Whether this branch has been merged into the parent.
  bool get isMerged => _merged;

  /// Whether this branch has been discarded.
  bool get isDiscarded => _discarded;

  /// Read: check overrides first, then fall back to parent.
  T get<T>(ReactonBase<T> reacton) {
    if (_overrides.containsKey(reacton.ref)) {
      return _overrides[reacton.ref] as T;
    }
    return parentStore.get(reacton);
  }

  /// Write: only modifies the branch, not the parent.
  void set<T>(WritableReacton<T> reacton, T value) {
    assert(!isClosed, 'Cannot modify a closed branch');
    _overrides[reacton.ref] = value;
  }

  /// Update a value using a function.
  void update<T>(WritableReacton<T> reacton, T Function(T current) updater) {
    set(reacton, updater(get(reacton)));
  }

  /// Get all reactons that have been modified in this branch.
  Set<ReactonRef> get modifiedReactons => _overrides.keys.toSet();

  /// Get all reactons that differ from the parent.
  BranchDiff diff() {
    final changes = <ReactonRef, BranchChange>{};
    for (final entry in _overrides.entries) {
      final parentValue = parentStore.getByRef(entry.key);
      changes[entry.key] = BranchChange(
        ref: entry.key,
        parentValue: parentValue,
        branchValue: entry.value,
      );
    }
    return BranchDiff(name, changes);
  }

  /// Discard this branch, clearing all overrides.
  void discard() {
    assert(!isClosed, 'Branch is already closed');
    _discarded = true;
    _overrides.clear();
  }

  /// Mark this branch as merged.
  void markMerged() {
    _merged = true;
  }
}

/// A single change in a branch.
class BranchChange {
  final ReactonRef ref;
  final dynamic parentValue;
  final dynamic branchValue;

  const BranchChange({
    required this.ref,
    required this.parentValue,
    required this.branchValue,
  });

  bool get hasChanged => parentValue != branchValue;
}

/// The complete set of differences between a branch and its parent.
class BranchDiff {
  final String branchName;
  final Map<ReactonRef, BranchChange> changes;

  const BranchDiff(this.branchName, this.changes);

  bool get isEmpty => changes.isEmpty;
  bool get isNotEmpty => changes.isNotEmpty;
  int get changeCount => changes.length;
}

/// Strategy for resolving conflicts when merging a branch.
enum MergeStrategy {
  /// Use the branch's values (default).
  theirs,

  /// Keep the parent's values.
  ours,
}

/// Extension on ReactonStore for branch operations.
extension ReactonStoreBranching on ReactonStore {
  /// Create a new state branch.
  StateBranch createBranch(String name) {
    return StateBranch(name, this);
  }

  /// Merge a branch's changes into this store.
  void mergeBranch(StateBranch branch, {MergeStrategy strategy = MergeStrategy.theirs}) {
    assert(!branch.isClosed, 'Cannot merge a closed branch');
    assert(identical(branch.parentStore, this), 'Branch belongs to a different store');

    final diff = branch.diff();
    batch(() {
      for (final change in diff.changes.values) {
        switch (strategy) {
          case MergeStrategy.theirs:
            _applyBranchChange(change);
          case MergeStrategy.ours:
            // Keep current value -- no-op
            break;
        }
      }
    });

    branch.markMerged();
  }

  void _applyBranchChange(BranchChange change) {
    // We need to find the reacton and use set() to trigger propagation.
    // For now, directly update the value and mark dirty.
    setByRefId(change.ref.id, change.branchValue);
  }
}
