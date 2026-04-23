<script setup>
import { ref, computed } from 'vue'

const tabs = [
  {
    id: 'counter',
    label: 'Counter',
    hint: 'Level 1 — 4 lines of state',
    code: `import 'package:flutter_reacton/flutter_reacton.dart';

final counter = reacton(0, name: 'counter');
final doubled = computed((read) => read(counter) * 2, name: 'doubled');

class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.watch(counter);
    final x2    = context.watch(doubled);

    return Column(children: [
      Text('Count: \$count'),
      Text('Doubled: \$x2'),
      ElevatedButton(
        onPressed: () => context.update(counter, (c) => c + 1),
        child: const Text('Increment'),
      ),
    ]);
  }
}`,
  },
  {
    id: 'async',
    label: 'Async',
    hint: 'Level 2 — query with caching & retry',
    code: `final userQuery = reactonQuery<User>(
  queryFn: (ctx) => api.fetchUser(),
  config: const QueryConfig(
    staleTime: Duration(minutes: 5),
    refetchOnResume: true,
  ),
  name: 'userQuery',
);

class ProfileView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch(userQuery);

    return user.when(
      loading: () => const CircularProgressIndicator(),
      error:   (e, _) => Text('Oops: \$e'),
      data:    (u) => Text('Hi, \${u.name}!'),
    );
  }
}`,
  },
  {
    id: 'state-machine',
    label: 'State Machine',
    hint: 'Level 3 — typed auth flow',
    code: `sealed class AuthState { const AuthState(); }
class Anonymous   extends AuthState { const Anonymous(); }
class Authenticating extends AuthState { const Authenticating(); }
class Authenticated extends AuthState {
  final User user;
  const Authenticated(this.user);
}

enum AuthEvent { signIn, signOut, fail }

final auth = stateMachine<AuthState, AuthEvent>(
  initial: const Anonymous(),
  transitions: {
    const Anonymous(): {
      AuthEvent.signIn: (ctx) async {
        final user = await api.signIn();
        return Authenticated(user);
      },
    },
    Authenticated: {
      AuthEvent.signOut: (_) => const Anonymous(),
    },
  },
  name: 'auth',
);`,
  },
  {
    id: 'branch',
    label: 'Branching',
    hint: 'Git-like state for previews',
    code: `// Preview an edit before committing
final draft = context.read<ReactonStore>().reactonStore
    .createBranch('draft');

draft.set(profileReacton, profileReacton.copyWith(
  bio: 'New bio preview',
));

// User confirms — merge into main
store.mergeBranch(draft);

// User cancels — drop everything
draft.discard();`,
  },
  {
    id: 'test',
    label: 'Testing',
    hint: 'First-class, Flutter-free',
    code: `test('doubled reflects counter', () {
  final store = TestReactonStore(overrides: [
    ReactonTestOverride(counter, 5),
  ]);

  expectReacton(store, counter).toHaveValue(5);
  expectReacton(store, doubled).toHaveValue(10);

  store.set(counter, 7);
  expectReacton(store, doubled).toHaveValue(14);
});`,
  },
]

const active = ref(tabs[0].id)
const current = computed(() => tabs.find((t) => t.id === active.value))
</script>

<template>
  <section class="home-showcase">
    <header class="home-showcase__header">
      <span class="home-showcase__eyebrow">Progressive API</span>
      <h2 class="home-showcase__title">
        From a single reacton to distributed state — same mental model.
      </h2>
      <p class="home-showcase__lede">
        Reacton grows with your app. Start with the Level 1 primitives, reach for
        advanced features only when you need them.
      </p>
    </header>

    <div class="home-showcase__tabs" role="tablist">
      <button
        v-for="tab in tabs"
        :key="tab.id"
        role="tab"
        :aria-selected="active === tab.id"
        class="home-showcase__tab"
        :class="{ 'is-active': active === tab.id }"
        @click="active = tab.id"
      >
        {{ tab.label }}
      </button>
    </div>

    <p class="home-showcase__hint">{{ current.hint }}</p>

    <div class="home-showcase__frame">
      <div class="home-showcase__chrome">
        <span class="dot dot--red" />
        <span class="dot dot--amber" />
        <span class="dot dot--green" />
        <span class="home-showcase__filename">main.dart</span>
      </div>
      <pre class="home-showcase__code"><code>{{ current.code }}</code></pre>
    </div>
  </section>
</template>

<style scoped>
.home-showcase {
  max-width: 1120px;
  margin: 96px auto 0;
  padding: 0 24px;
}

.home-showcase__header {
  text-align: center;
  margin-bottom: 40px;
}

.home-showcase__eyebrow {
  display: inline-block;
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  background: linear-gradient(120deg, #6366f1, #a855f7);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
  margin-bottom: 12px;
}

.home-showcase__title {
  font-size: 36px;
  font-weight: 800;
  letter-spacing: -0.025em;
  line-height: 1.15;
  max-width: 720px;
  margin: 0 auto 12px;
  color: var(--vp-c-text-1);
  border: none !important;
  padding: 0 !important;
}

.home-showcase__lede {
  max-width: 620px;
  margin: 0 auto;
  color: var(--vp-c-text-2);
  font-size: 17px;
  line-height: 1.55;
}

.home-showcase__tabs {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 8px;
  margin: 0 0 8px;
}

.home-showcase__tab {
  font-family: inherit;
  font-size: 14px;
  font-weight: 600;
  padding: 10px 16px;
  border-radius: 999px;
  border: 1px solid var(--vp-c-divider);
  background: var(--vp-c-bg-soft);
  color: var(--vp-c-text-2);
  cursor: pointer;
  transition: all 0.2s ease;
}

.home-showcase__tab:hover {
  color: var(--vp-c-text-1);
  border-color: var(--vp-c-brand-2);
}

.home-showcase__tab.is-active {
  background: linear-gradient(120deg, #6366f1, #a855f7);
  color: #fff;
  border-color: transparent;
  box-shadow: 0 8px 20px -8px rgba(139, 92, 246, 0.5);
}

.home-showcase__hint {
  text-align: center;
  font-size: 13.5px;
  color: var(--vp-c-text-3);
  margin: 12px 0 20px;
  font-weight: 500;
}

.home-showcase__frame {
  position: relative;
  border-radius: 16px;
  overflow: hidden;
  background: #0d1117;
  border: 1px solid rgba(255, 255, 255, 0.06);
  box-shadow:
    0 30px 80px -30px rgba(99, 102, 241, 0.4),
    0 20px 60px -20px rgba(168, 85, 247, 0.25);
}

.home-showcase__frame::before {
  content: '';
  position: absolute;
  inset: -1px;
  background: linear-gradient(120deg, #6366f1, #8b5cf6, #22d3ee);
  border-radius: 17px;
  z-index: -1;
  opacity: 0.5;
  filter: blur(14px);
}

.home-showcase__chrome {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 16px;
  background: #161b22;
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
}

.home-showcase__chrome .dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  display: inline-block;
}

.home-showcase__chrome .dot--red { background: #ff5f57; }
.home-showcase__chrome .dot--amber { background: #febc2e; }
.home-showcase__chrome .dot--green { background: #28c840; }

.home-showcase__filename {
  margin-left: 12px;
  color: #8b949e;
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 12px;
  font-weight: 500;
}

.home-showcase__code {
  margin: 0;
  padding: 24px 28px;
  overflow: auto;
  color: #c9d1d9;
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 13.5px;
  line-height: 1.65;
  max-height: 480px;
}

.home-showcase__code code {
  color: inherit;
  background: transparent;
  font-family: inherit;
  font-size: inherit;
}

@media (max-width: 768px) {
  .home-showcase {
    margin-top: 64px;
  }
  .home-showcase__title {
    font-size: 26px;
  }
  .home-showcase__code {
    font-size: 12.5px;
    padding: 18px;
  }
}
</style>
