<script setup>
import { withBase } from 'vitepress'

const packages = [
  {
    name: 'reacton',
    kind: 'Core',
    accent: 'indigo',
    blurb: 'Reactive graph engine, primitives, store, effects, async, middleware, persistence, branching, history, CRDT and isolates. Pure Dart.',
    href: '/api/reacton',
  },
  {
    name: 'flutter_reacton',
    kind: 'Flutter',
    accent: 'violet',
    blurb: 'Flutter bindings — ReactonScope, context extensions, builder widgets, form state, auto-dispose. Re-exports the core package.',
    href: '/api/flutter-reacton',
  },
  {
    name: 'reacton_test',
    kind: 'Testing',
    accent: 'emerald',
    blurb: 'TestReactonStore, overrides, effect trackers, fluent assertions and widget pump helpers. Pure Dart, no Flutter required.',
    href: '/api/reacton-test',
  },
  {
    name: 'reacton_cli',
    kind: 'Tooling',
    accent: 'amber',
    blurb: '`reacton init`, `create`, `graph`, `analyze`, `doctor` — scaffold projects, inspect the dependency graph, and diagnose setups.',
    href: '/tooling/cli',
  },
  {
    name: 'reacton_devtools',
    kind: 'DevTools',
    accent: 'cyan',
    blurb: 'Flutter DevTools extension — live graph, inspector, timeline, performance view and time-travel debugging.',
    href: '/tooling/devtools',
  },
  {
    name: 'reacton_generator',
    kind: 'Codegen',
    accent: 'rose',
    blurb: 'build_runner builders for `@ReactonSerializable`, dependency-graph analysis and dead-reacton detection. Optional.',
    href: '/tooling/code-generation',
  },
  {
    name: 'reacton_lint',
    kind: 'Lint',
    accent: 'violet',
    blurb: 'Three custom_lint rules: avoid_reacton_in_build, avoid_read_in_build, prefer_computed. Catches classic mistakes at compile time.',
    href: '/tooling/lint-rules',
  },
  {
    name: 'reacton-vscode',
    kind: 'IDE',
    accent: 'indigo',
    blurb: 'VS Code extension — code lens, hover, diagnostics, inline graph preview and snippets for every Reacton primitive.',
    href: '/tooling/vscode-extension',
  },
]
</script>

<template>
  <section class="ecosystem">
    <header class="ecosystem__header">
      <span class="ecosystem__eyebrow">Ecosystem</span>
      <h2 class="ecosystem__title">Eight packages, one mental model.</h2>
      <p class="ecosystem__lede">
        Reacton ships as a batteries-included monorepo. Pick what you need; nothing
        is mandatory beyond the core.
      </p>
    </header>

    <div class="ecosystem__grid">
      <a
        v-for="pkg in packages"
        :key="pkg.name"
        :href="withBase(pkg.href)"
        class="ecosystem__card"
        :data-accent="pkg.accent"
      >
        <div class="ecosystem__chip">{{ pkg.kind }}</div>
        <h3 class="ecosystem__name">{{ pkg.name }}</h3>
        <p class="ecosystem__blurb">{{ pkg.blurb }}</p>
        <span class="ecosystem__cta">Read the docs →</span>
      </a>
    </div>
  </section>
</template>

<style scoped>
.ecosystem {
  max-width: 1120px;
  margin: 96px auto 0;
  padding: 0 24px;
}

.ecosystem__header {
  text-align: center;
  margin-bottom: 48px;
}

.ecosystem__eyebrow {
  display: inline-block;
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  background: linear-gradient(120deg, #6366f1, #22d3ee);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
  margin-bottom: 12px;
}

.ecosystem__title {
  font-size: 36px;
  font-weight: 800;
  letter-spacing: -0.025em;
  line-height: 1.15;
  margin: 0 0 12px;
  color: var(--vp-c-text-1);
  border: none !important;
  padding: 0 !important;
}

.ecosystem__lede {
  max-width: 620px;
  margin: 0 auto;
  color: var(--vp-c-text-2);
  font-size: 17px;
  line-height: 1.55;
}

.ecosystem__grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 18px;
}

.ecosystem__card {
  position: relative;
  display: block;
  padding: 22px 22px 18px;
  border-radius: 14px;
  background: var(--vp-c-bg-soft);
  border: 1px solid var(--vp-c-divider);
  text-decoration: none !important;
  color: var(--vp-c-text-1);
  transition: transform 0.22s ease, box-shadow 0.22s ease, border-color 0.22s ease;
  overflow: hidden;
  background-image: none !important;
  background-size: auto !important;
}

.ecosystem__card::after {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: 14px;
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.3s ease;
  background: radial-gradient(
    circle at 50% 0%,
    rgba(139, 92, 246, 0.12) 0%,
    transparent 60%
  );
}

.ecosystem__card:hover {
  transform: translateY(-3px);
  border-color: transparent;
  box-shadow:
    0 16px 40px -20px rgba(99, 102, 241, 0.45),
    0 0 0 1px rgba(139, 92, 246, 0.22);
}

.ecosystem__card:hover::after {
  opacity: 1;
}

.ecosystem__chip {
  display: inline-block;
  padding: 3px 10px;
  border-radius: 999px;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  margin-bottom: 12px;
}

.ecosystem__card[data-accent='indigo']  .ecosystem__chip { background: rgba(99, 102, 241, 0.14); color: #6366f1; }
.ecosystem__card[data-accent='violet']  .ecosystem__chip { background: rgba(139, 92, 246, 0.14); color: #8b5cf6; }
.ecosystem__card[data-accent='emerald'] .ecosystem__chip { background: rgba(16, 185, 129, 0.14); color: #10b981; }
.ecosystem__card[data-accent='amber']   .ecosystem__chip { background: rgba(245, 158, 11, 0.16); color: #d97706; }
.ecosystem__card[data-accent='cyan']    .ecosystem__chip { background: rgba(34, 211, 238, 0.16); color: #0891b2; }
.ecosystem__card[data-accent='rose']    .ecosystem__chip { background: rgba(244, 63, 94, 0.14); color: #e11d48; }

.ecosystem__name {
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 18px;
  font-weight: 700;
  letter-spacing: -0.01em;
  margin: 0 0 8px;
  color: var(--vp-c-text-1);
}

.ecosystem__blurb {
  color: var(--vp-c-text-2);
  line-height: 1.55;
  font-size: 14px;
  margin: 0 0 14px;
}

.ecosystem__cta {
  display: inline-block;
  font-size: 13.5px;
  font-weight: 600;
  color: var(--vp-c-brand-1);
  transition: transform 0.2s ease;
}

.ecosystem__card:hover .ecosystem__cta {
  transform: translateX(3px);
}

@media (max-width: 768px) {
  .ecosystem {
    margin-top: 64px;
  }
  .ecosystem__title {
    font-size: 26px;
  }
}
</style>
