---
layout: home

title: Reacton
titleTemplate: Fine-grained reactive state management for Flutter

hero:
  name: Reacton
  text: Reactive state, done right.
  tagline: Fine-grained, glitch-free state management for Flutter — with a progressive API that scales from counters to collaborative, offline-first apps.
  image:
    src: /logo.svg
    alt: Reacton
  actions:
    - theme: brand
      text: Get started →
      link: /guide/quick-start
    - theme: alt
      text: Why Reacton?
      link: /guide/
    - theme: alt
      text: ★ GitHub
      link: https://github.com/sitharaj88/reacton

features:
  - icon: ⚡
    title: Fine-grained reactivity
    details: Reacton-level subscriptions mean only the widgets depending on changed state rebuild. No provider pyramids, no wasted frames.
  - icon: ✨
    title: Zero boilerplate
    details: Five concepts to start — reacton, computed, watch, set, scope. No builders, no controllers, no context juggling.
  - icon: 💎
    title: Glitch-free updates
    details: A two-phase mark/propagate algorithm solves the diamond dependency problem. Every computed value updates exactly once, never mid-transition.
  - icon: 🔀
    title: State branching
    details: Git-like branches for state. Preview changes, draft edits, merge or discard. Perfect for speculative UI and undo-heavy workflows.
  - icon: ⏱️
    title: Time travel
    details: Built-in undo/redo with a full action log. Jump to any point in history. Debug state changes like you debug code.
  - icon: 🧰
    title: Full ecosystem
    details: CLI, DevTools extension, lint rules, VS Code extension, testing utilities, code generation — all first-party, all documented.
  - icon: 🧪
    title: First-class testing
    details: A dedicated reacton_test package — TestReactonStore, overrides, effect trackers, fluent assertions. No Flutter required for most tests.
  - icon: 🌐
    title: Built for the real world
    details: Async with stale-while-revalidate, state machines, persistence, middleware, multi-isolate, CRDT collaboration — all opt-in, all tested.
  - icon: 🦋
    title: Pure Dart core
    details: The reactive engine has zero Flutter dependency. Use it in CLI apps, servers, tests — or ship it to web, desktop, embedded.
---
