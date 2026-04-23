import { h } from 'vue'
import type { Theme } from 'vitepress'
import DefaultTheme from 'vitepress/theme'

import HomeShowcase from './components/HomeShowcase.vue'
import StatsStrip from './components/StatsStrip.vue'
import EcosystemGrid from './components/EcosystemGrid.vue'
import HomeCTA from './components/HomeCTA.vue'

import './style.css'

export default {
  extends: DefaultTheme,
  Layout() {
    return h(DefaultTheme.Layout, null, {
      'home-features-after': () => [
        h(StatsStrip),
        h(HomeShowcase),
        h(EcosystemGrid),
        h(HomeCTA),
      ],
    })
  },
} satisfies Theme
