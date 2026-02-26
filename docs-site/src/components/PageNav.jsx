import { Link } from 'react-router-dom'

export default function PageNav({ prev, next }) {
  if (!prev && !next) return null

  return (
    <nav className="mt-16 pt-8 border-t border-gray-200 dark:border-gray-800">
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        {/* Previous Link */}
        {prev ? (
          <Link
            to={prev.path}
            className="group flex items-center gap-3 px-5 py-4 rounded-xl border border-gray-200 dark:border-gray-800 hover:border-purple-300 dark:hover:border-purple-700 hover:bg-purple-50/50 dark:hover:bg-purple-500/5 transition-all"
          >
            <svg
              className="w-5 h-5 text-gray-400 group-hover:text-purple-500 transition-colors shrink-0"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
            <div className="flex flex-col">
              <span className="text-xs font-medium text-gray-500 dark:text-gray-400">
                Previous
              </span>
              <span className="text-sm font-semibold text-gray-900 dark:text-white group-hover:text-purple-600 dark:group-hover:text-purple-400 transition-colors">
                {prev.title}
              </span>
            </div>
          </Link>
        ) : (
          <div />
        )}

        {/* Next Link */}
        {next ? (
          <Link
            to={next.path}
            className="group flex items-center justify-end gap-3 px-5 py-4 rounded-xl border border-gray-200 dark:border-gray-800 hover:border-purple-300 dark:hover:border-purple-700 hover:bg-purple-50/50 dark:hover:bg-purple-500/5 transition-all text-right"
          >
            <div className="flex flex-col">
              <span className="text-xs font-medium text-gray-500 dark:text-gray-400">
                Next
              </span>
              <span className="text-sm font-semibold text-gray-900 dark:text-white group-hover:text-purple-600 dark:group-hover:text-purple-400 transition-colors">
                {next.title}
              </span>
            </div>
            <svg
              className="w-5 h-5 text-gray-400 group-hover:text-purple-500 transition-colors shrink-0"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </Link>
        ) : (
          <div />
        )}
      </div>
    </nav>
  )
}
