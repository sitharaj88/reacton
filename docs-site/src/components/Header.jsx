import { useState, useEffect, useCallback, useRef } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'

const searchIndex = [
  { title: 'Getting Started', section: 'Setup', path: '/getting-started' },
  { title: 'atom()', section: 'Core Concepts', path: '/core-concepts' },
  { title: 'computed()', section: 'Core Concepts', path: '/core-concepts' },
  { title: 'ReactonStore', section: 'Core Concepts', path: '/core-concepts' },
  { title: 'effect()', section: 'Core Concepts', path: '/core-concepts' },
  { title: 'selector()', section: 'Core Concepts', path: '/core-concepts' },
  { title: 'family()', section: 'Core Concepts', path: '/core-concepts' },
  { title: 'ReactonScope', section: 'Widgets', path: '/flutter-widgets' },
  { title: 'ReactonBuilder', section: 'Widgets', path: '/flutter-widgets' },
  { title: 'ReactonConsumer', section: 'Widgets', path: '/flutter-widgets' },
  { title: 'context.watch()', section: 'Widgets', path: '/flutter-widgets' },
  { title: 'AsyncValue', section: 'Async', path: '/async-middleware' },
  { title: 'Middleware', section: 'Async', path: '/async-middleware' },
  { title: 'State Branching', section: 'Advanced', path: '/advanced' },
  { title: 'Time Travel', section: 'Advanced', path: '/advanced' },
  { title: 'Multi-Isolate', section: 'Advanced', path: '/advanced' },
  { title: 'Testing', section: 'Tooling', path: '/testing' },
  { title: 'DevTools', section: 'Tooling', path: '/tooling' },
  { title: 'CLI', section: 'Tooling', path: '/tooling' },
  { title: 'Lint Rules', section: 'Tooling', path: '/tooling' },
]

const navLinks = [
  { label: 'Docs', path: '/getting-started' },
  { label: 'Guide', path: '/core-concepts' },
  { label: 'Tooling', path: '/tooling' },
]

export default function Header({ onMenuToggle }) {
  const [isDark, setIsDark] = useState(() => document.documentElement.classList.contains('dark'))
  const [searchOpen, setSearchOpen] = useState(false)
  const [searchQuery, setSearchQuery] = useState('')
  const searchInputRef = useRef(null)
  const location = useLocation()
  const navigate = useNavigate()

  // Theme initialization
  useEffect(() => {
    const stored = localStorage.getItem('reacton-theme')
    if (stored === 'dark' || (!stored && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
      document.documentElement.classList.add('dark')
      setIsDark(true)
    } else {
      document.documentElement.classList.remove('dark')
      setIsDark(false)
    }
  }, [])

  const toggleTheme = useCallback(() => {
    const nextDark = !isDark
    setIsDark(nextDark)
    if (nextDark) {
      document.documentElement.classList.add('dark')
      localStorage.setItem('reacton-theme', 'dark')
    } else {
      document.documentElement.classList.remove('dark')
      localStorage.setItem('reacton-theme', 'light')
    }
  }, [isDark])

  // Keyboard shortcut for search
  useEffect(() => {
    const handleKeyDown = (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault()
        setSearchOpen((prev) => !prev)
      }
      if (e.key === 'Escape') {
        setSearchOpen(false)
      }
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [])

  // Focus search input when modal opens
  useEffect(() => {
    if (searchOpen && searchInputRef.current) {
      searchInputRef.current.focus()
    }
    if (searchOpen) {
      setSearchQuery('')
    }
  }, [searchOpen])

  const filteredResults = searchQuery.trim()
    ? searchIndex.filter(
        (item) =>
          item.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
          item.section.toLowerCase().includes(searchQuery.toLowerCase())
      )
    : []

  const handleResultClick = (path) => {
    setSearchOpen(false)
    navigate(path)
  }

  const isActive = (path) => location.pathname === path

  return (
    <>
      <header className="fixed top-0 left-0 right-0 z-50 h-16 bg-white/80 dark:bg-gray-950/80 backdrop-blur-xl border-b border-gray-200 dark:border-gray-800">
        <div className="flex items-center justify-between h-full px-4 sm:px-6 lg:px-8 max-w-screen-2xl mx-auto">
          {/* Left: Logo + Nav */}
          <div className="flex items-center gap-8">
            <Link to="/" className="flex items-center gap-3 group">
              <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-gradient-to-br from-purple-500 to-violet-600 text-white font-bold text-sm shadow-lg shadow-purple-500/25">
                P
              </div>
              <span className="text-lg font-bold text-gray-900 dark:text-white tracking-tight">
                Reacton
              </span>
            </Link>

            {/* Desktop Nav */}
            <nav className="hidden md:flex items-center gap-1">
              {navLinks.map((link) => (
                <Link
                  key={link.path}
                  to={link.path}
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                    isActive(link.path)
                      ? 'text-purple-600 dark:text-purple-400 bg-purple-50 dark:bg-purple-500/10'
                      : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-gray-800'
                  }`}
                >
                  {link.label}
                </Link>
              ))}
            </nav>
          </div>

          {/* Right: Actions */}
          <div className="flex items-center gap-2">
            {/* Search Button */}
            <button
              onClick={() => setSearchOpen(true)}
              className="flex items-center gap-2 px-3 py-1.5 rounded-lg text-sm text-gray-500 dark:text-gray-400 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
              <span className="hidden sm:inline">Search</span>
              <kbd className="hidden sm:inline-flex items-center px-1.5 py-0.5 rounded text-xs font-mono bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400">
                Ctrl K
              </kbd>
            </button>

            {/* Theme Toggle */}
            <button
              onClick={toggleTheme}
              className="flex items-center justify-center w-9 h-9 rounded-lg text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
              aria-label="Toggle theme"
            >
              {isDark ? (
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
                </svg>
              ) : (
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
                </svg>
              )}
            </button>

            {/* GitHub Link */}
            <a
              href="https://github.com/reactonstatemanagement/reacton"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center justify-center w-9 h-9 rounded-lg text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
              aria-label="GitHub"
            >
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                <path fillRule="evenodd" clipRule="evenodd" d="M12 2C6.477 2 2 6.477 2 12c0 4.42 2.865 8.166 6.839 9.489.5.092.682-.217.682-.482 0-.237-.008-.866-.013-1.7-2.782.604-3.369-1.34-3.369-1.34-.454-1.156-1.11-1.463-1.11-1.463-.908-.62.069-.608.069-.608 1.003.07 1.531 1.03 1.531 1.03.892 1.529 2.341 1.087 2.91.831.092-.646.35-1.086.636-1.337-2.22-.253-4.555-1.11-4.555-4.943 0-1.091.39-1.984 1.029-2.683-.103-.253-.446-1.27.098-2.647 0 0 .84-.269 2.75 1.025A9.578 9.578 0 0112 6.836c.85.004 1.705.115 2.504.337 1.909-1.294 2.747-1.025 2.747-1.025.546 1.377.203 2.394.1 2.647.64.699 1.028 1.592 1.028 2.683 0 3.842-2.339 4.687-4.566 4.935.359.309.678.919.678 1.852 0 1.336-.012 2.415-.012 2.743 0 .267.18.578.688.48C19.138 20.161 22 16.416 22 12c0-5.523-4.477-10-10-10z" />
              </svg>
            </a>

            {/* Mobile Menu Button */}
            <button
              onClick={onMenuToggle}
              className="flex md:hidden items-center justify-center w-9 h-9 rounded-lg text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
              aria-label="Toggle menu"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
              </svg>
            </button>
          </div>
        </div>
      </header>

      {/* Search Modal */}
      {searchOpen && (
        <div
          className="fixed inset-0 z-[100] flex items-start justify-center pt-[15vh] bg-black/50 backdrop-blur-sm"
          onClick={() => setSearchOpen(false)}
        >
          <div
            className="w-full max-w-xl mx-4 bg-white dark:bg-gray-900 rounded-2xl shadow-2xl border border-gray-200 dark:border-gray-700 overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Search Input */}
            <div className="flex items-center gap-3 px-4 border-b border-gray-200 dark:border-gray-700">
              <svg className="w-5 h-5 text-gray-400 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
              <input
                ref={searchInputRef}
                type="text"
                placeholder="Search documentation..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="flex-1 py-4 bg-transparent text-gray-900 dark:text-white placeholder-gray-400 outline-none text-base"
              />
              <kbd
                className="hidden sm:inline-flex items-center px-2 py-1 rounded text-xs font-mono bg-gray-100 dark:bg-gray-800 text-gray-500 dark:text-gray-400 cursor-pointer"
                onClick={() => setSearchOpen(false)}
              >
                Esc
              </kbd>
            </div>

            {/* Search Results */}
            <div className="max-h-80 overflow-y-auto">
              {searchQuery.trim() && filteredResults.length === 0 && (
                <div className="px-4 py-8 text-center text-gray-500 dark:text-gray-400 text-sm">
                  No results found for &ldquo;{searchQuery}&rdquo;
                </div>
              )}
              {filteredResults.length > 0 && (
                <ul className="py-2">
                  {filteredResults.map((item, index) => (
                    <li key={`${item.title}-${index}`}>
                      <button
                        onClick={() => handleResultClick(item.path)}
                        className="w-full flex items-center gap-3 px-4 py-3 text-left hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                      >
                        <svg className="w-4 h-4 text-gray-400 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                        </svg>
                        <div className="flex-1 min-w-0">
                          <div className="text-sm font-medium text-gray-900 dark:text-white truncate">
                            {item.title}
                          </div>
                          <div className="text-xs text-gray-500 dark:text-gray-400">
                            {item.section}
                          </div>
                        </div>
                        <svg className="w-4 h-4 text-gray-300 dark:text-gray-600 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                        </svg>
                      </button>
                    </li>
                  ))}
                </ul>
              )}
              {!searchQuery.trim() && (
                <div className="px-4 py-8 text-center text-gray-500 dark:text-gray-400 text-sm">
                  Start typing to search the documentation...
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </>
  )
}
