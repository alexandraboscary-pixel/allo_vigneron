import { NavLink } from 'react-router-dom'
import styles from './TabBar.module.css'

const icons = {
  feed: <path d="M4 11l8-7 8 7v9a1 1 0 0 1-1 1h-5v-6h-4v6H5a1 1 0 0 1-1-1z" />,
  explore: <><circle cx="11" cy="11" r="7" /><path d="M20 20l-4-4" /></>,
  scan: <><path d="M4 8V5a1 1 0 0 1 1-1h3M16 4h3a1 1 0 0 1 1 1v3M20 16v3a1 1 0 0 1-1 1h-3M8 20H5a1 1 0 0 1-1-1v-3" /><path d="M8 12h8" /></>,
  // Une vigneronne à chignon et un vigneron à béret et moustache
  vignerons: <>
    <circle cx="16.6" cy="14.6" r="4.6" />
    <circle cx="18.2" cy="8" r="1.7" fill="currentColor" stroke="none" />
    <path d="M12.3 13.2c1.9 0 3.6-1.1 4.6-2.8 1 1.5 2.4 2.5 4.1 2.8" />
    <circle cx="15.3" cy="15" r=".75" fill="currentColor" stroke="none" />
    <circle cx="18" cy="15" r=".75" fill="currentColor" stroke="none" />
    <path d="M15.5 17c.7.4 1.5.4 2.2 0" />
    <circle cx="7.4" cy="15.4" r="4.6" fill="var(--bg)" />
    <path d="M2.5 12.4c.3-2.4 2.3-3.8 4.9-3.8s4.6 1.1 4.9 3.2c.1.5-.3.8-.9.8H3.1c-.5 0-.7-.1-.6-.2z" fill="currentColor" />
    <path d="M7.4 8.6V7.3" />
    <circle cx="6.1" cy="15.2" r=".75" fill="currentColor" stroke="none" />
    <circle cx="8.7" cy="15.2" r=".75" fill="currentColor" stroke="none" />
    <path d="M5.4 17.2c.7.5 1.4.4 2-.2.6.6 1.3.7 2 .2" />
  </>,
  book: <path d="M7 3h10a1 1 0 0 1 1 1v17l-6-4-6 4V4a1 1 0 0 1 1-1z" />,
}

// Les dessins détaillés gardent un trait plus fin pour rester lisibles à 24 px
const fineStroke = new Set<keyof typeof icons>(['vignerons'])

function Icon({ name }: { name: keyof typeof icons }) {
  return (
    <svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" strokeWidth={fineStroke.has(name) ? 1.6 : 2} strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
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
