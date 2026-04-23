<script setup>
import { withBase } from 'vitepress'
</script>

<template>
  <section class="cta">
    <div class="cta__inner">
      <h2 class="cta__title">Start building in 60 seconds.</h2>
      <p class="cta__lede">
        One import. Zero boilerplate. A progressive API that scales from counters
        to collaborative, offline-first apps.
      </p>

      <div class="cta__command">
        <span class="cta__prompt">$</span>
        <code>flutter pub add flutter_reacton</code>
        <button
          class="cta__copy"
          type="button"
          @click="(e) => {
            navigator.clipboard?.writeText('flutter pub add flutter_reacton');
            e.currentTarget.classList.add('is-copied');
            setTimeout(() => e.currentTarget.classList.remove('is-copied'), 1200);
          }"
          aria-label="Copy install command"
        >Copy</button>
      </div>

      <div class="cta__actions">
        <a class="cta__btn cta__btn--primary" :href="withBase('/guide/quick-start')">Read the quick start</a>
        <a class="cta__btn cta__btn--ghost" :href="withBase('/cookbook/')">Explore the cookbook</a>
        <a class="cta__btn cta__btn--ghost" href="https://github.com/sitharaj88/reacton" target="_blank" rel="noopener">GitHub →</a>
      </div>
    </div>
  </section>
</template>

<style scoped>
.cta {
  max-width: 1120px;
  margin: 96px auto 64px;
  padding: 0 24px;
}

.cta__inner {
  position: relative;
  padding: 56px 32px;
  border-radius: 24px;
  text-align: center;
  background:
    radial-gradient(circle at 20% 20%, rgba(99, 102, 241, 0.25) 0%, transparent 45%),
    radial-gradient(circle at 80% 70%, rgba(168, 85, 247, 0.25) 0%, transparent 50%),
    linear-gradient(135deg, #0f172a 0%, #1e1b4b 100%);
  color: #fff;
  overflow: hidden;
  box-shadow: 0 30px 80px -30px rgba(99, 102, 241, 0.6);
}

.cta__inner::before {
  content: '';
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(rgba(255, 255, 255, 0.04) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255, 255, 255, 0.04) 1px, transparent 1px);
  background-size: 40px 40px;
  mask-image: radial-gradient(ellipse at center, black 40%, transparent 80%);
  -webkit-mask-image: radial-gradient(ellipse at center, black 40%, transparent 80%);
  pointer-events: none;
}

.cta__title {
  position: relative;
  font-size: 40px;
  font-weight: 800;
  letter-spacing: -0.03em;
  line-height: 1.1;
  margin: 0 0 16px;
  color: #fff;
  border: none !important;
  padding: 0 !important;
  background: linear-gradient(110deg, #ffffff 0%, #c7d2fe 80%);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
}

.cta__lede {
  position: relative;
  max-width: 620px;
  margin: 0 auto 32px;
  color: #cbd5e1;
  font-size: 17px;
  line-height: 1.55;
}

.cta__command {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 14px;
  padding: 14px 16px 14px 20px;
  border-radius: 12px;
  background: rgba(15, 23, 42, 0.7);
  border: 1px solid rgba(255, 255, 255, 0.1);
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-size: 14px;
  margin-bottom: 28px;
  backdrop-filter: blur(10px);
}

.cta__prompt {
  color: #22d3ee;
  font-weight: 700;
}

.cta__command code {
  color: #e2e8f0;
  background: transparent;
  font-family: inherit;
  font-size: inherit;
}

.cta__copy {
  font-family: inherit;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.02em;
  padding: 4px 10px;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.08);
  color: #e2e8f0;
  border: 1px solid rgba(255, 255, 255, 0.1);
  cursor: pointer;
  transition: all 0.2s ease;
}

.cta__copy:hover {
  background: rgba(255, 255, 255, 0.14);
  color: #fff;
}

.cta__copy.is-copied {
  background: #10b981;
  border-color: #10b981;
  color: #fff;
}

.cta__copy.is-copied::before {
  content: '✓ ';
}

.cta__actions {
  position: relative;
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  justify-content: center;
}

.cta__btn {
  display: inline-block;
  padding: 11px 20px;
  border-radius: 10px;
  font-size: 14.5px;
  font-weight: 600;
  text-decoration: none !important;
  transition: transform 0.2s ease, box-shadow 0.2s ease, background 0.2s ease;
  background-image: none !important;
  background-size: auto !important;
}

.cta__btn--primary {
  background: linear-gradient(120deg, #6366f1, #a855f7);
  color: #fff !important;
  box-shadow: 0 8px 24px -8px rgba(168, 85, 247, 0.6);
}

.cta__btn--primary:hover {
  transform: translateY(-1px);
  box-shadow: 0 14px 30px -10px rgba(168, 85, 247, 0.8);
}

.cta__btn--ghost {
  background: rgba(255, 255, 255, 0.08);
  color: #e2e8f0 !important;
  border: 1px solid rgba(255, 255, 255, 0.12);
}

.cta__btn--ghost:hover {
  background: rgba(255, 255, 255, 0.14);
  color: #fff !important;
}

@media (max-width: 640px) {
  .cta__inner { padding: 40px 20px; }
  .cta__title { font-size: 28px; }
  .cta__command { font-size: 13px; padding: 12px; }
}
</style>
