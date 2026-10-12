import { Link, Outlet } from 'react-router-dom'
import { supabase } from '../../lib/supabase'
import { RequireAuth } from './RequireAuth'
import ui from './pro.module.css'

export function ProLayout() {
  return (
    <div className={ui.shell}>
      <header className={ui.header}>
        <Link to="/pro" className={ui.brand}>Allô Vino <span>pro</span></Link>
        <button className={ui.link} onClick={() => supabase.auth.signOut()}>Me déconnecter</button>
      </header>
      <main className={ui.main}>
        <RequireAuth>
          <Outlet />
        </RequireAuth>
      </main>
    </div>
  )
}
