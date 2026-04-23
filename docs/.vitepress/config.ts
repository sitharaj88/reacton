import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Reacton',
  description: 'Fine-grained reactive state management for Flutter — glitch-free updates, a progressive API, and a batteries-included ecosystem.',
  base: '/reacton/',
  lang: 'en-US',

  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: '/reacton/logo.svg' }],
    ['link', { rel: 'preconnect', href: 'https://rsms.me/' }],
    ['link', { rel: 'preconnect', href: 'https://fonts.googleapis.com' }],
    ['meta', { name: 'theme-color', content: '#6366f1' }],

    // Open Graph
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:url', content: 'https://sitharaj88.github.io/reacton/' }],
    ['meta', { property: 'og:title', content: 'Reacton — Reactive State Management for Flutter' }],
    ['meta', { property: 'og:description', content: 'Fine-grained reactivity with reactons, computed values, state branching, time-travel, and a full ecosystem of dev tools.' }],
    ['meta', { property: 'og:image', content: 'https://sitharaj88.github.io/reacton/logo.svg' }],

    // Twitter
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
    ['meta', { name: 'twitter:title', content: 'Reacton — Reactive State Management for Flutter' }],
    ['meta', { name: 'twitter:description', content: 'Glitch-free, fine-grained reactivity for Flutter with a progressive API and a full ecosystem of tooling.' }],
    ['meta', { name: 'twitter:image', content: 'https://sitharaj88.github.io/reacton/logo.svg' }],
  ],

  cleanUrls: true,
  lastUpdated: true,

  sitemap: {
    hostname: 'https://sitharaj88.github.io/reacton/',
  },

  markdown: {
    theme: { light: 'github-light', dark: 'github-dark-dimmed' },
    lineNumbers: true,
    image: {
      lazyLoading: true,
    },
  },

  themeConfig: {
    logo: { src: '/logo.svg', alt: 'Reacton' },
    siteTitle: 'Reacton',

    nav: [
      { text: 'Guide', link: '/guide/', activeMatch: '^/guide/' },
      { text: 'Flutter', link: '/flutter/', activeMatch: '^/flutter/' },
      { text: 'Async', link: '/async/', activeMatch: '^/async/' },
      { text: 'Advanced', link: '/advanced/', activeMatch: '^/advanced/' },
      { text: 'Cookbook', link: '/cookbook/', activeMatch: '^/cookbook/' },
      { text: 'API', link: '/api/', activeMatch: '^/api/' },
      {
        text: 'Ecosystem',
        items: [
          { text: 'CLI', link: '/tooling/cli' },
          { text: 'DevTools', link: '/tooling/devtools' },
          { text: 'VS Code Extension', link: '/tooling/vscode-extension' },
          { text: 'Lint Rules', link: '/tooling/lint-rules' },
          { text: 'Code Generation', link: '/tooling/code-generation' },
        ],
      },
      {
        text: 'Resources',
        items: [
          { text: 'Architecture', link: '/architecture/' },
          { text: 'Testing', link: '/testing/' },
          { text: 'Migration Guides', link: '/migration/' },
          { text: 'FAQ', link: '/resources/faq' },
          { text: 'Troubleshooting', link: '/guide/troubleshooting' },
          { text: 'Error Reference', link: '/guide/errors' },
          { text: 'Comparison', link: '/resources/comparison' },
          { text: 'Roadmap', link: '/resources/roadmap' },
          { text: 'Changelog', link: '/resources/changelog' },
          { text: 'Glossary', link: '/guide/glossary' },
        ],
      },
    ],

    sidebar: {
      '/guide/': [
        {
          text: 'Getting Started',
          items: [
            { text: 'What is Reacton?', link: '/guide/' },
            { text: 'Installation', link: '/guide/installation' },
            { text: 'Quick Start', link: '/guide/quick-start' },
          ],
        },
        {
          text: 'Fundamentals',
          items: [
            { text: 'Core Concepts', link: '/guide/core-concepts' },
            { text: 'Thinking in Reacton', link: '/guide/thinking-in-reacton' },
            { text: 'Common Pitfalls', link: '/guide/pitfalls' },
            { text: 'Glossary', link: '/guide/glossary' },
          ],
        },
        {
          text: 'Troubleshooting',
          items: [
            { text: 'Troubleshooting Guide', link: '/guide/troubleshooting' },
            { text: 'Error Reference', link: '/guide/errors' },
          ],
        },
      ],

      '/flutter/': [
        {
          text: 'Flutter Integration',
          items: [
            { text: 'Overview', link: '/flutter/' },
            { text: 'ReactonScope', link: '/flutter/reacton-scope' },
            { text: 'Context Extensions', link: '/flutter/context-extensions' },
            { text: 'Widgets', link: '/flutter/widgets' },
            { text: 'Form State', link: '/flutter/forms' },
            { text: 'Auto-Dispose', link: '/flutter/auto-dispose' },
          ],
        },
      ],

      '/async/': [
        {
          text: 'Async State',
          items: [
            { text: 'Overview', link: '/async/' },
            { text: 'Async Reactons', link: '/async/async-reacton' },
            { text: 'Query Reactons', link: '/async/query-reacton' },
            { text: 'Retry Policies', link: '/async/retry' },
            { text: 'Optimistic Updates', link: '/async/optimistic' },
            { text: 'Debounce & Throttle', link: '/async/debounce-throttle' },
          ],
        },
      ],

      '/advanced/': [
        {
          text: 'State Patterns',
          items: [
            { text: 'Overview', link: '/advanced/' },
            { text: 'State Machines', link: '/advanced/state-machines' },
            { text: 'Observable Collections', link: '/advanced/collections' },
            { text: 'Lenses', link: '/advanced/lenses' },
            { text: 'Interceptors', link: '/advanced/interceptors' },
          ],
        },
        {
          text: 'Infrastructure',
          items: [
            { text: 'Middleware', link: '/advanced/middleware' },
            { text: 'Persistence', link: '/advanced/persistence' },
            { text: 'Modules', link: '/advanced/modules' },
          ],
        },
        {
          text: 'Time & Space',
          items: [
            { text: 'History (Undo/Redo)', link: '/advanced/history' },
            { text: 'State Branching', link: '/advanced/branching' },
            { text: 'Snapshots & Diffs', link: '/advanced/snapshots' },
          ],
        },
        {
          text: 'Distributed',
          items: [
            { text: 'Multi-Isolate', link: '/advanced/isolates' },
            { text: 'Collaborative (CRDT)', link: '/advanced/collaborative' },
          ],
        },
        {
          text: 'Orchestration',
          items: [
            { text: 'Sagas', link: '/advanced/sagas' },
          ],
        },
      ],

      '/architecture/': [
        {
          text: 'Architecture',
          items: [
            { text: 'Overview', link: '/architecture/' },
            { text: 'Project Structure', link: '/architecture/project-structure' },
            { text: 'Common Patterns', link: '/architecture/patterns' },
            { text: 'Performance', link: '/architecture/performance' },
            { text: 'Debugging', link: '/architecture/debugging' },
            { text: 'Scaling to Enterprise', link: '/architecture/scaling' },
          ],
        },
      ],

      '/testing/': [
        {
          text: 'Testing',
          items: [
            { text: 'Overview', link: '/testing/' },
            { text: 'Unit Testing', link: '/testing/unit-testing' },
            { text: 'Widget Testing', link: '/testing/widget-testing' },
            { text: 'Assertions', link: '/testing/assertions' },
            { text: 'Effect Testing', link: '/testing/effect-testing' },
            { text: 'Integration Testing', link: '/testing/integration-testing' },
            { text: 'Best Practices', link: '/testing/best-practices' },
          ],
        },
      ],

      '/tooling/': [
        {
          text: 'Developer Tools',
          items: [
            { text: 'Overview', link: '/tooling/' },
            { text: 'CLI', link: '/tooling/cli' },
            { text: 'Code Generation', link: '/tooling/code-generation' },
            { text: 'Lint Rules', link: '/tooling/lint-rules' },
            { text: 'DevTools Extension', link: '/tooling/devtools' },
            { text: 'VS Code Extension', link: '/tooling/vscode-extension' },
          ],
        },
      ],

      '/api/': [
        {
          text: 'API Reference',
          items: [
            { text: 'Index', link: '/api/' },
            { text: 'reacton (core)', link: '/api/reacton' },
            { text: 'flutter_reacton', link: '/api/flutter-reacton' },
            { text: 'reacton_test', link: '/api/reacton-test' },
            { text: 'reacton_cli', link: '/api/reacton-cli' },
            { text: 'reacton_devtools', link: '/api/reacton-devtools' },
          ],
        },
      ],

      '/cookbook/': [
        {
          text: 'Beginner',
          items: [
            { text: 'Overview', link: '/cookbook/' },
            { text: 'Counter App', link: '/cookbook/counter' },
            { text: 'Todo App', link: '/cookbook/todo-app' },
          ],
        },
        {
          text: 'Intermediate',
          items: [
            { text: 'Authentication', link: '/cookbook/authentication' },
            { text: 'Form Validation', link: '/cookbook/form-validation' },
            { text: 'Search with Debounce', link: '/cookbook/search-with-debounce' },
            { text: 'Shopping Cart', link: '/cookbook/shopping-cart' },
          ],
        },
        {
          text: 'Advanced',
          items: [
            { text: 'Pagination', link: '/cookbook/pagination' },
            { text: 'Offline-First', link: '/cookbook/offline-first' },
            { text: 'Multi-Step Wizard', link: '/cookbook/multi-step-wizard' },
            { text: 'Real-Time Chat', link: '/cookbook/real-time-chat' },
            { text: 'Analytics Dashboard', link: '/cookbook/dashboard' },
          ],
        },
      ],

      '/migration/': [
        {
          text: 'Migration Guides',
          items: [
            { text: 'Overview', link: '/migration/' },
            { text: 'From Riverpod', link: '/migration/from-riverpod' },
            { text: 'From BLoC', link: '/migration/from-bloc' },
            { text: 'From Provider', link: '/migration/from-provider' },
            { text: 'From GetX', link: '/migration/from-getx' },
          ],
        },
      ],

      '/resources/': [
        {
          text: 'Resources',
          items: [
            { text: 'FAQ', link: '/resources/faq' },
            { text: 'Detailed Comparison', link: '/resources/comparison' },
            { text: 'Roadmap', link: '/resources/roadmap' },
            { text: 'Changelog', link: '/resources/changelog' },
          ],
        },
        {
          text: 'Cross-reference',
          items: [
            { text: 'Troubleshooting', link: '/guide/troubleshooting' },
            { text: 'Error Reference', link: '/guide/errors' },
            { text: 'Common Pitfalls', link: '/guide/pitfalls' },
            { text: 'Glossary', link: '/guide/glossary' },
          ],
        },
      ],
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/sitharaj88/reacton' },
    ],

    search: {
      provider: 'local',
      options: {
        detailedView: true,
      },
    },

    editLink: {
      pattern: 'https://github.com/sitharaj88/reacton/edit/main/docs/:path',
      text: 'Edit this page on GitHub',
    },

    lastUpdated: {
      text: 'Last updated',
      formatOptions: { dateStyle: 'medium' },
    },

    outline: {
      level: [2, 3],
      label: 'On this page',
    },

    docFooter: {
      prev: 'Previous',
      next: 'Next',
    },

    returnToTopLabel: 'Back to top',
    sidebarMenuLabel: 'Menu',
    darkModeSwitchLabel: 'Appearance',
    lightModeSwitchTitle: 'Switch to light theme',
    darkModeSwitchTitle: 'Switch to dark theme',

    footer: {
      message:
        'Released under the <a href="https://github.com/sitharaj88/reacton/blob/main/LICENSE">MIT License</a>.',
      copyright: `Copyright © 2025-${new Date().getFullYear()} Reacton contributors`,
    },
  },
})
