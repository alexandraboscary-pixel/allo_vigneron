import { useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { useQueryClient } from '@tanstack/react-query'
import { supabase } from '../../lib/supabase'
import { slugify } from '../../lib/slug'
import { useMyDomaine } from './queries'
import ui from './pro.module.css'

// Paires de couleurs proposées pour le dégradé du domaine (README section 9)
const PALETTES: [string, string][] = [
  ['#FF8FAB', '#FFC79E'],
  ['#B8A1FF', '#FFD6E0'],
  ['#7FD6B0', '#FFE58F'],
  ['#FFB36B', '#FF8FAB'],
  ['#8FC8FF', '#C9B8FF'],
  ['#FF3D6E', '#FFC93C'],
]

export function DomaineForm() {
  const existing = useMyDomaine().data
  const qc = useQueryClient()
  const navigate = useNavigate()
  const [name, setName] = useState(existing?.name ?? '')
  const [firstName, setFirstName] = useState(existing?.first_name ?? '')
  const [region, setRegion] = useState(existing?.region ?? '')
  const [bio, setBio] = useState(existing?.bio ?? '')
  const [palette, setPalette] = useState<[string, string]>(existing ? [existing.color_1, existing.color_2] : PALETTES[0])
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  async function submit(e: FormEvent) {
    e.preventDefault()
    setBusy(true)
    setError(null)
    const fields = { name, first_name: firstName, region, bio: bio || null, color_1: palette[0], color_2: palette[1] }
    const { error } = existing
      ? await supabase.from('domaines').update(fields).eq('id', existing.id)
      : await supabase.from('domaines').insert({ ...fields, slug: slugify(name) })
    setBusy(false)
    if (error) return setError("Ça n'a pas marché. Réessaie dans un instant.")
    await qc.invalidateQueries({ queryKey: ['my-domaine'] })
    navigate('/pro')
  }

  return (
    <form onSubmit={submit} className={ui.form}>
      <label className={ui.field}>
        <span>Nom du domaine</span>
        <input required value={name} onChange={(e) => setName(e.target.value)} placeholder="Mas des Cigales" />
      </label>
      <label className={ui.field}>
        <span>Ton prénom (affiché sur l'app)</span>
        <input required value={firstName} onChange={(e) => setFirstName(e.target.value)} placeholder="Léa" />
      </label>
      <label className={ui.field}>
        <span>Région</span>
        <input required value={region} onChange={(e) => setRegion(e.target.value)} placeholder="Languedoc" />
      </label>
      <label className={ui.field}>
        <span>Ton domaine en deux phrases</span>
        <textarea rows={3} value={bio} onChange={(e) => setBio(e.target.value)} placeholder="J'ai repris les vignes de mon grand-père…" />
      </label>
      <fieldset className={ui.field}>
        <span>Tes couleurs</span>
        <div className={ui.palettes}>
          {PALETTES.map((p) => (
            <button
              type="button"
              key={p.join()}
              aria-label={`Couleurs ${p.join(' et ')}`}
              aria-pressed={p[0] === palette[0] && p[1] === palette[1]}
              className={ui.swatch}
              style={{ background: `linear-gradient(135deg, ${p[0]}, ${p[1]})` }}
              onClick={() => setPalette(p)}
            />
          ))}
        </div>
      </fieldset>
      {error && <p className={ui.error}>{error}</p>}
      <button className={ui.primary} disabled={busy}>{busy ? 'Enregistrement…' : existing ? 'Enregistrer' : 'Créer mon domaine'}</button>
    </form>
  )
}

export function DomaineEditScreen() {
  return (
    <section className={ui.page}>
      <h1 className={ui.title}>Ma fiche domaine</h1>
      <DomaineForm />
    </section>
  )
}
