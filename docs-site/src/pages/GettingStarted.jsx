import CodeBlock from '../components/CodeBlock'
import Callout from '../components/Callout'
import PageNav from '../components/PageNav'

export default function GettingStarted() {
  return (
    <div>
      <h1 id="getting-started" className="text-4xl font-extrabold tracking-tight mb-4">
        Getting Started
      </h1>
      <p className="text-lg text-gray-500 dark:text-gray-400 mb-8">
        Everything you need to start building reactive Flutter apps with Reacton — from installation through
        your first fully working application. By the end of this guide, you will understand atoms, derived
        state, scoped stores, and the complete read/write cycle.
      </p>

      {/* ================================================================== */}
      {/* PREREQUISITES */}
      {/* ================================================================== */}
      <h2 id="prerequisites" className="text-2xl font-bold mt-12 mb-4">
        Prerequisites
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Before installing Reacton, make sure your development environment meets the following requirements.
        Reacton is built on top of modern Dart language features such as extension methods and enhanced enums,
        so a recent SDK version is required.
      </p>

      <div className="overflow-x-auto mb-6">
        <table className="w-full text-sm border-collapse">
          <thead>
            <tr className="border-b border-gray-200 dark:border-gray-800">
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Requirement</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Minimum Version</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Recommended</th>
            </tr>
          </thead>
          <tbody className="text-gray-600 dark:text-gray-400">
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4">Dart SDK</td>
              <td className="py-3 px-4">
                <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">&gt;=3.0.0</code>
              </td>
              <td className="py-3 px-4">
                <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">3.2.0+</code>
              </td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4">Flutter SDK</td>
              <td className="py-3 px-4">
                <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">&gt;=3.10.0</code>
              </td>
              <td className="py-3 px-4">
                <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">3.16.0+</code>
              </td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4">IDE</td>
              <td className="py-3 px-4">VS Code or Android Studio / IntelliJ</td>
              <td className="py-3 px-4">VS Code with Dart &amp; Flutter extensions</td>
            </tr>
            <tr>
              <td className="py-3 px-4">Platform</td>
              <td className="py-3 px-4" colSpan={2}>Any platform supported by Flutter (iOS, Android, Web, macOS, Windows, Linux)</td>
            </tr>
          </tbody>
        </table>
      </div>

      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        You can verify your current versions by running the following command in your terminal:
      </p>
      <CodeBlock
        language="bash"
        code="flutter --version"
      />
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        You should see output that includes both the Flutter and Dart SDK versions. If your Dart SDK
        version is below 3.0.0, update Flutter by running{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">flutter upgrade</code>.
      </p>

      <Callout type="tip" title="IDE Setup">
        For the best experience, install the <strong>Dart</strong> and <strong>Flutter</strong> extensions
        in VS Code. These provide autocomplete, inline error checking, and hot-reload integration that
        makes working with Reacton's reactive APIs seamless. IntelliJ / Android Studio users should
        install the equivalent Dart and Flutter plugins.
      </Callout>

      {/* ================================================================== */}
      {/* INSTALLATION */}
      {/* ================================================================== */}
      <h2 id="installation" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Installation
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Reacton is distributed as two packages.{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton</code>{' '}
        is the platform-independent core that contains all reactive primitives — atoms, computed values,
        effects, selectors, and families. It has zero Flutter dependencies and can be used in pure Dart
        applications, CLI tools, or server-side Dart.{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">flutter_reacton</code>{' '}
        provides the Flutter integration layer — widgets like{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonScope</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonBuilder</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonConsumer</code>,
        and the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context</code>{' '}
        extension methods. For Flutter projects, you typically install both.
      </p>

      <h3 id="install-pubspec" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Option 1: Edit pubspec.yaml directly
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Open your project's{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">pubspec.yaml</code>{' '}
        and add both packages under{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">dependencies</code>:
      </p>
      <CodeBlock
        language="yaml"
        title="pubspec.yaml"
        code={`dependencies:
  flutter:
    sdk: flutter
  reacton: ^0.1.0
  flutter_reacton: ^0.1.0`}
      />
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Then fetch the packages:
      </p>
      <CodeBlock
        language="bash"
        code="flutter pub get"
      />

      <h3 id="install-cli" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Option 2: Install via the command line
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Flutter's CLI can add both packages in a single command. This automatically updates your{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">pubspec.yaml</code>{' '}
        and runs{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">pub get</code>{' '}
        for you:
      </p>
      <CodeBlock
        language="bash"
        code="flutter pub add reacton flutter_reacton"
      />

      <h3 id="verify-installation" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Verifying the Installation
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        To confirm everything is installed correctly, create a simple test file and verify the import
        resolves without errors:
      </p>
      <CodeBlock
        title="lib/verify_reacton.dart"
        code={`import 'package:reacton/reacton.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

// If your IDE shows no errors on these imports,
// Reacton is installed correctly!
final testAtom = atom(42, name: 'test');`}
      />
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        You can also run{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">flutter pub deps</code>{' '}
        to see the resolved dependency tree and confirm both{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton</code>{' '}
        and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">flutter_reacton</code>{' '}
        appear in the output.
      </p>

      <Callout type="info" title="Pure Dart projects">
        If you are building a server-side Dart application, CLI tool, or a package that does not depend
        on Flutter, you only need the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">reacton</code>{' '}
        package. The core reactive primitives work without any Flutter dependency.
      </Callout>

      {/* ================================================================== */}
      {/* PROJECT STRUCTURE */}
      {/* ================================================================== */}
      <h2 id="project-structure" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Recommended Project Structure
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Reacton does not enforce any particular directory layout — you are free to organize your project
        however you like. However, as your app grows, a consistent structure makes it easier to find
        atoms, computed values, and the widgets that consume them. Below is a battle-tested structure
        that works well for medium-to-large Reacton applications:
      </p>
      <CodeBlock
        language="bash"
        title="Recommended directory layout"
        code={`lib/
├── main.dart                  # App entry point, ReactonScope setup
├── atoms/                     # All atom definitions
│   ├── auth_atoms.dart        # Authentication-related atoms
│   ├── counter_atoms.dart     # Counter feature atoms
│   └── theme_atoms.dart       # Theme/UI preference atoms
├── computed/                  # Derived state (computed values)
│   ├── auth_computed.dart     # Derived auth state
│   └── cart_computed.dart     # Derived shopping cart totals
├── effects/                   # Side effects
│   └── analytics_effects.dart # Logging, analytics side effects
├── features/                  # Feature-based modules
│   ├── auth/
│   │   ├── login_page.dart
│   │   └── signup_page.dart
│   ├── home/
│   │   └── home_page.dart
│   └── settings/
│       └── settings_page.dart
├── widgets/                   # Shared, reusable widgets
│   ├── reacton_counter.dart
│   └── user_avatar.dart
└── utils/                     # Helpers, constants, extensions
    └── validators.dart`}
      />

      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The key principles behind this structure are:
      </p>
      <ul className="list-disc pl-6 mb-6 space-y-2 text-gray-600 dark:text-gray-400 leading-relaxed">
        <li>
          <strong className="text-gray-900 dark:text-white">Atoms are top-level and grouped by domain.</strong>{' '}
          Keeping atoms in a dedicated{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">atoms/</code>{' '}
          directory makes them easy to discover and prevents accidental duplication.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Computed values live separately from atoms.</strong>{' '}
          This keeps derivation logic distinct from source-of-truth state, making it clear which values
          are computed and which are primary.
        </li>
        <li>
          <strong className="text-gray-900 dark:text-white">Features are self-contained directories.</strong>{' '}
          Each feature folder contains its pages and feature-specific widgets. These files import atoms
          from the shared{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">atoms/</code>{' '}
          and{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">computed/</code>{' '}
          directories.
        </li>
      </ul>

      <Callout type="tip" title="Small projects">
        For small apps or prototypes, you can skip the directory hierarchy and declare everything
        in a single{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">state.dart</code>{' '}
        file alongside your{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">main.dart</code>.
        Reacton scales seamlessly — start simple and refactor when needed.
      </Callout>

      {/* ================================================================== */}
      {/* QUICK START */}
      {/* ================================================================== */}
      <h2 id="quick-start" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Quick Start — Step by Step
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-6 leading-relaxed">
        This walkthrough takes you from zero to a fully reactive Flutter app. Each step introduces a
        core Reacton concept and builds on the previous one. Follow along in order to develop a solid
        mental model of how Reacton works under the hood.
      </p>

      {/* Step 1 */}
      <div className="relative pl-12 pb-10 border-l-2 border-gray-200 dark:border-gray-800 ml-4">
        <div className="absolute -left-4 top-0 w-8 h-8 rounded-full bg-gradient-to-br from-indigo-500 to-purple-500 flex items-center justify-center text-white text-sm font-bold">
          1
        </div>
        <h3 id="step-1-atoms" className="text-xl font-semibold mb-3 text-gray-900 dark:text-white">
          Creating Your First Atoms
        </h3>
        <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
          An <strong className="text-gray-900 dark:text-white">atom</strong> is the smallest unit of reactive state in Reacton. Think
          of it as a named container that holds a single value — an integer, a string, a list, a custom
          object, or anything else. When the value inside an atom changes, every widget that is watching
          that atom automatically rebuilds. Atoms are the foundation of Reacton's reactivity model.
        </p>
        <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
          Atoms must be declared as <strong className="text-gray-900 dark:text-white">top-level variables</strong> (outside
          of any class or function). This is intentional: because atoms are definitions — not instances —
          they describe <em>what</em> state exists, not the actual runtime value. The actual values are
          stored inside a{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonStore</code>,
          which we will set up in Step 2. Declaring atoms at the top level keeps them as lightweight,
          reusable references that multiple widgets can share.
        </p>
        <CodeBlock
          title="lib/atoms/counter_atoms.dart"
          code={`import 'package:reacton/reacton.dart';

// A simple integer atom with an initial value of 0.
// The 'name' parameter is used for debugging and DevTools.
final counterAtom = atom(0, name: 'counter');

// A string atom to hold the user's name.
final nameAtom = atom('', name: 'userName');

// A boolean atom for toggling dark mode.
final isDarkModeAtom = atom(false, name: 'isDarkMode');

// Atoms can hold any type — lists, maps, custom classes.
final todosAtom = atom<List<String>>([], name: 'todos');`}
        />

        <Callout type="info" title="Naming conventions">
          By convention, atom variable names end with the suffix{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Atom</code>{' '}
          (e.g.,{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">counterAtom</code>,{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">userAtom</code>).
          The{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">name</code>{' '}
          parameter passed to{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">atom()</code>{' '}
          is a human-readable label used in Reacton DevTools and debug logs. Always provide one — it makes
          debugging dramatically easier.
        </Callout>

        <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
          The generic type is usually inferred from the initial value. For empty collections or nullable
          types, provide an explicit type parameter so Dart knows what you intend:
        </p>
        <CodeBlock
          code={`// Type inferred as atom<int> from the literal 0.
final counterAtom = atom(0, name: 'counter');

// Explicit type needed — Dart can't infer List<String> from [].
final todosAtom = atom<List<String>>([], name: 'todos');

// Explicit type for nullable values.
final selectedUserAtom = atom<User?>(null, name: 'selectedUser');`}
        />
      </div>

      {/* Step 2 */}
      <div className="relative pl-12 pb-10 border-l-2 border-gray-200 dark:border-gray-800 ml-4">
        <div className="absolute -left-4 top-0 w-8 h-8 rounded-full bg-gradient-to-br from-indigo-500 to-purple-500 flex items-center justify-center text-white text-sm font-bold">
          2
        </div>
        <h3 id="step-2-reactonscope" className="text-xl font-semibold mb-3 text-gray-900 dark:text-white">
          Setting Up ReactonScope
        </h3>
        <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonScope</code>{' '}
          is an{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">InheritedWidget</code>{' '}
          that injects a{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonStore</code>{' '}
          into the widget tree. The store is the runtime container that holds the actual values for all
          your atoms. Every widget below a{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonScope</code>{' '}
          can read and write state through{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context</code>{' '}
          extension methods.
        </p>
        <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
          You typically place a single{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonScope</code>{' '}
          at the root of your app, wrapping your{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">MaterialApp</code>{' '}
          or{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">CupertinoApp</code>.
          This gives every page and widget in your application access to the same shared store.
        </p>
        <CodeBlock
          title="lib/main.dart"
          code={`import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

void main() {
  // Create a store instance. This holds runtime values for all atoms.
  final store = ReactonStore();

  runApp(
    ReactonScope(
      store: store,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reacton Demo',
      theme: ThemeData(useMaterial3: true),
      home: const HomePage(),
    );
  }
}`}
        />

        <Callout type="warning" title="Don't forget ReactonScope!">
          If you try to call{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch()</code>{' '}
          or{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.set()</code>{' '}
          without a{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonScope</code>{' '}
          ancestor in the widget tree, you will get a runtime error. Always ensure your app is wrapped.
        </Callout>

        <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
          For advanced scenarios, you can nest multiple{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonScope</code>{' '}
          widgets with different stores. This is useful for isolated feature modules or testing where
          you want separate state containers:
        </p>
        <CodeBlock
          title="Nested scopes (advanced)"
          code={`// The inner ReactonScope creates an isolated state boundary.
// Widgets inside it read from the inner store,
// while widgets outside still use the outer store.

ReactonScope(
  store: ReactonStore(),   // outer / global store
  child: MaterialApp(
    home: ReactonScope(
      store: ReactonStore(), // inner / feature-scoped store
      child: const FeatureScreen(),
    ),
  ),
)`}
        />
      </div>

      {/* Step 3 */}
      <div className="relative pl-12 pb-10 border-l-2 border-gray-200 dark:border-gray-800 ml-4">
        <div className="absolute -left-4 top-0 w-8 h-8 rounded-full bg-gradient-to-br from-indigo-500 to-purple-500 flex items-center justify-center text-white text-sm font-bold">
          3
        </div>
        <h3 id="step-3-watch" className="text-xl font-semibold mb-3 text-gray-900 dark:text-white">
          Reading State with context.watch()
        </h3>
        <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch(atom)</code>{' '}
          is the primary way to read atom values inside a widget's{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">build()</code>{' '}
          method. It does two things: it returns the current value of the atom, and it{' '}
          <strong className="text-gray-900 dark:text-white">subscribes</strong> the widget so that it automatically
          rebuilds whenever that atom's value changes.
        </p>
        <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
          Under the hood, Reacton registers a listener on the atom within the store. When the atom's value
          is updated (via{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">set</code>{' '}
          or{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">update</code>),
          the store notifies all subscribed widgets, triggering a rebuild. The subscription is
          automatically cleaned up when the widget is disposed.
        </p>
        <CodeBlock
          title="lib/features/home/home_page.dart"
          code={`import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';
import '../../atoms/counter_atoms.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // watch() subscribes this widget to counterAtom.
    // Whenever counterAtom's value changes, build() re-runs.
    final count = context.watch(counterAtom);

    // watch() multiple atoms — the widget rebuilds
    // when ANY of them change.
    final name = context.watch(nameAtom);

    return Scaffold(
      appBar: AppBar(title: Text('Hello, \$name')),
      body: Center(
        child: Text(
          '\$count',
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ),
    );
  }
}`}
        />

        <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
          Reacton also provides{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.read(atom)</code>{' '}
          for one-time, non-reactive reads. Use{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read()</code>{' '}
          inside event handlers, callbacks, or{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">initState()</code>{' '}
          — places where you need the current value but do not want to subscribe to future changes.
        </p>
        <CodeBlock
          code={`// GOOD: read() in an event handler — no subscription needed.
onPressed: () {
  final current = context.read(counterAtom);
  print('Button pressed, current count: \$current');
}

// BAD: read() inside build() — the widget won't rebuild on changes!
// Use watch() instead if you need the UI to stay in sync.`}
        />

        <Callout type="danger" title="watch() vs read() in build()">
          Never use{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.read()</code>{' '}
          inside the{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">build()</code>{' '}
          method to display data. The widget will render the initial value but will never update when
          the atom changes. Always use{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch()</code>{' '}
          in{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">build()</code>{' '}
          for reactive UI.
        </Callout>
      </div>

      {/* Step 4 */}
      <div className="relative pl-12 pb-10 border-l-2 border-gray-200 dark:border-gray-800 ml-4">
        <div className="absolute -left-4 top-0 w-8 h-8 rounded-full bg-gradient-to-br from-indigo-500 to-purple-500 flex items-center justify-center text-white text-sm font-bold">
          4
        </div>
        <h3 id="step-4-write" className="text-xl font-semibold mb-3 text-gray-900 dark:text-white">
          Writing State with context.set() and context.update()
        </h3>
        <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
          Reacton provides two ways to write to an atom, each suited to different use cases:
        </p>
        <ul className="list-disc pl-6 mb-6 space-y-3 text-gray-600 dark:text-gray-400 leading-relaxed">
          <li>
            <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.set(atom, newValue)</code>{' '}
            — <strong className="text-gray-900 dark:text-white">Replaces</strong> the atom's value entirely. Use this when
            you already know the exact value you want to store and do not need the previous value.
          </li>
          <li>
            <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.update(atom, (current) =&gt; newValue)</code>{' '}
            — <strong className="text-gray-900 dark:text-white">Transforms</strong> the atom's value using a function that
            receives the current value and returns the new value. Use this when the next value depends
            on the previous one (incrementing, toggling, appending to a list, etc.).
          </li>
        </ul>
        <CodeBlock
          title="set() vs update() examples"
          code={`// ---------- set() — replace the entire value ----------

// Set the counter to a specific number.
context.set(counterAtom, 42);

// Set the user's name from a text field.
context.set(nameAtom, textController.text);

// Reset a list to empty.
context.set(todosAtom, []);


// ---------- update() — transform based on current value ----------

// Increment the counter by 1.
context.update(counterAtom, (n) => n + 1);

// Toggle a boolean.
context.update(isDarkModeAtom, (isDark) => !isDark);

// Append an item to a list (create a new list to trigger change).
context.update(todosAtom, (list) => [...list, 'New todo']);

// Remove an item from a list.
context.update(todosAtom, (list) => list.where((t) => t != 'Done').toList());`}
        />

        <Callout type="tip" title="When to use which?">
          <strong>Rule of thumb:</strong> if you are typing a literal value, use{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">set()</code>.
          If your new value is computed from the old value, use{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">update()</code>.
          Using{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">update()</code>{' '}
          avoids race conditions because it atomically reads and writes in one step.
        </Callout>

        <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
          Here is a complete widget that demonstrates both methods together:
        </p>
        <CodeBlock
          title="lib/widgets/counter_controls.dart"
          code={`class CounterControls extends StatelessWidget {
  const CounterControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Decrement — depends on current value, so use update().
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () => context.update(counterAtom, (n) => n - 1),
        ),

        // Reset — we know the exact value, so use set().
        TextButton(
          onPressed: () => context.set(counterAtom, 0),
          child: const Text('Reset'),
        ),

        // Increment — depends on current value, so use update().
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => context.update(counterAtom, (n) => n + 1),
        ),
      ],
    );
  }
}`}
        />
      </div>

      {/* Step 5 */}
      <div className="relative pl-12 pb-10 border-l-2 border-gray-200 dark:border-gray-800 ml-4">
        <div className="absolute -left-4 top-0 w-8 h-8 rounded-full bg-gradient-to-br from-indigo-500 to-purple-500 flex items-center justify-center text-white text-sm font-bold">
          5
        </div>
        <h3 id="step-5-computed" className="text-xl font-semibold mb-3 text-gray-900 dark:text-white">
          Derived State with computed()
        </h3>
        <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">computed()</code>{' '}
          creates a <strong className="text-gray-900 dark:text-white">read-only, derived atom</strong> whose value is
          automatically calculated from other atoms. You provide a function that receives a{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read</code>{' '}
          callback — use it to read the values of other atoms. Reacton automatically tracks which atoms
          you read and recalculates the derived value only when one of those dependencies changes.
        </p>
        <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
          Computed values are <strong className="text-gray-900 dark:text-white">lazily evaluated</strong>: they are not
          computed until something actually reads them. They are also{' '}
          <strong className="text-gray-900 dark:text-white">cached</strong>: if none of the dependencies have changed,
          re-reading a computed value returns the cached result without re-executing the derivation
          function. This makes computed values highly efficient even for expensive calculations.
        </p>
        <CodeBlock
          title="lib/computed/counter_computed.dart"
          code={`import 'package:reacton/reacton.dart';
import '../atoms/counter_atoms.dart';

// Derived atom: always equals counterAtom * 2.
// Recalculates only when counterAtom changes.
final doubleCountAtom = computed(
  (read) => read(counterAtom) * 2,
  name: 'doubleCount',
);

// Derived atom from multiple sources.
final summaryAtom = computed(
  (read) {
    final count = read(counterAtom);
    final name = read(nameAtom);
    return '\$name has counted to \$count';
  },
  name: 'summary',
);

// Derived boolean — useful for conditional UI.
final isHighAtom = computed(
  (read) => read(counterAtom) > 100,
  name: 'isHigh',
);`}
        />

        <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
          You consume computed atoms exactly like regular atoms — with{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch()</code>{' '}
          and{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.read()</code>.
          The only difference is that you cannot write to a computed atom (no{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">set()</code>{' '}
          or{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">update()</code>)
          because its value is entirely determined by the derivation function.
        </p>
        <CodeBlock
          code={`// In a widget's build() method:
final doubled = context.watch(doubleCountAtom);
final summary = context.watch(summaryAtom);

// Both values stay perfectly in sync with counterAtom
// and nameAtom, with zero manual wiring required.`}
        />

        <Callout type="info" title="Auto-dependency tracking">
          You do not need to declare dependencies manually. Reacton automatically discovers which atoms
          your computed function reads by tracking calls to{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read()</code>{' '}
          at runtime. If your derivation conditionally reads different atoms (e.g., inside an{' '}
          <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">if</code>{' '}
          statement), Reacton correctly updates the dependency set each time the computed value
          recalculates.
        </Callout>
      </div>

      {/* ================================================================== */}
      {/* COMPLETE EXAMPLE */}
      {/* ================================================================== */}
      <h2 id="complete-example" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Complete Example
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Here is a fully working Flutter application that ties together every concept from the walkthrough:
        atom creation, ReactonScope setup, reactive reads with{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">watch()</code>,
        state updates with{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">set()</code>{' '}
        and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">update()</code>,
        and derived state with{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">computed()</code>.
        Copy this into your project and run it to see Reacton in action.
      </p>
      <CodeBlock
        title="lib/main.dart — Complete counter app with derived state"
        code={`import 'package:flutter/material.dart';
import 'package:reacton/reacton.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

// ──────────────────────────────────────────────
// 1. Define atoms (top-level)
// ──────────────────────────────────────────────
final counterAtom = atom(0, name: 'counter');
final stepSizeAtom = atom(1, name: 'stepSize');

// ──────────────────────────────────────────────
// 2. Define computed / derived state
// ──────────────────────────────────────────────
final doubleCountAtom = computed(
  (read) => read(counterAtom) * 2,
  name: 'doubleCount',
);

final isEvenAtom = computed(
  (read) => read(counterAtom) % 2 == 0,
  name: 'isEven',
);

final statusMessageAtom = computed(
  (read) {
    final count = read(counterAtom);
    final isEven = read(isEvenAtom);
    return 'Count is \$count (\${isEven ? "even" : "odd"})';
  },
  name: 'statusMessage',
);

// ──────────────────────────────────────────────
// 3. Wrap the app with ReactonScope
// ──────────────────────────────────────────────
void main() {
  runApp(
    ReactonScope(
      store: ReactonStore(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reacton Counter',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const CounterPage(),
    );
  }
}

// ──────────────────────────────────────────────
// 4. Build reactive UI
// ──────────────────────────────────────────────
class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Reactive reads — this widget rebuilds when any of these change.
    final count = context.watch(counterAtom);
    final doubled = context.watch(doubleCountAtom);
    final status = context.watch(statusMessageAtom);
    final step = context.watch(stepSizeAtom);

    return Scaffold(
      appBar: AppBar(title: const Text('Reacton Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(status, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '\$count',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            Text(
              'Doubled: \$doubled',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // update() — next value depends on current value
                FilledButton.tonalIcon(
                  onPressed: () => context.update(
                    counterAtom,
                    (n) => n - step,
                  ),
                  icon: const Icon(Icons.remove),
                  label: Text('-\$step'),
                ),
                const SizedBox(width: 12),
                // set() — we know the exact target value
                OutlinedButton(
                  onPressed: () => context.set(counterAtom, 0),
                  child: const Text('Reset'),
                ),
                const SizedBox(width: 12),
                // update() — next value depends on current value
                FilledButton.tonalIcon(
                  onPressed: () => context.update(
                    counterAtom,
                    (n) => n + step,
                  ),
                  icon: const Icon(Icons.add),
                  label: Text('+\$step'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Step size selector
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 5, label: Text('5')),
                ButtonSegment(value: 10, label: Text('10')),
              ],
              selected: {step},
              onSelectionChanged: (values) {
                context.set(stepSizeAtom, values.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}`}
      />

      {/* ================================================================== */}
      {/* CORE API QUICK REFERENCE */}
      {/* ================================================================== */}
      <h2 id="core-api" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Core API Quick Reference
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        The table below covers every API you will use regularly in Reacton, organized into two tiers.{' '}
        <strong className="text-gray-900 dark:text-white">Level 1</strong> APIs are the essential primitives
        you will use in every app.{' '}
        <strong className="text-gray-900 dark:text-white">Level 2</strong> APIs unlock advanced patterns for
        larger or more complex applications.
      </p>

      {/* Level 1 table */}
      <h3 id="level-1-apis" className="text-lg font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Level 1 — Essential Primitives
      </h3>
      <div className="overflow-x-auto mb-6">
        <table className="w-full text-sm border-collapse">
          <thead>
            <tr className="border-b border-gray-200 dark:border-gray-800">
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">API</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Type</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Description</th>
            </tr>
          </thead>
          <tbody className="text-gray-600 dark:text-gray-400">
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4">
                <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">atom(value)</code>
              </td>
              <td className="py-3 px-4">Definition</td>
              <td className="py-3 px-4">Creates a writable atom with the given initial value. Atoms are the fundamental unit of reactive state.</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4">
                <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">{"computed((read) => ...)"}</code>
              </td>
              <td className="py-3 px-4">Definition</td>
              <td className="py-3 px-4">Creates a read-only derived atom. Automatically tracks dependencies and caches results. Recalculates only when dependencies change.</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4">
                <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch(atom)</code>
              </td>
              <td className="py-3 px-4">Read (reactive)</td>
              <td className="py-3 px-4">Returns the current value and subscribes the widget to future changes. Use in{' '}
                <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">build()</code>.
              </td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4">
                <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.read(atom)</code>
              </td>
              <td className="py-3 px-4">Read (one-time)</td>
              <td className="py-3 px-4">Returns the current value without subscribing. Use in event handlers, callbacks, and{' '}
                <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">initState()</code>.
              </td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4">
                <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.set(atom, value)</code>
              </td>
              <td className="py-3 px-4">Write</td>
              <td className="py-3 px-4">Replaces the atom's value. All widgets watching this atom rebuild.</td>
            </tr>
            <tr>
              <td className="py-3 px-4">
                <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.update(atom, fn)</code>
              </td>
              <td className="py-3 px-4">Write</td>
              <td className="py-3 px-4">Transforms the value using a function{' '}
                <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">(T) =&gt; T</code>.
                Atomically reads then writes.
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      {/* Level 2 table */}
      <h3 id="level-2-apis" className="text-lg font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Level 2 — Advanced APIs
      </h3>
      <div className="overflow-x-auto mb-6">
        <table className="w-full text-sm border-collapse">
          <thead>
            <tr className="border-b border-gray-200 dark:border-gray-800">
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">API</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Type</th>
              <th className="text-left py-3 px-4 font-semibold text-gray-900 dark:text-white">Description</th>
            </tr>
          </thead>
          <tbody className="text-gray-600 dark:text-gray-400">
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4">
                <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">{"effect((read) { ... })"}</code>
              </td>
              <td className="py-3 px-4">Side effect</td>
              <td className="py-3 px-4">Runs a callback whenever its tracked dependencies change. Used for logging, analytics, persistence, and other side effects.</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4">
                <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">{"selector((read) => ...)"}</code>
              </td>
              <td className="py-3 px-4">Definition</td>
              <td className="py-3 px-4">Like computed, but only notifies subscribers when the output value actually changes (deep equality). Ideal for expensive derivations producing the same result.</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4">
                <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">{"family((param) => atom(...))"}</code>
              </td>
              <td className="py-3 px-4">Definition</td>
              <td className="py-3 px-4">Creates a parameterized family of atoms. Each unique parameter yields a distinct atom instance. Great for per-item state (e.g., todo completion by ID).</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4">
                <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">{"asyncAtom(future)"}</code>
              </td>
              <td className="py-3 px-4">Definition</td>
              <td className="py-3 px-4">Creates an atom backed by an asynchronous operation. Provides loading, data, and error states automatically.</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4">
                <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonScope</code>
              </td>
              <td className="py-3 px-4">Widget</td>
              <td className="py-3 px-4">InheritedWidget that provides a ReactonStore to the widget tree. Required ancestor for all context extensions.</td>
            </tr>
            <tr className="border-b border-gray-100 dark:border-gray-800/50">
              <td className="py-3 px-4">
                <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">{"ReactonBuilder(atom, builder)"}</code>
              </td>
              <td className="py-3 px-4">Widget</td>
              <td className="py-3 px-4">Scoped builder widget that rebuilds only itself when the given atom changes. More granular than watching in a parent widget.</td>
            </tr>
            <tr>
              <td className="py-3 px-4">
                <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonConsumer</code>
              </td>
              <td className="py-3 px-4">Widget</td>
              <td className="py-3 px-4">Provides both a watch and read function within its builder. Useful when you need to read multiple atoms and also write state without a StatelessWidget.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <Callout type="tip" title="Progressive API">
        You do not need to learn all of these at once. Start with{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">atom</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">computed</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">watch</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">set</code>,
        and{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">update</code>.
        That covers 90% of real-world use cases. Add Level 2 APIs only when you encounter a specific need.
      </Callout>

      {/* ================================================================== */}
      {/* COMMON PATTERNS */}
      {/* ================================================================== */}
      <h2 id="common-patterns" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Common Patterns
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-6 leading-relaxed">
        The following patterns appear frequently in Reacton applications. Study them to develop an
        intuition for how to structure reactive state in different scenarios.
      </p>

      {/* Pattern 1: Counter */}
      <h3 id="pattern-counter" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Pattern 1: Counter with Undo
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        A counter that tracks its previous value and supports undo. This demonstrates using multiple
        atoms together and derived state for conditional UI.
      </p>
      <CodeBlock
        title="Counter with undo"
        code={`// Atoms
final counterAtom = atom(0, name: 'counter');
final previousAtom = atom<int?>(null, name: 'previous');

// Computed — can we undo?
final canUndoAtom = computed(
  (read) => read(previousAtom) != null,
  name: 'canUndo',
);

// Widget
class UndoableCounter extends StatelessWidget {
  const UndoableCounter({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch(counterAtom);
    final canUndo = context.watch(canUndoAtom);

    return Column(
      children: [
        Text('Count: \$count'),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                // Save current value before changing
                context.set(previousAtom, context.read(counterAtom));
                context.update(counterAtom, (n) => n + 1);
              },
              child: const Text('Increment'),
            ),
            ElevatedButton(
              onPressed: canUndo
                  ? () {
                      final prev = context.read(previousAtom);
                      context.set(counterAtom, prev!);
                      context.set(previousAtom, null);
                    }
                  : null, // disabled when nothing to undo
              child: const Text('Undo'),
            ),
          ],
        ),
      ],
    );
  }
}`}
      />

      {/* Pattern 2: Form State */}
      <h3 id="pattern-form" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Pattern 2: Form State
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Managing form inputs reactively. Each field is an atom, and computed values derive validation
        state and whether the form can be submitted. This pattern is clean and testable because the
        validation logic is pure functions with no widget dependency.
      </p>
      <CodeBlock
        title="Reactive form with validation"
        code={`// ── Atoms (one per form field) ──
final emailAtom = atom('', name: 'email');
final passwordAtom = atom('', name: 'password');
final acceptedTermsAtom = atom(false, name: 'acceptedTerms');

// ── Computed: field-level validation ──
final emailErrorAtom = computed((read) {
  final email = read(emailAtom);
  if (email.isEmpty) return null;
  if (!email.contains('@')) return 'Invalid email address';
  return null;
}, name: 'emailError');

final passwordErrorAtom = computed((read) {
  final password = read(passwordAtom);
  if (password.isEmpty) return null;
  if (password.length < 8) return 'Must be at least 8 characters';
  return null;
}, name: 'passwordError');

// ── Computed: form-level validation ──
final isFormValidAtom = computed((read) {
  final email = read(emailAtom);
  final password = read(passwordAtom);
  final accepted = read(acceptedTermsAtom);
  final emailErr = read(emailErrorAtom);
  final passErr = read(passwordErrorAtom);
  return email.isNotEmpty &&
      password.isNotEmpty &&
      accepted &&
      emailErr == null &&
      passErr == null;
}, name: 'isFormValid');

// ── Widget ──
class SignUpForm extends StatelessWidget {
  const SignUpForm({super.key});

  @override
  Widget build(BuildContext context) {
    final emailError = context.watch(emailErrorAtom);
    final passwordError = context.watch(passwordErrorAtom);
    final isValid = context.watch(isFormValidAtom);
    final accepted = context.watch(acceptedTermsAtom);

    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Email',
            errorText: emailError,
          ),
          onChanged: (v) => context.set(emailAtom, v),
        ),
        TextField(
          decoration: InputDecoration(
            labelText: 'Password',
            errorText: passwordError,
          ),
          obscureText: true,
          onChanged: (v) => context.set(passwordAtom, v),
        ),
        CheckboxListTile(
          title: const Text('I accept the terms'),
          value: accepted,
          onChanged: (v) => context.set(acceptedTermsAtom, v ?? false),
        ),
        FilledButton(
          onPressed: isValid ? () => _submit(context) : null,
          child: const Text('Sign Up'),
        ),
      ],
    );
  }

  void _submit(BuildContext context) {
    final email = context.read(emailAtom);
    final password = context.read(passwordAtom);
    // Send to API...
    print('Signing up \$email');
  }
}`}
      />

      {/* Pattern 3: List / CRUD */}
      <h3 id="pattern-crud" className="text-xl font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Pattern 3: List / CRUD
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Managing a list of items with create, read, update, and delete operations. The key insight is
        that Reacton atoms hold immutable values — when you modify a list, you create a new list and set
        it back on the atom. Computed values derive filtered views and aggregations.
      </p>
      <CodeBlock
        title="Todo list with CRUD and filtering"
        code={`// ── Model ──
class Todo {
  final String id;
  final String title;
  final bool completed;
  const Todo({required this.id, required this.title, this.completed = false});
  Todo copyWith({String? title, bool? completed}) =>
      Todo(id: id, title: title ?? this.title, completed: completed ?? this.completed);
}

// ── Atoms ──
final todosAtom = atom<List<Todo>>([], name: 'todos');
final filterAtom = atom<String>('all', name: 'filter'); // 'all' | 'active' | 'done'

// ── Computed ──
final filteredTodosAtom = computed((read) {
  final todos = read(todosAtom);
  final filter = read(filterAtom);
  switch (filter) {
    case 'active':
      return todos.where((t) => !t.completed).toList();
    case 'done':
      return todos.where((t) => t.completed).toList();
    default:
      return todos;
  }
}, name: 'filteredTodos');

final remainingCountAtom = computed(
  (read) => read(todosAtom).where((t) => !t.completed).length,
  name: 'remainingCount',
);

// ── CRUD helper functions ──
void addTodo(BuildContext context, String title) {
  final id = DateTime.now().millisecondsSinceEpoch.toString();
  context.update(todosAtom, (list) => [...list, Todo(id: id, title: title)]);
}

void toggleTodo(BuildContext context, String id) {
  context.update(todosAtom, (list) =>
      list.map((t) => t.id == id ? t.copyWith(completed: !t.completed) : t).toList());
}

void deleteTodo(BuildContext context, String id) {
  context.update(todosAtom, (list) => list.where((t) => t.id != id).toList());
}

// ── Widget ──
class TodoList extends StatelessWidget {
  const TodoList({super.key});

  @override
  Widget build(BuildContext context) {
    final todos = context.watch(filteredTodosAtom);
    final remaining = context.watch(remainingCountAtom);

    return Column(
      children: [
        Text('\$remaining items remaining'),
        // Filter buttons
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'all', label: Text('All')),
            ButtonSegment(value: 'active', label: Text('Active')),
            ButtonSegment(value: 'done', label: Text('Done')),
          ],
          selected: {context.watch(filterAtom)},
          onSelectionChanged: (v) => context.set(filterAtom, v.first),
        ),
        // Todo items
        ...todos.map((todo) => ListTile(
              title: Text(todo.title),
              leading: Checkbox(
                value: todo.completed,
                onChanged: (_) => toggleTodo(context, todo.id),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => deleteTodo(context, todo.id),
              ),
            )),
      ],
    );
  }
}`}
      />

      {/* ================================================================== */}
      {/* TROUBLESHOOTING */}
      {/* ================================================================== */}
      <h2 id="troubleshooting" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        Troubleshooting
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-6 leading-relaxed">
        Here are the most common mistakes beginners make with Reacton, along with explanations of why
        they happen and how to fix them.
      </p>

      {/* Mistake 1 */}
      <h3 id="mistake-atoms-in-build" className="text-lg font-semibold mt-6 mb-3 text-gray-900 dark:text-white">
        Mistake 1: Creating atoms inside build()
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Atoms are <em>definitions</em> — they describe a piece of state, not the value itself. If you
        create an atom inside a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">build()</code>{' '}
        method, you get a brand-new atom definition on every rebuild, which means the widget is always
        watching a <em>different</em> atom and the state never persists.
      </p>
      <CodeBlock
        title="BAD — atom created inside build()"
        code={`class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // BAD: A new atom is created on every single rebuild.
    // State is lost because each rebuild creates a different atom.
    final counterAtom = atom(0, name: 'counter');
    final count = context.watch(counterAtom);
    return Text('\$count');
  }
}`}
      />
      <CodeBlock
        title="GOOD — atom declared at the top level"
        code={`// GOOD: Declared once, shared across all widgets.
final counterAtom = atom(0, name: 'counter');

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.watch(counterAtom);
    return Text('\$count');
  }
}`}
      />

      {/* Mistake 2 */}
      <h3 id="mistake-read-in-build" className="text-lg font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Mistake 2: Using read() instead of watch() in build()
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.read()</code>{' '}
        fetches the current value but does <strong className="text-gray-900 dark:text-white">not</strong> subscribe the widget
        to changes. If you use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read()</code>{' '}
        inside{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">build()</code>,
        the widget renders the initial value but never updates.
      </p>
      <CodeBlock
        title="BAD vs GOOD — reading in build()"
        code={`class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // BAD: Shows "0" forever even after counterAtom changes.
    final count = context.read(counterAtom);

    // GOOD: Rebuilds whenever counterAtom changes.
    final count = context.watch(counterAtom);

    return Text('\$count');
  }
}`}
      />

      <Callout type="info" title="When to use read()">
        Use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">read()</code>{' '}
        in event handlers like{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onPressed</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">onChanged</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">initState()</code>,
        or any code that runs <em>outside</em> of the{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">build()</code>{' '}
        method. In those cases, you want a snapshot of the current value, not a subscription.
      </Callout>

      {/* Mistake 3 */}
      <h3 id="mistake-missing-scope" className="text-lg font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Mistake 3: Forgetting ReactonScope
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        If you see a runtime error like{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">No ReactonScope found in the widget tree</code>,
        it means you are trying to use{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.watch()</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.read()</code>,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.set()</code>,
        or{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">context.update()</code>{' '}
        without a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonScope</code>{' '}
        ancestor. Fix this by wrapping your app (or the relevant subtree) in a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">ReactonScope</code>.
      </p>
      <CodeBlock
        title="Fix: wrap with ReactonScope"
        code={`void main() {
  runApp(
    // This MUST be an ancestor of any widget that uses context.watch() etc.
    ReactonScope(
      store: ReactonStore(),
      child: const MyApp(),
    ),
  );
}`}
      />

      {/* Mistake 4 */}
      <h3 id="mistake-type-inference" className="text-lg font-semibold mt-8 mb-3 text-gray-900 dark:text-white">
        Mistake 4: Type inference issues with computed()
      </h3>
      <p className="text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
        Dart can sometimes struggle to infer the return type of a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">computed()</code>{' '}
        function, especially with conditional logic, nullable types, or complex expressions. If you
        see type errors or unexpected{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">dynamic</code>{' '}
        types, provide an explicit type parameter.
      </p>
      <CodeBlock
        title="Explicit types for computed()"
        code={`// BAD: Dart may infer 'Object' or 'dynamic' due to mixed return types.
final resultAtom = computed((read) {
  if (read(counterAtom) > 10) return 'High';
  return read(counterAtom); // returns int — now the function returns Object
});

// GOOD: Explicit type parameter makes the intent clear.
final resultAtom = computed<String>((read) {
  final count = read(counterAtom);
  if (count > 10) return 'High';
  return count.toString();
}, name: 'result');

// GOOD: Nullable types must be explicit.
final maybeUserAtom = computed<User?>((read) {
  final id = read(selectedIdAtom);
  return read(usersAtom).where((u) => u.id == id).firstOrNull;
}, name: 'maybeUser');`}
      />

      <Callout type="warning" title="Mutating collections in place">
        Reacton detects changes by reference comparison. If you mutate a{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">List</code>{' '}
        or{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">Map</code>{' '}
        in place (e.g.,{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">list.add(item)</code>)
        and set the same list back, Reacton will not detect a change because the reference has not changed.
        Always create a <strong>new</strong> collection:{' '}
        <code className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 text-sm font-mono font-medium">[...list, item]</code>.
      </Callout>

      {/* ================================================================== */}
      {/* WHAT'S NEXT */}
      {/* ================================================================== */}
      <h2 id="whats-next" className="text-2xl font-bold mt-12 mb-4 pt-8 border-t border-gray-200 dark:border-gray-800">
        What's Next
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-6 leading-relaxed">
        You now have a solid foundation in Reacton. You understand atoms, the ReactonScope/store model,
        reactive reads with watch(), state writes with set() and update(), derived state with computed(),
        and common patterns for real-world apps. From here, explore the rest of the documentation to
        unlock the full power of Reacton.
      </p>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
        <a
          href="#/core-concepts"
          className="group block p-6 rounded-xl border border-gray-200 dark:border-gray-800 hover:border-indigo-300 dark:hover:border-indigo-700 hover:shadow-lg hover:shadow-indigo-500/5 transition-all"
        >
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-1 group-hover:text-indigo-600 dark:group-hover:text-indigo-400 transition-colors">
            Core Concepts
          </h3>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Deep dive into atoms, computed values, effects, selectors, and families. Understand the
            reactive graph model.
          </p>
        </a>
        <a
          href="#/flutter-widgets"
          className="group block p-6 rounded-xl border border-gray-200 dark:border-gray-800 hover:border-indigo-300 dark:hover:border-indigo-700 hover:shadow-lg hover:shadow-indigo-500/5 transition-all"
        >
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-1 group-hover:text-indigo-600 dark:group-hover:text-indigo-400 transition-colors">
            Flutter Widgets
          </h3>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Learn about ReactonBuilder, ReactonConsumer, ReactonScope nesting, and performance optimization
            techniques.
          </p>
        </a>
        <a
          href="#/async"
          className="group block p-6 rounded-xl border border-gray-200 dark:border-gray-800 hover:border-indigo-300 dark:hover:border-indigo-700 hover:shadow-lg hover:shadow-indigo-500/5 transition-all"
        >
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-1 group-hover:text-indigo-600 dark:group-hover:text-indigo-400 transition-colors">
            Async State
          </h3>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Handle API calls, loading states, and error handling with asyncAtom and async computed
            values.
          </p>
        </a>
        <a
          href="#/testing"
          className="group block p-6 rounded-xl border border-gray-200 dark:border-gray-800 hover:border-indigo-300 dark:hover:border-indigo-700 hover:shadow-lg hover:shadow-indigo-500/5 transition-all"
        >
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-1 group-hover:text-indigo-600 dark:group-hover:text-indigo-400 transition-colors">
            Testing
          </h3>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Unit test your atoms and computed values. Widget test with scoped stores. Integration
            testing patterns.
          </p>
        </a>
        <a
          href="#/devtools"
          className="group block p-6 rounded-xl border border-gray-200 dark:border-gray-800 hover:border-indigo-300 dark:hover:border-indigo-700 hover:shadow-lg hover:shadow-indigo-500/5 transition-all"
        >
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-1 group-hover:text-indigo-600 dark:group-hover:text-indigo-400 transition-colors">
            DevTools
          </h3>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Inspect your reactive state graph, time-travel through state changes, and debug subscriptions
            in real time.
          </p>
        </a>
        <a
          href="#/examples"
          className="group block p-6 rounded-xl border border-gray-200 dark:border-gray-800 hover:border-indigo-300 dark:hover:border-indigo-700 hover:shadow-lg hover:shadow-indigo-500/5 transition-all"
        >
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-1 group-hover:text-indigo-600 dark:group-hover:text-indigo-400 transition-colors">
            Examples
          </h3>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Full sample applications — todo app, shopping cart, authentication flow, and more — built
            entirely with Reacton.
          </p>
        </a>
      </div>

      <PageNav next={{ title: 'Core Concepts', path: '/core-concepts' }} />
    </div>
  )
}
