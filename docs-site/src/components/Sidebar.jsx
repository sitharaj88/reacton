import { Link, useLocation } from 'react-router-dom'

const sections = [
  {
    heading: 'GETTING STARTED',
    links: [
      { title: 'Installation', path: '/getting-started' },
    ],
  },
  {
    heading: 'CORE',
    links: [
      { title: 'Core Concepts', path: '/core-concepts' },
    ],
  },
  {
    heading: 'FLUTTER',
    links: [
      { title: 'Widgets', path: '/flutter-widgets' },
    ],
  },
  {
    heading: 'ADVANCED',
    links: [
      { title: 'Async & Middleware', path: '/async-middleware' },
      { title: 'Advanced Features', path: '/advanced' },
    ],
  },
  {
    heading: 'TOOLING',
    links: [
      { title: 'Testing', path: '/testing' },
      { title: 'Tooling', path: '/tooling' },
    ],
  },
]

export default function Sidebar({ isOpen, onClose }) {
  const location = useLocation()

  const isActive = (path) => location.pathname === path

  const sidebarContent = (
    <nav className="flex flex-col gap-6 px-4 py-6 overflow-y-auto h-full">
      {sections.map((section) => (
        <div key={section.heading}>
          <h4 className="text-xs font-semibold tracking-wider text-gray-400 dark:text-gray-500 uppercase mb-2 px-3">
            {section.heading}
          </h4>
          <ul className="flex flex-col gap-0.5">
            {section.links.map((link) => (
              <li key={link.path}>
                <Link
                  to={link.path}
                  onClick={onClose}
                  className={`block px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                    isActive(link.path)
                      ? 'bg-purple-50 dark:bg-purple-500/10 text-purple-600 dark:text-purple-400'
                      : 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 hover:text-gray-900 dark:hover:text-white'
                  }`}
                >
                  {link.title}
                </Link>
              </li>
            ))}
          </ul>
        </div>
      ))}
    </nav>
  )

  return (
    <>
      {/* Desktop Sidebar */}
      <aside className="hidden lg:block fixed left-0 top-16 bottom-0 w-72 bg-white dark:bg-gray-950 border-r border-gray-200 dark:border-gray-800 overflow-y-auto">
        {sidebarContent}
      </aside>

      {/* Mobile Sidebar Overlay */}
      {isOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm lg:hidden"
          onClick={onClose}
        />
      )}

      {/* Mobile Sidebar Drawer */}
      <aside
        className={`fixed left-0 top-16 bottom-0 w-72 z-50 bg-white dark:bg-gray-950 border-r border-gray-200 dark:border-gray-800 transform transition-transform duration-300 ease-in-out lg:hidden ${
          isOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        {sidebarContent}
      </aside>
    </>
  )
}
