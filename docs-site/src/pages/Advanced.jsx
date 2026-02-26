import CodeBlock from '../components/CodeBlock'
import Callout from '../components/Callout'
import PageNav from '../components/PageNav'

export default function Advanced() {
  return (
    <div>
      <h1 id="advanced-features" className="text-4xl font-extrabold tracking-tight mb-4">
        Advanced Features
      </h1>
      <p className="text-lg text-gray-500 dark:text-gray-400 mb-8">
        State branching, time travel, multi-isolate sharing, snapshots, incremental computation,
        and performance optimization. These are the power-user features that unlock Reacton's full potential.
      </p>

      {/* ============================================================ */}
      {/* STATE BRANCHING                                               */}
      {/* ============================================================ */}
      <h2 id="branching" className="text-2xl font-bold mt-12 mb-4">
        State Branching
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        State branching gives you Git-like branching for your entire application state. You can
        create an isolated copy of the store, make modifications freely without touching the
        original state, inspect what changed, and then either merge those changes back or throw
        them away. This is one of Reacton's most powerful features and enables patterns that are
        extremely difficult to achieve with traditional state management.
      </p>

      {/* Branching - Creating a Branch */}
      <h3 id="branching-create" className="text-xl font-semibold mt-8 mb-3">
        Creating a Branch
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.createBranch('name')</code>
        {' '}to create a new branch. The name is used for debugging and DevTools identification.
        The returned{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">StoreBranch</code>
        {' '}object acts like a mini-store with its own{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">get</code>
        {' '}and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">set</code>
        {' '}methods.
      </p>
      <CodeBlock
        title="Creating a branch"
        code={`final store = ReactonStore();

// Define some atoms
final nameAtom = atom('Alice');
final themeAtom = atom(ThemeMode.light);
final settingsAtom = atom(AppSettings.defaults());

// Create a branch — this is instant, no data is copied yet
final branch = store.createBranch('draft-settings');

// The branch is now a live, isolated workspace
print(branch.name); // 'draft-settings'`}
      />

      {/* Branching - Copy-on-Write */}
      <h3 id="branching-cow" className="text-xl font-semibold mt-8 mb-3">
        Copy-on-Write Semantics
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Branches use <strong className="text-gray-900 dark:text-white">copy-on-write</strong> semantics,
        which means creating a branch is essentially free. No atom values are duplicated at creation time.
        Instead, the branch maintains a thin overlay on top of the parent store:
      </p>
      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400">
        <li>
          <strong className="text-gray-900 dark:text-white">Reads</strong> fall through to the parent.
          If you read an atom that has not been modified in the branch, the branch transparently returns
          the parent store's value. There is no copy.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Writes</strong> stay in the branch.
          The first time you write to an atom in a branch, a copy is made and the new value is stored
          in the branch's overlay. The parent store is completely untouched.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Subsequent reads</strong> of a modified atom
          return the branch's local copy, not the parent's value.
        </li>
      </ul>
      <CodeBlock
        title="Copy-on-write in action"
        code={`final branch = store.createBranch('experiment');

// Reading — falls through to parent
final currentName = branch.get(nameAtom);
print(currentName); // 'Alice' (from parent store)

// Writing — creates a local copy in the branch
branch.set(nameAtom, 'Bob');

// Now reads return the branch's local value
print(branch.get(nameAtom)); // 'Bob'

// Parent is completely unaffected
print(store.get(nameAtom)); // 'Alice'

// Atoms that were never written still fall through
print(branch.get(themeAtom)); // ThemeMode.light (from parent)`}
      />

      <Callout type="info" title="Memory Efficiency">
        Because of copy-on-write, a branch that modifies 3 out of 100 atoms only stores those 3 values.
        The other 97 atoms consume zero additional memory. This makes branches viable even in
        memory-constrained mobile environments.
      </Callout>

      {/* Branching - Diff */}
      <h3 id="branching-diff" className="text-xl font-semibold mt-8 mb-3">
        Branch Diff
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Before merging, you can inspect exactly what a branch has changed relative to its parent using{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">branch.diff()</code>.
        This returns a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">BranchDiff</code>
        {' '}object containing every atom that was modified, along with the old (parent) and new (branch) values.
      </p>
      <CodeBlock
        title="Inspecting branch changes"
        code={`final branch = store.createBranch('edits');
branch.set(nameAtom, 'Charlie');
branch.set(settingsAtom, AppSettings(darkMode: true, fontSize: 18));

final diff = branch.diff();

// See all changed atoms
print(diff.changes.length); // 2

// Iterate over changes
for (final change in diff.changes.entries) {
  print('Atom: \${change.key}');
  print('  Parent value: \${change.value.parentValue}');
  print('  Branch value: \${change.value.branchValue}');
}

// Check if a specific atom was modified
print(diff.hasChanged(nameAtom));     // true
print(diff.hasChanged(themeAtom));    // false

// Get a summary for logging/debugging
print(diff.summary());
// 'BranchDiff(edits): 2 atoms changed [nameAtom, settingsAtom]'`}
      />

      {/* Branching - Merging */}
      <h3 id="branching-merge" className="text-xl font-semibold mt-8 mb-3">
        Merging Branches
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        When you are satisfied with the changes in a branch, apply them to the parent store
        with{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.mergeBranch(branch)</code>.
        This atomically copies every modified value from the branch into the parent store and
        notifies all subscribers of the changed atoms.
      </p>
      <CodeBlock
        title="Merging branch changes"
        code={`final branch = store.createBranch('user-edits');

// Make several changes
branch.set(nameAtom, 'Diana');
branch.set(settingsAtom, AppSettings(darkMode: true));

// Merge everything back into the parent store
store.mergeBranch(branch);

// Parent store now has the branch's values
print(store.get(nameAtom));     // 'Diana'
print(store.get(settingsAtom)); // AppSettings(darkMode: true)

// All subscribers are notified of the changes
// UI rebuilds happen automatically`}
      />

      {/* Branching - Merge Strategies */}
      <h3 id="branching-merge-strategies" className="text-xl font-semibold mt-8 mb-3">
        Merge Strategies
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        If the parent store has also been modified since the branch was created, you may have
        conflicting changes. Reacton provides merge strategies to handle this, similar to Git
        merge strategies:
      </p>
      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400">
        <li>
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">MergeStrategy.ours</code>
          {' '}&mdash; Branch values always win. If both the parent and branch modified the same atom, the branch value is used.
        </li>
        <li>
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">MergeStrategy.theirs</code>
          {' '}&mdash; Parent values always win. Conflicting atoms keep their parent store value; only non-conflicting branch changes are applied.
        </li>
        <li>
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">MergeStrategy.custom</code>
          {' '}&mdash; You provide a resolver function that decides per-atom which value to keep.
        </li>
      </ul>
      <CodeBlock
        title="Merge strategies"
        code={`// Default: branch values win (ours)
store.mergeBranch(branch, strategy: MergeStrategy.ours);

// Parent values win on conflicts
store.mergeBranch(branch, strategy: MergeStrategy.theirs);

// Custom resolver for fine-grained control
store.mergeBranch(branch, strategy: MergeStrategy.custom(
  (conflict) {
    // conflict.atom       — the atom in question
    // conflict.parentValue — current value in the parent store
    // conflict.branchValue — value in the branch

    if (conflict.atom == criticalSettingAtom) {
      // For critical settings, always take the parent value
      return conflict.parentValue;
    }
    // For everything else, take the branch value
    return conflict.branchValue;
  },
));`}
      />

      <Callout type="tip" title="When to use custom merge strategies">
        Custom merge strategies are especially useful in collaborative editing scenarios
        or when you have atoms with "append-only" semantics (like a log list) where you want
        to combine both values rather than picking one.
      </Callout>

      {/* Branching - Discard */}
      <h3 id="branching-discard" className="text-xl font-semibold mt-8 mb-3">
        Discarding a Branch
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        If you decide the branch's changes are not needed, call{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">branch.discard()</code>
        {' '}to throw away all modifications and free the branch's memory. The parent store is
        completely unaffected.
      </p>
      <CodeBlock
        title="Discarding changes"
        code={`final branch = store.createBranch('risky-changes');

branch.set(nameAtom, 'DANGER');
branch.set(settingsAtom, AppSettings.broken());

// Changed our mind — throw it all away
branch.discard();

// Parent store is untouched
print(store.get(nameAtom)); // 'Alice' (original value)

// The branch is now invalid — using it will throw
// branch.get(nameAtom); // throws BranchDiscardedError`}
      />

      {/* Branching - Nested */}
      <h3 id="branching-nested" className="text-xl font-semibold mt-8 mb-3">
        Nested Branches
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        You can create branches from other branches, forming a tree of state overlays. Each
        child branch reads from its direct parent branch (not the root store), and writes
        stay local. This is useful for multi-level "what-if" exploration.
      </p>
      <CodeBlock
        title="Nested branches"
        code={`final store = ReactonStore();
store.set(counterAtom, 0);

// Level 1 branch
final branchA = store.createBranch('level-1');
branchA.set(counterAtom, 10);

// Level 2 branch — reads from branchA, not from store
final branchB = branchA.createBranch('level-2');
print(branchB.get(counterAtom)); // 10 (from branchA)

branchB.set(counterAtom, 20);
print(branchB.get(counterAtom)); // 20 (local)
print(branchA.get(counterAtom)); // 10 (unaffected)
print(store.get(counterAtom));   // 0  (unaffected)

// Merge level-2 into level-1
branchA.mergeBranch(branchB);
print(branchA.get(counterAtom)); // 20

// Then merge level-1 into the root store
store.mergeBranch(branchA);
print(store.get(counterAtom));   // 20`}
      />

      {/* Branching - Real-World Examples */}
      <h3 id="branching-examples" className="text-xl font-semibold mt-8 mb-3">
        Real-World Examples
      </h3>

      <h4 id="branching-example-form" className="text-lg font-medium mt-6 mb-3 text-gray-800 dark:text-gray-200">
        Form Draft Editing
      </h4>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The most common use case: allow users to edit settings in a form without affecting the
        live application state. Only apply the changes when the user explicitly saves.
      </p>
      <CodeBlock
        title="Form draft with branching"
        code={`// Atoms for user profile settings
final displayNameAtom = atom('Alice');
final bioAtom = atom('Flutter developer');
final notificationsAtom = atom(true);
final themeAtom = atom(ThemeMode.light);

class ProfileEditPage extends StatefulWidget {
  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final StoreBranch _draft;

  @override
  void initState() {
    super.initState();
    // Create a draft branch — all edits happen here
    _draft = store.createBranch('profile-edit');
  }

  @override
  void dispose() {
    // If the user navigates away without saving, discard
    if (!_draft.isDiscarded && !_draft.isMerged) {
      _draft.discard();
    }
    super.dispose();
  }

  void _save() {
    // Apply all draft changes to the real store
    store.mergeBranch(_draft);
    Navigator.of(context).pop();
  }

  void _cancel() {
    // Throw away all changes
    _draft.discard();
    Navigator.of(context).pop();
  }

  void _resetToDefaults() {
    // Discard current draft and create a fresh one
    _draft.discard();
    setState(() {
      _draft = store.createBranch('profile-edit');
      // Set default values in the new branch
      _draft.set(displayNameAtom, 'New User');
      _draft.set(bioAtom, '');
      _draft.set(notificationsAtom, true);
      _draft.set(themeAtom, ThemeMode.system);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        actions: [
          TextButton(onPressed: _cancel, child: Text('Cancel')),
          FilledButton(onPressed: _save, child: Text('Save')),
        ],
      ),
      body: Column(
        children: [
          // Use ReactonBuilder with the branch, not the main store
          ReactonBuilder(
            store: _draft,
            atom: displayNameAtom,
            builder: (context, name) => TextField(
              controller: TextEditingController(text: name),
              onChanged: (v) => _draft.set(displayNameAtom, v),
              decoration: InputDecoration(labelText: 'Display Name'),
            ),
          ),
          ReactonBuilder(
            store: _draft,
            atom: bioAtom,
            builder: (context, bio) => TextField(
              controller: TextEditingController(text: bio),
              onChanged: (v) => _draft.set(bioAtom, v),
              decoration: InputDecoration(labelText: 'Bio'),
            ),
          ),
          ReactonBuilder(
            store: _draft,
            atom: notificationsAtom,
            builder: (context, enabled) => SwitchListTile(
              title: Text('Notifications'),
              value: enabled,
              onChanged: (v) => _draft.set(notificationsAtom, v),
            ),
          ),
          // Show diff preview
          TextButton(
            onPressed: () {
              final diff = _draft.diff();
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('Pending Changes'),
                  content: Text(
                    diff.changes.isEmpty
                      ? 'No changes yet.'
                      : diff.summary(),
                  ),
                ),
              );
            },
            child: Text('Preview Changes'),
          ),
        ],
      ),
    );
  }
}`}
      />

      <h4 id="branching-example-theme" className="text-lg font-medium mt-6 mb-3 text-gray-800 dark:text-gray-200">
        Theme Preview
      </h4>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Let users try out a new theme without committing to it. The rest of the app continues
        with the current theme while the preview screen shows the candidate.
      </p>
      <CodeBlock
        title="Theme preview with branching"
        code={`final primaryColorAtom = atom(Colors.indigo);
final fontFamilyAtom = atom('Roboto');
final borderRadiusAtom = atom(8.0);

class ThemePreviewSheet extends StatefulWidget {
  @override
  State<ThemePreviewSheet> createState() => _ThemePreviewSheetState();
}

class _ThemePreviewSheetState extends State<ThemePreviewSheet> {
  late StoreBranch _preview;

  @override
  void initState() {
    super.initState();
    _preview = store.createBranch('theme-preview');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Preview Theme', style: Theme.of(context).textTheme.titleLarge),

        // Color picker modifies the branch only
        ColorPicker(
          initialColor: _preview.get(primaryColorAtom),
          onColorChanged: (c) => _preview.set(primaryColorAtom, c),
        ),

        // Font selector
        DropdownButton<String>(
          value: _preview.get(fontFamilyAtom),
          items: ['Roboto', 'Lato', 'Poppins', 'Montserrat']
              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
              .toList(),
          onChanged: (f) => _preview.set(fontFamilyAtom, f!),
        ),

        // Live preview panel uses branch values
        ReactonBuilder(
          store: _preview,
          atom: primaryColorAtom,
          builder: (context, color) => Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                _preview.get(borderRadiusAtom),
              ),
            ),
            child: Text(
              'Preview Text',
              style: TextStyle(
                color: color,
                fontFamily: _preview.get(fontFamilyAtom),
              ),
            ),
          ),
        ),

        Row(
          children: [
            OutlinedButton(
              onPressed: () {
                _preview.discard();
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                // User likes the theme — apply it app-wide
                store.mergeBranch(_preview);
                Navigator.pop(context);
              },
              child: Text('Apply Theme'),
            ),
          ],
        ),
      ],
    );
  }
}`}
      />

      <h4 id="branching-example-wizard" className="text-lg font-medium mt-6 mb-3 text-gray-800 dark:text-gray-200">
        Multi-Step Wizard with Rollback
      </h4>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Use nested branches for a multi-step wizard where each step can be individually
        rolled back without affecting previous steps.
      </p>
      <CodeBlock
        title="Multi-step wizard"
        code={`class WizardController {
  final ReactonStore store;
  late StoreBranch _wizardBranch;
  final List<StoreBranch> _stepBranches = [];
  int _currentStep = 0;

  WizardController(this.store) {
    // One parent branch for the entire wizard
    _wizardBranch = store.createBranch('wizard');
    _startNewStep();
  }

  StoreBranch get currentStepBranch => _stepBranches.last;

  void _startNewStep() {
    // Each step gets its own sub-branch
    final parent = _stepBranches.isEmpty
        ? _wizardBranch
        : _stepBranches.last;
    _stepBranches.add(parent.createBranch('step-\$_currentStep'));
  }

  /// Commit current step and move to next
  void nextStep() {
    final current = _stepBranches.last;
    final parent = _stepBranches.length > 1
        ? _stepBranches[_stepBranches.length - 2]
        : _wizardBranch;

    // Merge this step's changes into its parent
    parent.mergeBranch(current);
    _currentStep++;
    _startNewStep();
  }

  /// Undo the current step (discard changes, go back)
  void previousStep() {
    if (_stepBranches.length <= 1) return;

    // Discard current step
    _stepBranches.removeLast().discard();
    _currentStep--;
  }

  /// Complete the wizard — apply everything to the main store
  void complete() {
    // Merge the last step into the wizard branch
    final current = _stepBranches.last;
    _wizardBranch.mergeBranch(current);

    // Merge the wizard branch into the main store
    store.mergeBranch(_wizardBranch);
  }

  /// Cancel the entire wizard — nothing is applied
  void cancel() {
    // Discarding the parent automatically invalidates children
    _wizardBranch.discard();
  }
}`}
      />

      <h4 id="branching-example-ab" className="text-lg font-medium mt-6 mb-3 text-gray-800 dark:text-gray-200">
        A/B State Testing
      </h4>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Compare two different state configurations side-by-side without affecting the live app.
      </p>
      <CodeBlock
        title="A/B state comparison"
        code={`final pricingAtom = atom(PricingConfig.standard());
final layoutAtom = atom(LayoutConfig.classic());

// Create two alternative configurations
final variantA = store.createBranch('variant-a');
variantA.set(pricingAtom, PricingConfig.premium());
variantA.set(layoutAtom, LayoutConfig.modern());

final variantB = store.createBranch('variant-b');
variantB.set(pricingAtom, PricingConfig.freemium());
variantB.set(layoutAtom, LayoutConfig.minimal());

// Compare diffs
final diffA = variantA.diff();
final diffB = variantB.diff();

print('Variant A changes: \${diffA.changes.length}');
print('Variant B changes: \${diffB.changes.length}');

// User or analytics decides the winner
final winner = await runABTest(variantA, variantB);
store.mergeBranch(winner);

// Discard the loser
(winner == variantA ? variantB : variantA).discard();`}
      />

      <Callout type="info" title="Performance Characteristics">
        <p className="mb-2">
          Branch creation is <strong>O(1)</strong> thanks to copy-on-write. Memory usage
          is proportional only to the number of atoms actually modified in the branch, not
          the total number of atoms in the store. Merging is <strong>O(k)</strong> where
          <em> k</em> is the number of modified atoms. For a typical form-editing use case
          modifying 5-10 atoms, branching and merging are effectively instantaneous.
        </p>
      </Callout>

      {/* ============================================================ */}
      {/* TIME TRAVEL                                                   */}
      {/* ============================================================ */}
      <h2 id="time-travel" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Time Travel
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Time travel gives you full undo/redo capability with the ability to jump to any point
        in an atom's history. Reacton records a configurable number of historical values with
        timestamps, and exposes a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">History&lt;T&gt;</code>
        {' '}controller for navigating through them.
      </p>

      {/* Time Travel - Enabling */}
      <h3 id="time-travel-enable" className="text-xl font-semibold mt-8 mb-3">
        Enabling Time Travel
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Call{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.enableHistory(atom, maxHistory: 50)</code>
        {' '}on any atom to start recording its value changes. The returned{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">History&lt;T&gt;</code>
        {' '}controller is your handle for navigating history.
      </p>
      <CodeBlock
        title="Enabling history"
        code={`final counterAtom = atom(0);
final textAtom = atom('');

// Enable history with default limit (50 entries)
final counterHistory = store.enableHistory(counterAtom);

// Enable with custom limit
final textHistory = store.enableHistory(textAtom, maxHistory: 200);

// The initial value is recorded as the first history entry
print(counterHistory.entries.length); // 1
print(counterHistory.entries.first.value); // 0`}
      />

      {/* Time Travel - API */}
      <h3 id="time-travel-api" className="text-xl font-semibold mt-8 mb-3">
        History Controller API
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">History&lt;T&gt;</code>
        {' '}class provides a complete API for navigating, inspecting, and managing state history:
      </p>

      <div className="overflow-x-auto mb-6">
        <table className="min-w-full text-sm border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
          <thead>
            <tr className="bg-gray-50 dark:bg-gray-800/50">
              <th className="text-left px-4 py-3 font-semibold text-gray-900 dark:text-white border-b border-gray-200 dark:border-gray-700">Method / Property</th>
              <th className="text-left px-4 py-3 font-semibold text-gray-900 dark:text-white border-b border-gray-200 dark:border-gray-700">Type</th>
              <th className="text-left px-4 py-3 font-semibold text-gray-900 dark:text-white border-b border-gray-200 dark:border-gray-700">Description</th>
            </tr>
          </thead>
          <tbody className="text-gray-600 dark:text-gray-400">
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="px-4 py-2.5 font-mono text-indigo-600 dark:text-indigo-400">undo()</td>
              <td className="px-4 py-2.5">void</td>
              <td className="px-4 py-2.5">Move back one step in history. No-op if at the beginning.</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="px-4 py-2.5 font-mono text-indigo-600 dark:text-indigo-400">redo()</td>
              <td className="px-4 py-2.5">void</td>
              <td className="px-4 py-2.5">Move forward one step. No-op if at the end.</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="px-4 py-2.5 font-mono text-indigo-600 dark:text-indigo-400">jumpTo(index)</td>
              <td className="px-4 py-2.5">void</td>
              <td className="px-4 py-2.5">Jump directly to any entry by index. Throws if out of range.</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="px-4 py-2.5 font-mono text-indigo-600 dark:text-indigo-400">canUndo</td>
              <td className="px-4 py-2.5">bool</td>
              <td className="px-4 py-2.5">True if there is at least one previous entry to undo to.</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="px-4 py-2.5 font-mono text-indigo-600 dark:text-indigo-400">canRedo</td>
              <td className="px-4 py-2.5">bool</td>
              <td className="px-4 py-2.5">True if there is at least one future entry to redo to.</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="px-4 py-2.5 font-mono text-indigo-600 dark:text-indigo-400">entries</td>
              <td className="px-4 py-2.5">{'List<HistoryEntry<T>>'}</td>
              <td className="px-4 py-2.5">All recorded entries. Each has a value and timestamp.</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="px-4 py-2.5 font-mono text-indigo-600 dark:text-indigo-400">currentIndex</td>
              <td className="px-4 py-2.5">int</td>
              <td className="px-4 py-2.5">The index of the currently active entry in the entries list.</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="px-4 py-2.5 font-mono text-indigo-600 dark:text-indigo-400">clear()</td>
              <td className="px-4 py-2.5">void</td>
              <td className="px-4 py-2.5">Remove all history. The current value is kept as the sole entry.</td>
            </tr>
            <tr>
              <td className="px-4 py-2.5 font-mono text-indigo-600 dark:text-indigo-400">dispose()</td>
              <td className="px-4 py-2.5">void</td>
              <td className="px-4 py-2.5">Stop tracking history and free memory. Cannot be used after this.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <CodeBlock
        title="Complete History API usage"
        code={`final counterAtom = atom(0);
final history = store.enableHistory(counterAtom, maxHistory: 50);

// Make some changes
store.set(counterAtom, 10);
store.set(counterAtom, 20);
store.set(counterAtom, 30);

// History: [0, 10, 20, 30]  currentIndex: 3
print(history.entries.length); // 4
print(history.currentIndex);  // 3
print(history.canUndo);       // true
print(history.canRedo);       // false

// Undo
history.undo(); // value -> 20, currentIndex -> 2
history.undo(); // value -> 10, currentIndex -> 1

print(store.get(counterAtom)); // 10
print(history.canUndo);        // true
print(history.canRedo);        // true

// Redo
history.redo(); // value -> 20, currentIndex -> 2

// Jump to a specific point
history.jumpTo(0); // value -> 0 (initial value)
print(store.get(counterAtom)); // 0

// Jump to the latest
history.jumpTo(history.entries.length - 1); // value -> 30

// Inspect entries
for (final entry in history.entries) {
  print('Value: \${entry.value}, Time: \${entry.timestamp}');
}

// Clear history (keeps current value)
history.clear();
print(history.entries.length); // 1 (just the current value)

// Clean up when done
history.dispose();`}
      />

      {/* Time Travel - Fork Behavior */}
      <h3 id="time-travel-fork" className="text-xl font-semibold mt-8 mb-3">
        Fork Behavior
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        When you make a new change after undoing, the "future" entries are discarded. This is
        identical to how Git works: if you go back in history and start making new commits,
        the old forward history is lost.
      </p>
      <CodeBlock
        title="Fork behavior"
        code={`final atom = atom(0);
final history = store.enableHistory(atom);

store.set(atom, 1);
store.set(atom, 2);
store.set(atom, 3);
// History: [0, 1, 2, 3]  currentIndex: 3

history.undo(); // -> 2
history.undo(); // -> 1
// History: [0, 1, 2, 3]  currentIndex: 1
// canRedo is true (entries 2 and 3 are in the future)

// Now make a NEW change — this forks the timeline
store.set(atom, 99);
// History: [0, 1, 99]  currentIndex: 2
// The old future [2, 3] is gone forever

print(history.canRedo); // false — no future to redo to
print(history.entries.length); // 3`}
      />

      <Callout type="warning" title="Fork discards future entries">
        Once you make a new change after undoing, the discarded future entries cannot be recovered.
        If you need to preserve all possible timelines, consider using state branching instead,
        where you can create a branch before making the new change.
      </Callout>

      {/* Time Travel - Max History */}
      <h3 id="time-travel-max-history" className="text-xl font-semibold mt-8 mb-3">
        Max History Limit
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">maxHistory</code>
        {' '}parameter controls how many entries are kept. When the limit is reached, the oldest
        entries are dropped first (FIFO). This prevents unbounded memory growth for atoms that
        change frequently.
      </p>
      <CodeBlock
        title="Max history behavior"
        code={`final atom = atom(0);
final history = store.enableHistory(atom, maxHistory: 3);

store.set(atom, 1);
store.set(atom, 2);
store.set(atom, 3); // maxHistory reached

// History: [1, 2, 3]  — the initial 0 was dropped
print(history.entries.length); // 3

store.set(atom, 4);
// History: [2, 3, 4]  — entry with value 1 was dropped
print(history.entries.first.value); // 2`}
      />

      {/* Time Travel - UI Example */}
      <h3 id="time-travel-ui" className="text-xl font-semibold mt-8 mb-3">
        Undo/Redo Toolbar Widget
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Here is a reusable toolbar widget that provides undo, redo, and history navigation
        controls for any atom with history enabled.
      </p>
      <CodeBlock
        title="Undo/Redo toolbar widget"
        code={`class UndoRedoToolbar<T> extends StatelessWidget {
  final History<T> history;
  final String? label;

  const UndoRedoToolbar({
    required this.history,
    this.label,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: history,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null) ...[
              Text(
                label!,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Undo button
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: history.canUndo ? () => history.undo() : null,
              tooltip: 'Undo',
            ),

            // Redo button
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: history.canRedo ? () => history.redo() : null,
              tooltip: 'Redo',
            ),

            // History position indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '\${history.currentIndex + 1} / \${history.entries.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(width: 4),

            // History slider for jump-to
            if (history.entries.length > 1)
              Expanded(
                child: Slider(
                  value: history.currentIndex.toDouble(),
                  min: 0,
                  max: (history.entries.length - 1).toDouble(),
                  divisions: history.entries.length - 1,
                  onChanged: (v) => history.jumpTo(v.round()),
                ),
              ),
          ],
        );
      },
    );
  }
}`}
      />

      {/* Time Travel - Text Editor Example */}
      <h3 id="time-travel-text-editor" className="text-xl font-semibold mt-8 mb-3">
        Example: Text Editor with Undo/Redo
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        A complete text editor example that uses time travel for undo/redo. Changes are
        debounced so each "undo step" represents a meaningful edit, not every keystroke.
      </p>
      <CodeBlock
        title="Text editor with time travel"
        code={`final documentAtom = atom('');
final documentHistory = store.enableHistory(documentAtom, maxHistory: 100);

class TextEditorPage extends StatefulWidget {
  @override
  State<TextEditorPage> createState() => _TextEditorPageState();
}

class _TextEditorPageState extends State<TextEditorPage> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: store.get(documentAtom));
  }

  void _onTextChanged(String text) {
    // Debounce: only record a history entry after 500ms of no typing
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      store.set(documentAtom, text);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Editor'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: UndoRedoToolbar(
              history: documentHistory,
              label: 'Document',
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ReactonBuilder(
          atom: documentAtom,
          builder: (context, text) {
            // Sync controller when history navigation changes the value
            if (_controller.text != text) {
              _controller.text = text;
              _controller.selection = TextSelection.collapsed(
                offset: text.length,
              );
            }
            return TextField(
              controller: _controller,
              onChanged: _onTextChanged,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                hintText: 'Start typing...',
                border: OutlineInputBorder(),
              ),
            );
          },
        ),
      ),
      // Keyboard shortcuts
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
            const UndoIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyZ,
        ): const RedoIntent(),
      },
      actions: {
        UndoIntent: CallbackAction<UndoIntent>(
          onInvoke: (_) {
            if (documentHistory.canUndo) documentHistory.undo();
            return null;
          },
        ),
        RedoIntent: CallbackAction<RedoIntent>(
          onInvoke: (_) {
            if (documentHistory.canRedo) documentHistory.redo();
            return null;
          },
        ),
      },
    );
  }
}

class UndoIntent extends Intent { const UndoIntent(); }
class RedoIntent extends Intent { const RedoIntent(); }`}
      />

      {/* Time Travel - Drawing App Example */}
      <h3 id="time-travel-drawing" className="text-xl font-semibold mt-8 mb-3">
        Example: Drawing App with Stroke History
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        A drawing app where each completed stroke is a single history entry. Users can undo
        and redo individual strokes.
      </p>
      <CodeBlock
        title="Drawing app with stroke history"
        code={`class Stroke {
  final List<Offset> points;
  final Color color;
  final double width;

  const Stroke({
    required this.points,
    required this.color,
    required this.width,
  });
}

final strokesAtom = atom<List<Stroke>>([]);
final strokesHistory = store.enableHistory(strokesAtom, maxHistory: 50);

class DrawingCanvas extends StatefulWidget {
  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<Offset> _currentPoints = [];
  Color _currentColor = Colors.black;
  double _currentWidth = 3.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Undo/Redo toolbar
        UndoRedoToolbar(history: strokesHistory, label: 'Strokes'),

        // Color and width controls
        Row(
          children: [
            for (final color in [Colors.black, Colors.red, Colors.blue, Colors.green])
              GestureDetector(
                onTap: () => setState(() => _currentColor = color),
                child: Container(
                  width: 32, height: 32,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: _currentColor == color
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                ),
              ),
            Expanded(
              child: Slider(
                value: _currentWidth,
                min: 1, max: 20,
                onChanged: (v) => setState(() => _currentWidth = v),
              ),
            ),
          ],
        ),

        // Canvas
        Expanded(
          child: ReactonBuilder(
            atom: strokesAtom,
            builder: (context, strokes) {
              return GestureDetector(
                onPanStart: (d) {
                  _currentPoints = [d.localPosition];
                },
                onPanUpdate: (d) {
                  setState(() {
                    _currentPoints = [..._currentPoints, d.localPosition];
                  });
                },
                onPanEnd: (_) {
                  // Stroke complete — add to atom (triggers history entry)
                  final newStroke = Stroke(
                    points: _currentPoints,
                    color: _currentColor,
                    width: _currentWidth,
                  );
                  store.set(strokesAtom, [...strokes, newStroke]);
                  _currentPoints = [];
                },
                child: CustomPaint(
                  painter: StrokePainter(
                    strokes: strokes,
                    currentPoints: _currentPoints,
                    currentColor: _currentColor,
                    currentWidth: _currentWidth,
                  ),
                  size: Size.infinite,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class StrokePainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;

  StrokePainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      if (stroke.points.isNotEmpty) {
        path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (final point in stroke.points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, paint);
    }

    // Draw current in-progress stroke
    if (currentPoints.isNotEmpty) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(currentPoints.first.dx, currentPoints.first.dy);
      for (final point in currentPoints.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StrokePainter old) => true;
}`}
      />

      {/* Time Travel - Performance */}
      <h3 id="time-travel-performance" className="text-xl font-semibold mt-8 mb-3">
        Performance Tips
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Time travel stores copies of atom values, so memory usage grows with history size and
        value complexity. Here are guidelines for tuning:
      </p>
      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400">
        <li>
          <strong className="text-gray-900 dark:text-white">Small primitives</strong> (int, String, bool):
          {' '}Use{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">maxHistory: 100-500</code>
          {' '}freely. Memory impact is negligible.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Medium objects</strong> (data classes, small lists):
          {' '}Use{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">maxHistory: 20-50</code>.
          Each entry stores a full copy of the value.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Large collections</strong> (lists of hundreds of items):
          {' '}Use{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">maxHistory: 5-20</code>
          {' '}or consider tracking only the change delta rather than the full list.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Debounce frequent updates</strong>:
          For text fields or sliders, debounce changes so each history entry represents a meaningful
          edit rather than every single keystroke or pixel movement.
        </li>
      </ul>
      <Callout type="tip" title="Combine with branching">
        For coarse-grained undo (like "undo all changes in this editing session"), state branching
        is often more appropriate than time travel. Use time travel for fine-grained, per-atom
        undo/redo, and branching for session-level rollback.
      </Callout>

      {/* ============================================================ */}
      {/* ACTION LOG                                                    */}
      {/* ============================================================ */}
      <h2 id="action-log" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Action Log
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ActionLog</code>
        {' '}provides a complete, inspectable audit trail of every state mutation that occurs in
        your store. Every time an atom's value changes, the log records the atom reference,
        the old value, the new value, and a high-resolution timestamp. This is invaluable for
        debugging, analytics, and building replay/playback features.
      </p>

      <h3 id="action-log-setup" className="text-xl font-semibold mt-8 mb-3">
        Setting Up the Action Log
      </h3>
      <CodeBlock
        title="ActionLog setup"
        code={`final store = ReactonStore();
final log = ActionLog();

// Attach the log to the store
store.addMiddleware(log);

// Now all mutations are automatically recorded
store.set(counterAtom, 1);
store.set(nameAtom, 'Alice');
store.set(counterAtom, 2);

// Access the log entries
print(log.entries.length); // 3`}
      />

      <h3 id="action-log-entries" className="text-xl font-semibold mt-8 mb-3">
        Inspecting Log Entries
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Each{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">LogEntry</code>
        {' '}contains detailed information about a single mutation:
      </p>
      <CodeBlock
        title="Inspecting log entries"
        code={`for (final entry in log.entries) {
  print('Atom:      \${entry.atomName}');
  print('Old value: \${entry.oldValue}');
  print('New value: \${entry.newValue}');
  print('Timestamp: \${entry.timestamp}');
  print('Stack:     \${entry.stackTrace}'); // optional, for debug builds
  print('---');
}

// Output:
// Atom:      counterAtom
// Old value: 0
// New value: 1
// Timestamp: 2025-01-15T10:30:45.123Z
// ---
// Atom:      nameAtom
// Old value: ''
// New value: Alice
// Timestamp: 2025-01-15T10:30:45.125Z
// ...`}
      />

      <h3 id="action-log-filtering" className="text-xl font-semibold mt-8 mb-3">
        Filtering and Querying
      </h3>
      <CodeBlock
        title="Filtering log entries"
        code={`// Filter by atom
final counterChanges = log.entriesFor(counterAtom);
print(counterChanges.length); // only counterAtom mutations

// Filter by time range
final recentChanges = log.entriesBetween(
  start: DateTime.now().subtract(Duration(minutes: 5)),
  end: DateTime.now(),
);

// Filter by predicate
final largeCounterChanges = log.entriesWhere(
  (entry) => entry.atomName == 'counterAtom' &&
             (entry.newValue as int) > 100,
);

// Get the last N entries
final lastTen = log.entries.take(10).toList();`}
      />

      <h3 id="action-log-export" className="text-xl font-semibold mt-8 mb-3">
        Export and Import
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Action logs can be serialized for storage, sharing, or analysis in external tools.
      </p>
      <CodeBlock
        title="Export and import logs"
        code={`// Export to JSON
final jsonString = log.toJson();
// Save to file, send to server, etc.
await File('debug_log.json').writeAsString(jsonString);

// Import from JSON
final importedLog = ActionLog.fromJson(jsonString);

// Export to CSV for spreadsheet analysis
final csvString = log.toCsv();

// Clear the log
log.clear();`}
      />

      <Callout type="tip" title="Use with Reacton DevTools">
        The Action Log integrates with Reacton DevTools for a visual timeline of state changes.
        Enable it in debug mode and connect DevTools to see a real-time, filterable stream
        of all mutations with their values, timestamps, and call stacks.
      </Callout>

      {/* ============================================================ */}
      {/* MULTI-ISOLATE STATE                                           */}
      {/* ============================================================ */}
      <h2 id="isolates" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Multi-Isolate State Sharing
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Dart uses isolates for concurrency. Unlike threads, isolates do not share memory.
        Each isolate has its own heap, and communication happens exclusively through message
        passing. This makes concurrent programming safer but creates a challenge: how do you
        share reactive state between a UI isolate and a background worker?
      </p>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Reacton's{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">IsolateStore</code>
        {' '}bridges this gap. It spawns a worker isolate with its own store instance and
        automatically synchronizes specified atoms between the main and worker isolates using
        an efficient message-passing protocol.
      </p>

      <h3 id="isolates-why" className="text-xl font-semibold mt-8 mb-3">
        Why Isolates Matter
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Flutter runs on a single UI isolate. Any heavy computation on this isolate (image
        processing, JSON parsing of large payloads, complex business logic, cryptographic
        operations) blocks the UI and causes jank. The standard solution is{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Isolate.run()</code>
        {' '}or{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">compute()</code>,
        but these are fire-and-forget: you send data in, get a result back, and that is it. There is
        no ongoing reactivity, no way for the worker to subscribe to state changes, and no way
        to push incremental results back.
      </p>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">IsolateStore</code>
        {' '}solves this by keeping a persistent worker isolate alive with a synchronized store,
        enabling ongoing, bidirectional reactive state sharing.
      </p>

      <h3 id="isolates-api" className="text-xl font-semibold mt-8 mb-3">
        IsolateStore API
      </h3>
      <CodeBlock
        title="Spawning an isolate store"
        code={`final mainStore = ReactonStore();

// Atoms to share between isolates
final configAtom = atom(ProcessingConfig.defaults());
final progressAtom = atom(0.0);
final resultAtom = atom<ProcessingResult?>(null);
final errorAtom = atom<String?>(null);

// Spawn a worker isolate with shared atoms
final isolateStore = await IsolateStore.spawn(
  mainStore,
  sharedAtoms: [configAtom, progressAtom, resultAtom, errorAtom],
  entryPoint: (workerStore) {
    // This entire function runs in the worker isolate.
    // workerStore is a fully functional ReactonStore.

    // Subscribe to config changes from the main isolate
    workerStore.subscribe(configAtom, (config) async {
      try {
        // Heavy computation that would block the UI
        for (int i = 0; i <= 100; i++) {
          await Future.delayed(Duration(milliseconds: 50));
          workerStore.set(progressAtom, i / 100.0);
        }

        final result = await processData(config);
        workerStore.set(resultAtom, result);
      } catch (e) {
        workerStore.set(errorAtom, e.toString());
      }
    });
  },
);`}
      />

      <h3 id="isolates-communication" className="text-xl font-semibold mt-8 mb-3">
        Bidirectional Communication
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Shared atoms are synchronized in both directions automatically:
      </p>
      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400">
        <li>
          <strong className="text-gray-900 dark:text-white">Main to Worker</strong>:
          When the main isolate changes a shared atom (e.g., updating{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">configAtom</code>),
          the new value is serialized and sent to the worker isolate, where it updates the
          worker's local copy of the atom and triggers any subscribers.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Worker to Main</strong>:
          When the worker changes a shared atom (e.g., updating{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">progressAtom</code>
          {' '}or{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">resultAtom</code>),
          the value is sent back to the main isolate, updating the main store and triggering
          UI rebuilds.
        </li>
      </ul>
      <CodeBlock
        title="Bidirectional sync in action"
        code={`// In the main isolate — UI reacts to worker's progress
ReactonBuilder(
  atom: progressAtom,
  builder: (context, progress) {
    return Column(
      children: [
        LinearProgressIndicator(value: progress),
        Text('\${(progress * 100).toStringAsFixed(0)}%'),
      ],
    );
  },
),

// When user changes config, it automatically reaches the worker
void onConfigChanged(ProcessingConfig newConfig) {
  mainStore.set(configAtom, newConfig);
  // The worker's subscription to configAtom fires automatically
}

// When the worker finishes, result automatically reaches the UI
ReactonBuilder(
  atom: resultAtom,
  builder: (context, result) {
    if (result == null) return Text('Processing...');
    return ResultDisplay(result: result);
  },
),`}
      />

      <h3 id="isolates-protocol" className="text-xl font-semibold mt-8 mb-3">
        Communication Protocol
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Under the hood, Reacton uses a simple message protocol over Dart's{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">SendPort</code>
        /{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReceivePort</code>:
      </p>
      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400">
        <li>
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">HandshakeAck</code>
          {' '}&mdash; Sent when the worker isolate has initialized its store and is ready to
          receive atom updates. The main isolate waits for this before resolving the{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">IsolateStore.spawn()</code>
          {' '}future.
        </li>
        <li>
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AtomValueChanged</code>
          {' '}&mdash; Sent in either direction when a shared atom's value changes. Contains
          the atom identifier and the serialized new value.
        </li>
      </ul>

      <Callout type="warning" title="Serialization Constraints">
        Values shared across isolates must be types that Dart can send through{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">SendPort.send()</code>:
        primitives (int, double, String, bool, null), lists, maps, typed data, and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">TransferableTypedData</code>.
        Complex objects need to be serializable (e.g., implement{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">toJson()</code>/{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">fromJson()</code>).
        Closures, streams, and most Dart objects cannot cross isolate boundaries.
      </Callout>

      <h3 id="isolates-error-handling" className="text-xl font-semibold mt-8 mb-3">
        Error Handling
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Errors in the worker isolate should be communicated back to the main isolate through
        shared atoms. If the worker isolate crashes, the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">IsolateStore</code>
        {' '}detects the disconnection and can notify listeners.
      </p>
      <CodeBlock
        title="Error handling in isolates"
        code={`final errorAtom = atom<IsolateError?>(null);
final statusAtom = atom(WorkerStatus.idle);

final isolateStore = await IsolateStore.spawn(
  mainStore,
  sharedAtoms: [configAtom, resultAtom, errorAtom, statusAtom],
  entryPoint: (workerStore) {
    workerStore.subscribe(configAtom, (config) async {
      workerStore.set(statusAtom, WorkerStatus.running);
      try {
        final result = await heavyComputation(config);
        workerStore.set(resultAtom, result);
        workerStore.set(statusAtom, WorkerStatus.completed);
      } catch (e, stackTrace) {
        workerStore.set(errorAtom, IsolateError(
          message: e.toString(),
          stackTrace: stackTrace.toString(),
        ));
        workerStore.set(statusAtom, WorkerStatus.error);
      }
    });
  },
  // Called if the worker isolate crashes unexpectedly
  onError: (error) {
    mainStore.set(errorAtom, IsolateError(
      message: 'Worker isolate crashed: \$error',
    ));
    mainStore.set(statusAtom, WorkerStatus.crashed);
  },
);

// In the UI — handle errors
ReactonBuilder(
  atom: errorAtom,
  builder: (context, error) {
    if (error == null) return SizedBox.shrink();
    return ErrorBanner(
      message: error.message,
      onRetry: () {
        mainStore.set(errorAtom, null);
        // Re-trigger computation by updating config
        mainStore.set(configAtom, mainStore.get(configAtom));
      },
    );
  },
),`}
      />

      <h3 id="isolates-dispose" className="text-xl font-semibold mt-8 mb-3">
        Disposing Isolate Stores
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Always dispose of isolate stores when they are no longer needed. This terminates the
        worker isolate and closes the communication ports.
      </p>
      <CodeBlock
        title="Disposing isolate stores"
        code={`// Graceful shutdown
await isolateStore.dispose();

// In a StatefulWidget
@override
void dispose() {
  isolateStore.dispose();
  super.dispose();
}

// Or with a provider that manages lifecycle
final imageProcessorProvider = Provider<IsolateStore>((ref) {
  final isolateStore = IsolateStore.spawn(...);
  ref.onDispose(() => isolateStore.dispose());
  return isolateStore;
});`}
      />

      <h3 id="isolates-example" className="text-xl font-semibold mt-8 mb-3">
        Complete Example: Image Processing Pipeline
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        A full working example that offloads expensive image processing to a worker isolate
        while keeping the UI responsive with real-time progress updates.
      </p>
      <CodeBlock
        title="Image processing with IsolateStore"
        code={`// --- Shared atoms ---
final sourceImageAtom = atom<Uint8List?>(null);
final filtersAtom = atom<List<ImageFilter>>([]);
final progressAtom = atom(0.0);
final processedImageAtom = atom<Uint8List?>(null);
final processingStatusAtom = atom(ProcessingStatus.idle);

// --- Worker setup ---
late final IsolateStore _imageWorker;

Future<void> initImageProcessor() async {
  _imageWorker = await IsolateStore.spawn(
    store,
    sharedAtoms: [
      sourceImageAtom,
      filtersAtom,
      progressAtom,
      processedImageAtom,
      processingStatusAtom,
    ],
    entryPoint: (workerStore) {
      // React to new source images or filter changes
      workerStore.subscribe(sourceImageAtom, (imageBytes) async {
        if (imageBytes == null) return;

        workerStore.set(processingStatusAtom, ProcessingStatus.running);
        workerStore.set(progressAtom, 0.0);

        final filters = workerStore.get(filtersAtom);
        Uint8List result = imageBytes;

        for (int i = 0; i < filters.length; i++) {
          // Apply each filter (expensive CPU work)
          result = await filters[i].apply(result);

          // Report progress back to main isolate
          workerStore.set(progressAtom, (i + 1) / filters.length);
        }

        workerStore.set(processedImageAtom, result);
        workerStore.set(processingStatusAtom, ProcessingStatus.completed);
      });

      // Also react to filter changes
      workerStore.subscribe(filtersAtom, (filters) {
        final image = workerStore.get(sourceImageAtom);
        if (image != null) {
          // Re-process with new filters
          workerStore.set(sourceImageAtom, image); // triggers above
        }
      });
    },
  );
}

// --- UI ---
class ImageEditorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Editor')),
      body: Column(
        children: [
          // Progress bar
          ReactonBuilder(
            atom: processingStatusAtom,
            builder: (context, status) {
              if (status != ProcessingStatus.running) {
                return SizedBox.shrink();
              }
              return ReactonBuilder(
                atom: progressAtom,
                builder: (context, progress) {
                  return LinearProgressIndicator(value: progress);
                },
              );
            },
          ),

          // Image display
          Expanded(
            child: ReactonBuilder(
              atom: processedImageAtom,
              builder: (context, processed) {
                if (processed != null) {
                  return Image.memory(processed, fit: BoxFit.contain);
                }
                return ReactonBuilder(
                  atom: sourceImageAtom,
                  builder: (context, source) {
                    if (source != null) {
                      return Image.memory(source, fit: BoxFit.contain);
                    }
                    return Center(child: Text('Pick an image'));
                  },
                );
              },
            ),
          ),

          // Filter controls
          FilterToolbar(
            onFilterAdded: (filter) {
              final current = store.get(filtersAtom);
              store.set(filtersAtom, [...current, filter]);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final picker = ImagePicker();
          final file = await picker.pickImage(source: ImageSource.gallery);
          if (file != null) {
            final bytes = await file.readAsBytes();
            store.set(sourceImageAtom, bytes);
          }
        },
        child: Icon(Icons.add_photo_alternate),
      ),
    );
  }
}`}
      />

      {/* ============================================================ */}
      {/* INCREMENTAL COMPUTATION                                       */}
      {/* ============================================================ */}
      <h2 id="incremental" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Incremental Computation
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        When you derive a list from another list (filtering, sorting, mapping), the default
        behavior recomputes the entire derived list whenever the source changes. For small lists
        this is fine, but when you have hundreds or thousands of items with a single insertion or
        removal, recomputing everything is wasteful.
      </p>

      <h3 id="incremental-problem" className="text-xl font-semibold mt-8 mb-3">
        The Problem
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Consider a chat application with 10,000 messages. You have a derived atom that filters
        messages by a search query. When one new message arrives, the standard computed atom
        re-filters all 10,000 messages, even though only the new message needs to be checked.
      </p>
      <CodeBlock
        title="The recomputation problem"
        code={`final messagesAtom = atom<List<Message>>([]);
final searchQueryAtom = atom('');

// This recomputes on EVERY change to messagesAtom —
// even if only one message was added
final filteredMessagesAtom = computed((get) {
  final messages = get(messagesAtom);     // 10,000 messages
  final query = get(searchQueryAtom);
  return messages.where((m) => m.text.contains(query)).toList();
  // ^ Iterates all 10,000 every time
});`}
      />

      <h3 id="incremental-solution" className="text-xl font-semibold mt-8 mb-3">
        The Solution: IncrementalListAtom
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">IncrementalListAtom&lt;T&gt;</code>
        {' '}tracks granular changes (insertions, removals, updates) instead of replacing the
        entire list. Downstream derivations receive only the delta and can update themselves
        incrementally.
      </p>
      <CodeBlock
        title="IncrementalListAtom concept"
        code={`final messagesAtom = incrementalListAtom<Message>([]);

// Granular operations — each emits a minimal change event
messagesAtom.add(newMessage);            // ListChange.insert(index, item)
messagesAtom.removeAt(5);               // ListChange.remove(index, item)
messagesAtom.update(3, updatedMessage);  // ListChange.update(index, old, new)

// Downstream derivations receive the delta, not the full list
final filteredAtom = messagesAtom.derive(
  filter: (msg) => msg.text.contains(query),
  onInsert: (index, msg) {
    // Only check the new message — O(1) instead of O(n)
    if (msg.text.contains(query)) addToFiltered(msg);
  },
  onRemove: (index, msg) {
    removeFromFiltered(msg);
  },
);`}
      />

      <h3 id="incremental-use-cases" className="text-xl font-semibold mt-8 mb-3">
        Use Cases
      </h3>
      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400">
        <li>
          <strong className="text-gray-900 dark:text-white">Large lists</strong>:
          Chat messages, feed items, product catalogs with hundreds or thousands of entries.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Real-time feeds</strong>:
          WebSocket-driven data where items are frequently added at the top without disturbing the rest.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Table data</strong>:
          Spreadsheet-style grids where individual cells are updated without re-rendering the entire table.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Animated lists</strong>:
          Knowing exactly which item was inserted or removed allows you to animate the change
          with{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">AnimatedList</code>
          {' '}without diffing.
        </li>
      </ul>

      <Callout type="info" title="Roadmap Status">
        Incremental computation is currently on the Reacton roadmap. The API design is being
        finalized and will be available in a future release. The examples above represent the
        intended API direction. In the meantime, you can achieve partial incrementality by
        keeping atom granularity small (one atom per item rather than one atom for the whole list).
      </Callout>

      {/* ============================================================ */}
      {/* STORE SNAPSHOTS                                               */}
      {/* ============================================================ */}
      <h2 id="snapshots" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Store Snapshots
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        A snapshot captures the complete state of every atom in the store at a single point in
        time. Unlike branches (which are live workspaces), snapshots are <strong className="text-gray-900 dark:text-white">immutable</strong> and{' '}
        <strong className="text-gray-900 dark:text-white">serializable</strong>. You can save them,
        restore from them, compare them, and even persist them to disk.
      </p>

      <h3 id="snapshots-create" className="text-xl font-semibold mt-8 mb-3">
        Creating and Restoring Snapshots
      </h3>
      <CodeBlock
        title="Snapshot basics"
        code={`final store = ReactonStore();
final nameAtom = atom('Alice');
final counterAtom = atom(0);
final settingsAtom = atom(AppSettings.defaults());

// Take a snapshot of the current state
final snapshot = store.snapshot();

print(snapshot.timestamp);    // when the snapshot was taken
print(snapshot.atomCount);    // number of atoms captured
print(snapshot.get(nameAtom)); // 'Alice'

// Make some changes
store.set(nameAtom, 'Bob');
store.set(counterAtom, 42);

// Restore to the snapshot — all atoms revert
store.restore(snapshot);

print(store.get(nameAtom));    // 'Alice'
print(store.get(counterAtom)); // 0
// All subscribers are notified of the restored values`}
      />

      <h3 id="snapshots-use-cases" className="text-xl font-semibold mt-8 mb-3">
        Use Cases
      </h3>
      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400">
        <li>
          <strong className="text-gray-900 dark:text-white">Save points</strong>:
          Take a snapshot before a risky operation so you can revert if something goes wrong.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Crash recovery</strong>:
          Persist the snapshot to disk and restore it when the app restarts after a crash.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Testing</strong>:
          Capture a specific state configuration and restore it across multiple test cases for
          consistent test setup.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Debugging</strong>:
          Export a snapshot from a user's device and import it locally to reproduce their exact state.
        </li>
      </ul>

      <h3 id="snapshots-serialization" className="text-xl font-semibold mt-8 mb-3">
        Serialization
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Snapshots can be serialized to JSON for persistence or network transfer. Each atom
        must have a registered serializer for this to work.
      </p>
      <CodeBlock
        title="Snapshot serialization"
        code={`// Register serializers for custom types
store.registerSerializer<AppSettings>(
  serialize: (settings) => settings.toJson(),
  deserialize: (json) => AppSettings.fromJson(json),
);

// Take a snapshot and serialize it
final snapshot = store.snapshot();
final jsonString = snapshot.toJson();

// Persist to SharedPreferences or file
final prefs = await SharedPreferences.getInstance();
await prefs.setString('app_snapshot', jsonString);

// Later, restore from JSON
final savedJson = prefs.getString('app_snapshot');
if (savedJson != null) {
  final restored = StoreSnapshot.fromJson(savedJson);
  store.restore(restored);
}

// Compare two snapshots
final before = store.snapshot();
// ... user makes changes ...
final after = store.snapshot();

final diff = before.diff(after);
print('Changed atoms: \${diff.changedAtoms.length}');
for (final change in diff.changes.entries) {
  print('\${change.key}: \${change.value.before} -> \${change.value.after}');
}`}
      />

      <h3 id="snapshots-complete-example" className="text-xl font-semibold mt-8 mb-3">
        Complete Example: Auto-Save with Crash Recovery
      </h3>
      <CodeBlock
        title="Auto-save with snapshots"
        code={`class SnapshotManager {
  final ReactonStore store;
  final SharedPreferences prefs;
  Timer? _autoSaveTimer;

  SnapshotManager({required this.store, required this.prefs});

  /// Start auto-saving every 30 seconds
  void startAutoSave() {
    _autoSaveTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => saveSnapshot(),
    );
  }

  /// Save a snapshot to disk
  Future<void> saveSnapshot() async {
    final snapshot = store.snapshot();
    final json = snapshot.toJson();
    await prefs.setString('auto_save', json);
    await prefs.setString('auto_save_time', DateTime.now().toIso8601String());
  }

  /// Restore from the last auto-save, if available
  Future<bool> restoreIfAvailable() async {
    final json = prefs.getString('auto_save');
    if (json == null) return false;

    try {
      final snapshot = StoreSnapshot.fromJson(json);
      store.restore(snapshot);

      final savedTime = prefs.getString('auto_save_time') ?? 'unknown';
      print('Restored state from \$savedTime');
      return true;
    } catch (e) {
      print('Failed to restore snapshot: \$e');
      return false;
    }
  }

  /// Create a named save point
  Future<void> createSavePoint(String name) async {
    final snapshot = store.snapshot();
    final json = snapshot.toJson();
    await prefs.setString('save_point_\$name', json);
  }

  /// Restore a named save point
  Future<bool> restoreSavePoint(String name) async {
    final json = prefs.getString('save_point_\$name');
    if (json == null) return false;
    store.restore(StoreSnapshot.fromJson(json));
    return true;
  }

  void dispose() {
    _autoSaveTimer?.cancel();
  }
}

// Usage
void main() async {
  final prefs = await SharedPreferences.getInstance();
  final store = ReactonStore();

  final snapshotManager = SnapshotManager(store: store, prefs: prefs);

  // Try to restore from crash recovery
  final restored = await snapshotManager.restoreIfAvailable();
  if (restored) {
    print('Recovered from previous session!');
  }

  // Start auto-saving
  snapshotManager.startAutoSave();

  runApp(MyApp(store: store));
}`}
      />

      <Callout type="tip" title="Snapshots vs Branches">
        Use <strong>snapshots</strong> when you need a frozen, serializable checkpoint of your
        entire state (persistence, crash recovery, testing). Use <strong>branches</strong> when
        you need a live, mutable workspace for in-progress edits (form drafts, previews, wizards).
      </Callout>

      {/* ============================================================ */}
      {/* PERFORMANCE OPTIMIZATION                                      */}
      {/* ============================================================ */}
      <h2 id="performance" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Performance Optimization Guide
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Reacton is designed to be fast by default, but understanding its internals helps you
        squeeze out maximum performance in demanding scenarios. This section covers the most
        impactful optimization techniques.
      </p>

      {/* Performance - Atom Granularity */}
      <h3 id="performance-granularity" className="text-xl font-semibold mt-8 mb-3">
        Atom Granularity
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The single most important performance decision is <strong className="text-gray-900 dark:text-white">how granular your atoms are</strong>.
        When an atom changes, every widget that depends on it rebuilds. If one atom contains
        your entire app state, a change to any field rebuilds everything. If each piece of
        state has its own atom, only the widgets that actually care rebuild.
      </p>
      <CodeBlock
        title="Bad: monolithic atom"
        code={`// DON'T: One giant atom for everything
final appStateAtom = atom(AppState(
  user: User(...),
  settings: Settings(...),
  cart: Cart(...),
  notifications: [...],
));

// Changing the cart rebuilds the user profile, settings page,
// notification badge, and every other widget`}
      />
      <CodeBlock
        title="Good: granular atoms"
        code={`// DO: Separate atoms for separate concerns
final userAtom = atom(User(...));
final settingsAtom = atom(Settings(...));
final cartAtom = atom(Cart(...));
final notificationsAtom = atom<List<Notification>>([]);
final unreadCountAtom = computed((get) =>
  get(notificationsAtom).where((n) => !n.isRead).length,
);

// Now changing the cart ONLY rebuilds cart-related widgets
// The user profile, settings, and notifications are untouched`}
      />

      <Callout type="tip" title="Rule of thumb">
        If two pieces of state change independently or are consumed by different widgets,
        they should be in separate atoms. If they always change together and are always
        consumed together, they can share an atom.
      </Callout>

      {/* Performance - Selectors */}
      <h3 id="performance-selectors" className="text-xl font-semibold mt-8 mb-3">
        Using Selectors to Avoid Unnecessary Rebuilds
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Even with granular atoms, you sometimes need to read only part of an atom's value.
        Selectors let you derive a subset of an atom and only rebuild when that subset changes.
      </p>
      <CodeBlock
        title="Selectors for partial reads"
        code={`final userAtom = atom(User(name: 'Alice', email: 'alice@example.com', avatar: '...'));

// Without selector: rebuilds when ANY user field changes
ReactonBuilder(
  atom: userAtom,
  builder: (context, user) => Text(user.name),
  // This rebuilds even if only email or avatar changed!
);

// With selector: rebuilds ONLY when name changes
final userNameAtom = computed((get) => get(userAtom).name);

ReactonBuilder(
  atom: userNameAtom,
  builder: (context, name) => Text(name),
  // Only rebuilds when the name string actually changes
);

// You can also use inline selectors
ReactonBuilder(
  atom: userAtom,
  selector: (user) => user.name,
  builder: (context, name) => Text(name),
  // Reacton compares the selector output, not the full atom value
);`}
      />

      {/* Performance - Batching */}
      <h3 id="performance-batching" className="text-xl font-semibold mt-8 mb-3">
        Batching Updates
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        When you need to update multiple atoms at once, each individual{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">set()</code>
        {' '}call triggers notifications and potential rebuilds. Use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.batch()</code>
        {' '}to group multiple updates into a single notification cycle.
      </p>
      <CodeBlock
        title="Batching multiple updates"
        code={`// Without batching: 4 separate notification cycles
// Each one could trigger a rebuild
store.set(nameAtom, 'Bob');
store.set(emailAtom, 'bob@example.com');
store.set(avatarAtom, 'new-avatar.png');
store.set(updatedAtAtom, DateTime.now());

// With batching: 1 notification cycle after all updates
store.batch(() {
  store.set(nameAtom, 'Bob');
  store.set(emailAtom, 'bob@example.com');
  store.set(avatarAtom, 'new-avatar.png');
  store.set(updatedAtAtom, DateTime.now());
});
// All subscribers are notified once, with the final values

// Batching also works with computed atoms —
// intermediate states are never seen by subscribers
final fullNameAtom = computed((get) => '\${get(firstNameAtom)} \${get(lastNameAtom)}');

store.batch(() {
  store.set(firstNameAtom, 'Jane');
  store.set(lastNameAtom, 'Smith');
});
// fullNameAtom goes directly from old -> 'Jane Smith'
// It never briefly shows 'Jane OldLastName'`}
      />

      {/* Performance - Computed vs Widget */}
      <h3 id="performance-computed" className="text-xl font-semibold mt-8 mb-3">
        Computed Atoms vs Widget-Level Derivation
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        You can derive values either as computed atoms (in the store layer) or inline in the
        widget build method. Each approach has trade-offs:
      </p>
      <div className="overflow-x-auto mb-6">
        <table className="min-w-full text-sm border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
          <thead>
            <tr className="bg-gray-50 dark:bg-gray-800/50">
              <th className="text-left px-4 py-3 font-semibold text-gray-900 dark:text-white border-b border-gray-200 dark:border-gray-700">Aspect</th>
              <th className="text-left px-4 py-3 font-semibold text-gray-900 dark:text-white border-b border-gray-200 dark:border-gray-700">Computed Atom</th>
              <th className="text-left px-4 py-3 font-semibold text-gray-900 dark:text-white border-b border-gray-200 dark:border-gray-700">Widget-Level</th>
            </tr>
          </thead>
          <tbody className="text-gray-600 dark:text-gray-400">
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="px-4 py-2.5 font-medium text-gray-900 dark:text-white">Caching</td>
              <td className="px-4 py-2.5">Value is cached and shared across all consumers</td>
              <td className="px-4 py-2.5">Recomputed in every widget that needs it</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="px-4 py-2.5 font-medium text-gray-900 dark:text-white">Rebuild precision</td>
              <td className="px-4 py-2.5">Only rebuilds when computed value changes</td>
              <td className="px-4 py-2.5">Rebuilds whenever source atom changes</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800">
              <td className="px-4 py-2.5 font-medium text-gray-900 dark:text-white">Testability</td>
              <td className="px-4 py-2.5">Can be tested independently of UI</td>
              <td className="px-4 py-2.5">Must test through widget testing</td>
            </tr>
            <tr>
              <td className="px-4 py-2.5 font-medium text-gray-900 dark:text-white">Best for</td>
              <td className="px-4 py-2.5">Shared derivations, expensive computations</td>
              <td className="px-4 py-2.5">One-off, cheap derivations used by a single widget</td>
            </tr>
          </tbody>
        </table>
      </div>
      <CodeBlock
        title="When to use computed atoms"
        code={`// USE computed atom: expensive + shared by multiple widgets
final sortedProductsAtom = computed((get) {
  final products = get(productsAtom);  // could be 1000+ items
  final sortBy = get(sortFieldAtom);
  return [...products]..sort((a, b) => a.compareTo(b, sortBy));
});

// Multiple widgets read sortedProductsAtom — computed once, cached
ProductGrid(products: context.watch(sortedProductsAtom));
ProductCount(count: context.watch(sortedProductsAtom).length);

// USE widget-level: cheap + only used by one widget
ReactonBuilder(
  atom: counterAtom,
  builder: (context, count) {
    final isEven = count % 2 == 0;  // trivial derivation
    return Text(isEven ? 'Even' : 'Odd');
  },
);`}
      />

      {/* Performance - ReactonBuilder vs context.watch */}
      <h3 id="performance-builder-vs-watch" className="text-xl font-semibold mt-8 mb-3">
        ReactonBuilder vs context.watch
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Both{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonBuilder</code>
        {' '}and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch()</code>
        {' '}subscribe to atom changes, but they control different rebuild scopes:
      </p>
      <CodeBlock
        title="Rebuild scope comparison"
        code={`// context.watch — rebuilds the ENTIRE widget
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.watch(counterAtom);
    // If counterAtom changes, this ENTIRE build method re-runs.
    // ExpensiveHeader and ExpensiveFooter rebuild too.
    return Column(
      children: [
        ExpensiveHeader(),       // rebuilds unnecessarily
        Text('Count: \$count'),  // the only part that needs to rebuild
        ExpensiveFooter(),       // rebuilds unnecessarily
      ],
    );
  }
}

// ReactonBuilder — rebuilds only the builder function
class MyBetterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpensiveHeader(),       // does NOT rebuild
        ReactonBuilder(
          atom: counterAtom,
          builder: (context, count) => Text('Count: \$count'),
          // Only this Text widget rebuilds
        ),
        ExpensiveFooter(),       // does NOT rebuild
      ],
    );
  }
}`}
      />
      <Callout type="tip" title="When to use which">
        Use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch()</code>
        {' '}when the entire widget depends on the atom (small, focused widgets). Use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonBuilder</code>
        {' '}when only a portion of a larger widget depends on the atom, to minimize the
        rebuild scope.
      </Callout>

      {/* Performance - Profiling */}
      <h3 id="performance-profiling" className="text-xl font-semibold mt-8 mb-3">
        Profiling with DevTools
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Reacton integrates with Flutter DevTools to help you identify performance bottlenecks:
      </p>
      <CodeBlock
        title="Enabling Reacton DevTools"
        code={`void main() {
  final store = ReactonStore();

  // Enable DevTools integration in debug mode
  assert(() {
    ReactonDevTools.connect(store, options: DevToolsOptions(
      // Log all atom reads and writes
      traceReads: true,
      traceWrites: true,

      // Track rebuild counts per widget
      trackRebuilds: true,

      // Warn if a computed atom takes longer than 16ms
      slowComputedThreshold: Duration(milliseconds: 16),

      // Warn if a widget rebuilds more than 60 times/second
      excessiveRebuildThreshold: 60,
    ));
    return true;
  }());

  runApp(MyApp(store: store));
}`}
      />
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        With DevTools connected, you can:
      </p>
      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400">
        <li>See a real-time graph of all atoms and their dependency relationships.</li>
        <li>Identify which atoms change most frequently.</li>
        <li>See which widgets rebuild when each atom changes.</li>
        <li>Spot "cascade rebuilds" where one atom change triggers many widget rebuilds.</li>
        <li>Profile computed atom execution time to find expensive derivations.</li>
      </ul>

      {/* Performance - Pitfalls */}
      <h3 id="performance-pitfalls" className="text-xl font-semibold mt-8 mb-3">
        Common Performance Pitfalls
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Here are the most common mistakes that cause performance problems, and how to fix them:
      </p>

      <h4 className="text-lg font-medium mt-6 mb-3 text-gray-800 dark:text-gray-200">
        1. Creating new objects in computed atoms unnecessarily
      </h4>
      <CodeBlock
        title="Pitfall: always-new objects"
        code={`// BAD: creates a new list every time, even if nothing changed
final filteredAtom = computed((get) {
  final items = get(itemsAtom);
  return items.where((i) => i.isActive).toList(); // new List every time
});

// GOOD: use a stable comparison or memoization
final filteredAtom = computed((get) {
  final items = get(itemsAtom);
  return items.where((i) => i.isActive).toList();
}, equals: const ListEquality().equals);
// Now Reacton compares list contents, not identity`}
      />

      <h4 className="text-lg font-medium mt-6 mb-3 text-gray-800 dark:text-gray-200">
        2. Reading too many atoms in one widget
      </h4>
      <CodeBlock
        title="Pitfall: over-subscribing"
        code={`// BAD: widget rebuilds if ANY of these 5 atoms change
class DashboardWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch(userAtom);
    final orders = context.watch(ordersAtom);
    final notifications = context.watch(notificationsAtom);
    final settings = context.watch(settingsAtom);
    final analytics = context.watch(analyticsAtom);
    return BigDashboard(user, orders, notifications, settings, analytics);
  }
}

// GOOD: split into focused sub-widgets
class DashboardWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UserHeader(),            // only watches userAtom
        OrdersSummary(),         // only watches ordersAtom
        NotificationsBadge(),    // only watches notificationsAtom
        SettingsQuickAccess(),   // only watches settingsAtom
        AnalyticsChart(),        // only watches analyticsAtom
      ],
    );
  }
}`}
      />

      <h4 className="text-lg font-medium mt-6 mb-3 text-gray-800 dark:text-gray-200">
        3. Forgetting to batch related updates
      </h4>
      <CodeBlock
        title="Pitfall: unbatched updates"
        code={`// BAD: 3 separate notifications, possible intermediate states
void updateUserProfile(String name, String email, String avatar) {
  store.set(nameAtom, name);     // triggers rebuild with new name, old email
  store.set(emailAtom, email);   // triggers rebuild with new name+email, old avatar
  store.set(avatarAtom, avatar); // triggers rebuild with all new values
}

// GOOD: one notification, no intermediate states
void updateUserProfile(String name, String email, String avatar) {
  store.batch(() {
    store.set(nameAtom, name);
    store.set(emailAtom, email);
    store.set(avatarAtom, avatar);
  });
  // One rebuild with the final, consistent state
}`}
      />

      <h4 className="text-lg font-medium mt-6 mb-3 text-gray-800 dark:text-gray-200">
        4. Expensive operations in computed atoms without memoization
      </h4>
      <CodeBlock
        title="Pitfall: expensive computed atoms"
        code={`// BAD: sorts 10,000 items every time ANY dependency changes
final sortedItemsAtom = computed((get) {
  final items = get(itemsAtom);
  final sortField = get(sortFieldAtom);
  final filterQuery = get(filterQueryAtom);

  // This runs even if only filterQuery changed and sort is irrelevant
  final sorted = [...items]..sort(/* expensive */);
  return sorted.where((i) => i.matches(filterQuery)).toList();
});

// GOOD: split into separate computed atoms
final sortedItemsAtom = computed((get) {
  final items = get(itemsAtom);
  final sortField = get(sortFieldAtom);
  return [...items]..sort(/* expensive */);
  // Only recomputes when items or sortField change
});

final filteredItemsAtom = computed((get) {
  final sorted = get(sortedItemsAtom); // cached!
  final query = get(filterQueryAtom);
  return sorted.where((i) => i.matches(query)).toList();
  // Recomputes on query change, but uses cached sort
});`}
      />

      <Callout type="danger" title="Avoid infinite loops">
        Never set an atom inside a computed atom's derivation function. Computed atoms are
        for reading and deriving values only. Writing to atoms inside a computed function
        will trigger re-derivation and create an infinite loop.
      </Callout>

      <h3 id="performance-summary" className="text-xl font-semibold mt-8 mb-3">
        Performance Checklist
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Use this checklist when optimizing your Reacton application:
      </p>
      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400">
        <li>
          <strong className="text-gray-900 dark:text-white">Keep atoms small and focused</strong>
          {' '}&mdash; one atom per independent piece of state.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Use computed atoms for shared derivations</strong>
          {' '}&mdash; compute once, consume everywhere.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Batch related updates</strong>
          {' '}&mdash; use{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">store.batch()</code>
          {' '}for multi-atom changes.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Use selectors for partial reads</strong>
          {' '}&mdash; only rebuild when the relevant subset of data changes.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Prefer ReactonBuilder for scoped rebuilds</strong>
          {' '}&mdash; minimize the widget subtree that rebuilds.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Split expensive computed atoms</strong>
          {' '}&mdash; chain smaller computations so each step is cached independently.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Profile with DevTools</strong>
          {' '}&mdash; measure before optimizing; identify actual bottlenecks.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Use custom equality</strong>
          {' '}&mdash; provide{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">equals</code>
          {' '}functions for computed atoms that return collections or complex objects.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Offload heavy work</strong>
          {' '}&mdash; use{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">IsolateStore</code>
          {' '}for computations that take more than 16ms.
        </li>
      </ul>

      <PageNav
        prev={{ title: 'Async & Middleware', path: '/async-middleware' }}
        next={{ title: 'Testing', path: '/testing' }}
      />
    </div>
  )
}
