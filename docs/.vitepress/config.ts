import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Reacton',
  description: 'Fine-grained reactive state management for Flutter',
  base: '/reacton/',

  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: '/reacton/logo.svg' }],
    ['meta', { property: 'og:title', content: 'Reacton — Reactive State Management for Flutter' }],
    ['meta', { property: 'og:description', content: 'Fine-grained reactivity with reactons, computed values, state branching, time-travel, and more.' }],
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
  ],

  cleanUrls: true,

  markdown: {
    theme: { light: 'github-light', dark: 'one-dark-pro' },
    lineNumbers: true,
  },

  themeConfig: {
    logo: '/logo.svg',

    nav: [
      { text: 'Guide', link: '/guide/' },
      { text: 'Flutter', link: '/flutter/' },
      { text: 'API', link: '/api/' },
      { text: 'Cookbook', link: '/cookbook/' },
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
    ],

    sidebar: {
      '/guide/': [
        {
          text: 'Introduction',
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
          ],
        },
      ],

      '/advanced/': [
        {
          text: 'Advanced Features',
          items: [
            { text: 'Overview', link: '/advanced/' },
            { text: 'Middleware', link: '/advanced/middleware' },
            { text: 'Persistence', link: '/advanced/persistence' },
            { text: 'History (Undo/Redo)', link: '/advanced/history' },
            { text: 'State Branching', link: '/advanced/branching' },
            { text: 'State Machines', link: '/advanced/state-machines' },
            { text: 'Modules', link: '/advanced/modules' },
            { text: 'Observable Collections', link: '/advanced/collections' },
            { text: 'Multi-Isolate', link: '/advanced/isolates' },
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
            { text: 'reacton (Core)', link: '/api/reacton' },
            { text: 'flutter_reacton', link: '/api/flutter-reacton' },
            { text: 'reacton_test', link: '/api/reacton-test' },
          ],
        },
      ],

      '/cookbook/': [
        {
          text: 'Recipes',
          items: [
            { text: 'Overview', link: '/cookbook/' },
            { text: 'Counter App', link: '/cookbook/counter' },
            { text: 'Todo App', link: '/cookbook/todo-app' },
            { text: 'Authentication', link: '/cookbook/authentication' },
            { text: 'Form Validation', link: '/cookbook/form-validation' },
            { text: 'Pagination', link: '/cookbook/pagination' },
            { text: 'Offline-First', link: '/cookbook/offline-first' },
          ],
        },
      ],

      '/migration/': [
        {
          text: 'Migration Guides',
          items: [
            { text: 'Overview', link: '/migration/' },
            { text: 'From Riverpod', link: '/migration/from-riverpod' },
            { text: 'From Bloc', link: '/migration/from-bloc' },
            { text: 'From Provider', link: '/migration/from-provider' },
          ],
        },
      ],
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/sitharaj88/reacton' },
    ],

    search: { provider: 'local' },

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright 2025-present',
    },
  },
})
