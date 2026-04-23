<script setup>
const stats = [
  { label: 'Packages',          value: '8',   hint: 'monorepo workspace' },
  { label: 'Public APIs',       value: '120+', hint: 'across core + flutter' },
  { label: 'Test cases',        value: '18k+', hint: 'lines of Dart test' },
  { label: 'Cookbook recipes',  value: '12',   hint: 'end-to-end apps' },
  { label: 'Flutter DevTools',  value: '✓',    hint: 'dedicated extension' },
  { label: 'Dart',              value: '≥ 3.0',hint: 'sound null-safety' },
]
</script>

<template>
  <section class="stats">
    <div class="stats__inner">
      <div class="stats__grid">
        <div v-for="stat in stats" :key="stat.label" class="stats__item">
          <div class="stats__value">{{ stat.value }}</div>
          <div class="stats__label">{{ stat.label }}</div>
          <div class="stats__hint">{{ stat.hint }}</div>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.stats {
  max-width: 1120px;
  margin: 72px auto 0;
  padding: 0 24px;
}

.stats__inner {
  position: relative;
  padding: 32px 24px;
  border-radius: 20px;
  background:
    linear-gradient(120deg, rgba(99, 102, 241, 0.08) 0%, rgba(168, 85, 247, 0.08) 100%),
    var(--vp-c-bg-soft);
  border: 1px solid var(--vp-c-divider);
  overflow: hidden;
}

.stats__inner::before {
  content: '';
  position: absolute;
  top: -60%;
  right: -20%;
  width: 400px;
  height: 400px;
  background: radial-gradient(circle, rgba(139, 92, 246, 0.18) 0%, transparent 60%);
  pointer-events: none;
}

.stats__inner::after {
  content: '';
  position: absolute;
  bottom: -50%;
  left: -15%;
  width: 360px;
  height: 360px;
  background: radial-gradient(circle, rgba(34, 211, 238, 0.15) 0%, transparent 60%);
  pointer-events: none;
}

.stats__grid {
  position: relative;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 24px;
  text-align: center;
}

.stats__item {
  padding: 8px 4px;
}

.stats__value {
  font-size: 34px;
  font-weight: 800;
  letter-spacing: -0.02em;
  line-height: 1;
  background: linear-gradient(120deg, #6366f1 0%, #a855f7 80%);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
  margin-bottom: 6px;
}

.stats__label {
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--vp-c-text-1);
}

.stats__hint {
  font-size: 12px;
  color: var(--vp-c-text-3);
  margin-top: 4px;
  line-height: 1.4;
}

@media (max-width: 640px) {
  .stats__value { font-size: 28px; }
}
</style>
