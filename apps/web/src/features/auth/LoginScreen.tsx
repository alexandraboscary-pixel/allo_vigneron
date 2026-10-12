import { useState, type FormEvent } from 'react'
import { Navigate, useSearchParams } from 'react-router-dom'
import { supabase } from '../../lib/supabase'
import { useAuth } from '../../lib/auth'
import ui from '../pro/pro.module.css'

export function LoginScreen() {
  const { session } = useAuth()
  const [params] = useSearchParams()
  const next = params.get('next') || '/pro'
  const [email, setEmail] = useState('')
  const [sent, setSent] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  if (session) return <Navigate to={next} replace />

  async function submit(e: FormEvent) {
    e.preventDefault()
    setBusy(true)
    setError(null)
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: `${window.location.origin}${next}` },
    })
    setBusy(false)
    if (error) setError("Le lien n'a pas pu partir. Vérifie ton adresse et réessaie.")
    else setSent(true)
  }

  return (
    <section className={ui.page}>
      <h1 className={ui.title}>Connexion</h1>
      {sent ? (
        <p className={ui.lead}>C'est parti ! Ouvre le lien reçu à <strong>{email}</strong> pour te connecter.</p>
      ) : (
        <form onSubmit={submit} className={ui.form}>
          <p className={ui.lead}>Pas de mot de passe : on t'envoie un lien par e-mail.</p>
          <label className={ui.field}>
            <span>Ton e-mail</span>
            <input type="email" required autoComplete="email" value={email} onChange={(e) => setEmail(e.target.value)} />
          </label>
          {error && <p className={ui.error}>{error}</p>}
          <button className={ui.primary} disabled={busy}>{busy ? 'Envoi…' : 'Recevoir mon lien'}</button>
        </form>
      )}
    </section>
  )
}
