---
layout: home

hero:
  name: Reacton
  text: Reactive State Management for Flutter
  tagline: Fine-grained reactivity with a progressive API. From counter apps to enterprise systems.
  image:
    src: /logo.svg
    alt: Reacton
  actions:
    - theme: brand
      text: Get Started
      link: /guide/quick-start
    - theme: alt
      text: Why Reacton?
      link: /guide/

features:
  - icon: ⚡
    title: Fine-Grained Reactivity
    details: Reacton-level subscriptions mean only widgets that depend on changed state rebuild. Zero unnecessary work.
  - icon: ✨
    title: Zero Boilerplate
    details: Just 5 concepts to start — reacton, computed, watch, set, scope. No providers, no builders, no context juggling.
  - icon: 💎
    title: Glitch-Free Updates
    details: Two-phase mark/propagate algorithm solves the diamond dependency problem. Every computed value updates exactly once.
  - icon: 🔀
    title: State Branching
    details: Git-like branching for state. Preview changes, create drafts, merge or discard. Perfect for speculative UI.
  - icon: ⏱️
    title: Time Travel
    details: Built-in undo/redo with full action log. Jump to any point in history. Debug state changes effortlessly.
  - icon: 📦
    title: Full Ecosystem
    details: DevTools, CLI, lint rules, VS Code extension, testing utilities, and code generation — all included.
---

<div style="max-width: 688px; margin: 0 auto; padding: 48px 24px;">

## The simplest reactive state in Flutter

```dart
import 'package:flutter_reacton/flutter_reacton.dart';

// 1. Declare state
final counter = reacton(0, name: 'counter');
final doubled = computed((read) => read(counter) * 2, name: 'doubled');

// 2. Wrap your app
void main() => runApp(ReactonScope(child: MyApp()));

// 3. Use in widgets
class CounterPage extends StatelessWidget {
  Widget build(BuildContext context) {
    final count = context.watch(counter);        // rebuilds on change
    final double = context.watch(doubled);       // auto-derived

    return Column(children: [
      Text('Count: $count'),
      Text('Doubled: $double'),
      ElevatedButton(
        onPressed: () => context.update(counter, (c) => c + 1),
        child: Text('Increment'),
      ),
    ]);
  }
}
```

## How does Reacton compare?

| Feature | Reacton | Riverpod | Bloc | Provider |
|---------|:-------:|:--------:|:----:|:--------:|
| Fine-grained reactivity | ✅ | ✅ | ❌ | ❌ |
| Zero boilerplate | ✅ | ❌ | ❌ | ✅ |
| Computed / derived state | ✅ | ✅ | ❌ | ❌ |
| State branching | ✅ | ❌ | ❌ | ❌ |
| Time travel (undo/redo) | ✅ | ❌ | ✅ | ❌ |
| State machines | ✅ | ❌ | ✅ | ❌ |
| Observable collections | ✅ | ❌ | ❌ | ❌ |
| Query caching (SWR) | ✅ | ✅ | ❌ | ❌ |
| Form state management | ✅ | ❌ | ❌ | ❌ |
| DevTools extension | ✅ | ✅ | ✅ | ❌ |
| CLI tooling | ✅ | ✅ | ✅ | ❌ |
| Custom lint rules | ✅ | ✅ | ✅ | ❌ |
| VS Code extension | ✅ | ❌ | ✅ | ❌ |
| Multi-isolate support | ✅ | ❌ | ❌ | ❌ |

## Progressive API — grow with your needs

**Level 1** — `reacton()`, `context.watch()`, `context.set()` — covers 80% of apps

**Level 2** — Add `computed()`, `createEffect()`, `selector()` — for derived state and side effects

**Level 3** — State machines, branching, persistence, middleware, isolates — enterprise-grade power

</div>
