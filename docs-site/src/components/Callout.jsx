const config = {
  info: {
    border: 'border-l-blue-500',
    bg: 'bg-blue-50 dark:bg-blue-500/5',
    iconColor: 'text-blue-500',
    titleColor: 'text-blue-800 dark:text-blue-400',
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    ),
    defaultTitle: 'Info',
  },
  tip: {
    border: 'border-l-green-500',
    bg: 'bg-green-50 dark:bg-green-500/5',
    iconColor: 'text-green-500',
    titleColor: 'text-green-800 dark:text-green-400',
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
      </svg>
    ),
    defaultTitle: 'Tip',
  },
  warning: {
    border: 'border-l-amber-500',
    bg: 'bg-amber-50 dark:bg-amber-500/5',
    iconColor: 'text-amber-500',
    titleColor: 'text-amber-800 dark:text-amber-400',
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4.5c-.77-.833-2.694-.833-3.464 0L3.34 16.5c-.77.833.192 2.5 1.732 2.5z" />
      </svg>
    ),
    defaultTitle: 'Warning',
  },
  danger: {
    border: 'border-l-red-500',
    bg: 'bg-red-50 dark:bg-red-500/5',
    iconColor: 'text-red-500',
    titleColor: 'text-red-800 dark:text-red-400',
    icon: (
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    ),
    defaultTitle: 'Danger',
  },
}

export default function Callout({ type = 'info', title, children }) {
  const styles = config[type] || config.info
  const displayTitle = title || styles.defaultTitle

  return (
    <div className={`my-6 rounded-r-xl border-l-4 ${styles.border} ${styles.bg} p-4`}>
      <div className="flex items-center gap-2 mb-2">
        <span className={styles.iconColor}>
          {styles.icon}
        </span>
        <span className={`text-sm font-semibold ${styles.titleColor}`}>
          {displayTitle}
        </span>
      </div>
      <div className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed pl-7">
        {children}
      </div>
    </div>
  )
}
