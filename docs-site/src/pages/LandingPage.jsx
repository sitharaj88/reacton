import { useState } from 'react'
import { Link } from 'react-router-dom'
import Header from '../components/Header'
import CodeBlock from '../components/CodeBlock'

const features = [
  {
    icon: '\u26A1',
    title: 'Fine-Grained Reactivity',
    description:
      'Atom-level subscriptions mean only the widgets that depend on changed state rebuild. No unnecessary work.',
  },
  {
    icon: '\u2728',
    title: 'Zero Boilerplate',
    description:
      'Just 5 concepts to start. No providers, no builders, no context juggling. Progressive API grows with you.',
  },
  {
    icon: '\uD83D\uDD37',
    title: 'Glitch-Free Updates',
    description:
      'Two-phase mark/propagate algorithm solves the diamond dependency problem. Every computed value updates exactly once.',
  },
  {
    icon: '\uD83C\uDF3F',
    title: 'State Branching',
    description:
      'Git-like branching for state. Preview changes, create drafts, merge or discard. Perfect for complex forms.',
  },
  {
    icon: '\u23F1',
    title: 'Time Travel',
    description:
      'Built-in undo/redo with full action log. Jump to any point in history. Debug state changes effortlessly.',
  },
  {
    icon: '\uD83D\uDE80',
    title: 'Full Ecosystem',
    description:
      'DevTools extension, CLI tool, custom lint rules, VS Code extension, testing utilities, and code generation.',
  },
]

const levels = [
  {
    level: 1,
    label: 'Beginner',
    subtitle: '5 concepts',
    gradient: 'from-emerald-400 to-cyan-400',
    concepts: ['atom()', 'context.watch()', 'context.read()', 'context.set()', 'ReactonScope'],
  },
  {
    level: 2,
    label: 'Intermediate',
    subtitle: '5 more concepts',
    gradient: 'from-indigo-400 to-purple-400',
    concepts: ['computed()', 'effect()', 'asyncAtom()', 'family()', 'selector()'],
  },
  {
    level: 3,
    label: 'Advanced',
    subtitle: 'Full power',
    gradient: 'from-orange-400 to-rose-400',
    concepts: ['store.branch()', 'enableHistory()', 'optimistic updates', 'IsolateStore', 'middleware'],
  },
]

const comparisonFeatures = [
  'Fine-grained reactivity',
  'Zero boilerplate',
  'State branching',
  'Time travel',
  'DevTools',
  'Lint rules',
  'Code generation',
  'Multi-isolate',
]

const comparisonData = {
  Reacton: [true, true, true, true, true, true, true, true],
  Riverpod: [true, false, false, false, true, true, true, false],
  BLoC: [false, false, false, true, true, false, false, false],
  GetX: [true, true, false, false, false, false, false, false],
  Signals: [true, true, false, false, false, false, false, false],
}

const ecosystem = [
  { name: 'reacton', description: 'Pure Dart reactive core' },
  { name: 'flutter_reacton', description: 'Flutter widgets & bindings' },
  { name: 'reacton_test', description: 'Testing utilities' },
  { name: 'reacton_lint', description: 'Custom lint rules' },
  { name: 'reacton_devtools', description: 'DevTools extension' },
  { name: 'reacton_cli', description: 'CLI scaffolding tool' },
  { name: 'reacton_generator', description: 'Code generation' },
]

const counterExample = `import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

// Declare atoms at top-level
final counterAtom = atom(0, name: 'counter');
final doubleAtom = computed<int>(
  (read) => read(counterAtom) * 2,
  name: 'double',
);

void main() {
  runApp(ReactonScope(
    store: ReactonStore(),
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch(counterAtom);
    final doubled = context.watch(doubleAtom);

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Count: \$count'),
              Text('Doubled: \$doubled'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.update(counterAtom, (n) => n + 1),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}`

export default function LandingPage() {
  const [copied, setCopied] = useState(false)

  const handleCopy = () => {
    navigator.clipboard.writeText('flutter pub add reacton flutter_reacton')
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className="min-h-screen bg-white dark:bg-gray-950 text-gray-900 dark:text-gray-100">
      {/* Header */}
      <Header />

      {/* Hero Section */}
      <section className="pt-32 pb-20 px-4 sm:px-6 lg:px-8 text-center max-w-5xl mx-auto">
        <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-gradient-to-r from-indigo-500/10 to-purple-500/10 border border-indigo-500/20 mb-8">
          <span className="text-sm font-medium bg-gradient-to-r from-indigo-400 to-purple-400 bg-clip-text text-transparent">
            v0.1.0 — Now Available
          </span>
        </div>

        <h1 className="text-5xl sm:text-6xl lg:text-7xl font-extrabold tracking-tight mb-6">
          <span className="block">Reactive State for</span>
          <span className="block bg-gradient-to-r from-indigo-500 to-purple-500 bg-clip-text text-transparent">
            Flutter
          </span>
        </h1>

        <p className="text-lg sm:text-xl text-gray-600 dark:text-gray-400 max-w-2xl mx-auto mb-10 leading-relaxed">
          Fine-grained atom-based reactivity with zero boilerplate. Progressive API from beginner to
          advanced. Full developer tooling ecosystem.
        </p>

        <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-10">
          <Link
            to="/getting-started"
            className="inline-flex items-center gap-2 px-8 py-3.5 rounded-lg bg-gradient-to-r from-indigo-500 to-purple-500 text-white font-semibold shadow-lg shadow-indigo-500/25 hover:shadow-xl hover:shadow-indigo-500/30 transition-all duration-300 hover:-translate-y-0.5"
          >
            Get Started
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M13 7l5 5m0 0l-5 5m5-5H6" />
            </svg>
          </Link>
          <a
            href="https://github.com/placeholder/reacton"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 px-8 py-3.5 rounded-lg border border-gray-300 dark:border-gray-700 text-gray-700 dark:text-gray-300 font-semibold hover:border-indigo-500/50 hover:text-indigo-500 transition-all duration-300"
          >
            <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
              <path
                fillRule="evenodd"
                d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"
                clipRule="evenodd"
              />
            </svg>
            GitHub
          </a>
        </div>

        <div className="inline-flex items-center gap-3 px-5 py-3 rounded-xl bg-gray-100 dark:bg-gray-900 border border-gray-200 dark:border-gray-800">
          <code className="text-sm sm:text-base font-mono text-gray-700 dark:text-gray-300">
            flutter pub add reacton flutter_reacton
          </code>
          <button
            onClick={handleCopy}
            className="p-1.5 rounded-md hover:bg-gray-200 dark:hover:bg-gray-800 transition-colors text-gray-500 hover:text-gray-700 dark:hover:text-gray-300"
            title="Copy to clipboard"
          >
            {copied ? (
              <svg className="w-4 h-4 text-emerald-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
              </svg>
            ) : (
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"
                />
              </svg>
            )}
          </button>
        </div>
      </section>

      {/* Features Grid */}
      <section className="py-20 px-4 sm:px-6 lg:px-8 max-w-6xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight mb-4">
            Everything You Need
          </h2>
          <p className="text-lg text-gray-600 dark:text-gray-400 max-w-2xl mx-auto">
            A complete state management solution designed for modern Flutter applications.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((feature) => (
            <div
              key={feature.title}
              className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-xl p-6 hover:border-indigo-500/50 transition-all duration-300 hover:shadow-lg hover:shadow-indigo-500/5"
            >
              <div className="text-3xl mb-4">{feature.icon}</div>
              <h3 className="text-lg font-semibold mb-2">{feature.title}</h3>
              <p className="text-gray-600 dark:text-gray-400 text-sm leading-relaxed">
                {feature.description}
              </p>
            </div>
          ))}
        </div>
      </section>

      {/* Progressive API Section */}
      <section className="py-20 px-4 sm:px-6 lg:px-8 bg-gray-50 dark:bg-gray-900/50">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl font-bold tracking-tight mb-4">
              Learn at Your Own Pace
            </h2>
            <p className="text-lg text-gray-600 dark:text-gray-400 max-w-2xl mx-auto">
              Three progressive API levels. Start simple, unlock power as you need it.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {levels.map((level) => (
              <div
                key={level.level}
                className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-xl p-6 hover:border-indigo-500/50 transition-all duration-300"
              >
                <div className="flex items-center gap-3 mb-5">
                  <span
                    className={`inline-flex items-center justify-center w-10 h-10 rounded-lg bg-gradient-to-br ${level.gradient} text-white font-bold text-lg`}
                  >
                    {level.level}
                  </span>
                  <div>
                    <div className="font-semibold">{level.label}</div>
                    <div className="text-xs text-gray-500 dark:text-gray-400">{level.subtitle}</div>
                  </div>
                </div>
                <ul className="space-y-2.5">
                  {level.concepts.map((concept) => (
                    <li key={concept} className="flex items-center gap-2.5 text-sm">
                      <span
                        className={`w-1.5 h-1.5 rounded-full bg-gradient-to-r ${level.gradient} shrink-0`}
                      />
                      <code className="font-mono text-gray-700 dark:text-gray-300">{concept}</code>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Code Example Section */}
      <section className="py-20 px-4 sm:px-6 lg:px-8 max-w-4xl mx-auto">
        <div className="text-center mb-12">
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight mb-4">
            Simple by Default, Powerful When Needed
          </h2>
          <p className="text-lg text-gray-600 dark:text-gray-400 max-w-2xl mx-auto">
            A complete counter with derived state in under 40 lines.
          </p>
        </div>

        <CodeBlock language="dart">{counterExample}</CodeBlock>
      </section>

      {/* Comparison Table */}
      <section className="py-20 px-4 sm:px-6 lg:px-8 bg-gray-50 dark:bg-gray-900/50">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl font-bold tracking-tight mb-4">
              How Reacton Compares
            </h2>
            <p className="text-lg text-gray-600 dark:text-gray-400 max-w-2xl mx-auto">
              See how Reacton stacks up against other Flutter state management solutions.
            </p>
          </div>

          <div className="overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-800">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-gray-100 dark:bg-gray-900">
                  <th className="text-left py-3.5 px-4 font-semibold text-gray-700 dark:text-gray-300">
                    Feature
                  </th>
                  {Object.keys(comparisonData).map((lib) => (
                    <th
                      key={lib}
                      className={`py-3.5 px-4 font-semibold text-center ${
                        lib === 'Reacton'
                          ? 'text-indigo-600 dark:text-indigo-400'
                          : 'text-gray-700 dark:text-gray-300'
                      }`}
                    >
                      {lib}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {comparisonFeatures.map((feature, i) => (
                  <tr
                    key={feature}
                    className="border-t border-gray-200 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-gray-900/80 transition-colors"
                  >
                    <td className="py-3 px-4 text-gray-700 dark:text-gray-300">{feature}</td>
                    {Object.entries(comparisonData).map(([lib, values]) => (
                      <td key={lib} className="py-3 px-4 text-center">
                        {values[i] ? (
                          <span className="text-emerald-500 font-bold">{'\u2713'}</span>
                        ) : (
                          <span className="text-gray-400 dark:text-gray-600">{'\u2717'}</span>
                        )}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      {/* Ecosystem Section */}
      <section className="py-20 px-4 sm:px-6 lg:px-8 max-w-6xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight mb-4">
            Complete Ecosystem
          </h2>
          <p className="text-lg text-gray-600 dark:text-gray-400 max-w-2xl mx-auto">
            Everything you need to build, test, debug, and ship.
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {ecosystem.map((pkg) => (
            <div
              key={pkg.name}
              className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-xl p-5 hover:border-indigo-500/50 transition-all duration-300"
            >
              <div className="font-mono text-sm font-semibold text-indigo-600 dark:text-indigo-400 mb-1.5">
                {pkg.name}
              </div>
              <div className="text-sm text-gray-600 dark:text-gray-400">{pkg.description}</div>
            </div>
          ))}
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 px-4 sm:px-6 lg:px-8 border-t border-gray-200 dark:border-gray-800">
        <div className="text-center">
          <p className="text-gray-600 dark:text-gray-400 mb-2">
            Built with {'\u2764'} for Flutter developers
          </p>
          <p className="text-sm text-gray-500 dark:text-gray-500">Released under MIT License</p>
        </div>
      </footer>
    </div>
  )
}
