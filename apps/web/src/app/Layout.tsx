import { Outlet, useLocation } from 'react-router-dom'
import { TabBar } from '../components/TabBar'
import styles from './Layout.module.css'

export function Layout() {
  const { pathname } = useLocation()
  const dark = pathname === '/scan'
  return (
    <div className={`${styles.shell} ${dark ? styles.dark : ''}`}>
      <main className={styles.main}>
        <Outlet />
      </main>
      <TabBar />
    </div>
  )
}
