import type { ReactNode } from 'react'
import { Navigate, useLocation } from 'react-router-dom'
import { useAuth } from '../../lib/auth'
import { isSupabaseConfigured } from '../../lib/supabase'
import ui from './pro.module.css'

export function RequireAuth({ children }: { children: ReactNode }) {
  const { session, loading } = useAuth()
  const { pathname } = useLocation()
  if (!isSupabaseConfigured) {
    return <p className={ui.error}>Supabase n'est pas branché : renseigne VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY dans apps/web/.env.local.</p>
  }
  if (loading) return <p className={ui.lead}>Chargement…</p>
  if (!session) return <Navigate to={`/connexion?next=${encodeURIComponent(pathname)}`} replace />
  return <>{children}</>
}
