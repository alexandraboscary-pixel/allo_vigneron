import { NavLink } from 'react-router-dom'
import styles from './TabBar.module.css'

const icons = {
  feed: <path d="M4 11l8-7 8 7v9a1 1 0 0 1-1 1h-5v-6h-4v6H5a1 1 0 0 1-1-1z" />,
  explore: <><circle cx="11" cy="11" r="7" /><path d="M20 20l-4-4" /></>,
  scan: <><path d="M4 8V5a1 1 0 0 1 1-1h3M16 4h3a1 1 0 0 1 1 1v3M20 16v3a1 1 0 0 1-1 1h-3M8 20H5a1 1 0 0 1-1-1v-3" /><path d="M8 12h8" /></>,
  // Vigneron à béret et moustache
  vignerons: <>
    <circle cx="12" cy="14.5" r="6" />
    <path d="M5.2 10.2C5.8 7 8.6 5.3 12 5.3s6.8 1.3 7.3 4.3c.1.7-.5 1.1-1.3 1.1H6.2c-.7 0-1.1-.2-1-.5z" fill="currentColor" />
    <path d="M12 5.3V3.6" />
    <circle cx="9.8" cy="13.4" r="1" fill="currentColor" stroke="none" />
    <circle cx="14.2" cy="13.4" r="1" fill="currentColor" stroke="none" />
    <path d="M8.6 16.6c1.3.9 2.6.6 3.4-.4.8 1 2.1 1.3 3.4.4" />
  </>,
  book: <path d="M7 3h10a1 1 0 0 1 1 1v17l-6-4-6 4V4a1 1 0 0 1 1-1z" />,
}

function Icon({ name }: { name: keyof typeof icons }) {
  return (
    <svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      {icons[name]}
    </svg>
  )
}

const tabClass = ({ isActive }: { isActive: boolean }) => `${styles.tab} ${isActive ? styles.active : ''}`

export function TabBar() {
  return (
    <nav className={styles.bar} aria-label="Navigation principale">
      <NavLink to="/" end className={tabClass}><Icon name="feed" /><span>Fil</span></NavLink>
      <NavLink to="/explorer" className={tabClass}><Icon name="explore" /><span>Explorer</span></NavLink>
      <NavLink to="/scan" className={styles.scan} aria-label="Scanner une bouteille"><Icon name="scan" /></NavLink>
      <NavLink to="/vignerons" className={tabClass}><Icon name="vignerons" /><span>Vignerons</span></NavLink>
      <NavLink to="/book" className={tabClass}><Icon name="book" /><span>Book</span></NavLink>
    </nav>
  )
}
