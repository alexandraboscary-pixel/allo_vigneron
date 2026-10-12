import { useState, type FormEvent } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { useQueryClient } from '@tanstack/react-query'
import { supabase } from '../../lib/supabase'
import { slugify } from '../../lib/slug'
import { compressImage } from '../../lib/image'
import type { Wine, WineColor } from '../../lib/types'
import { useAdhesions, useMyDomaine, useWine } from './queries'
import { MediaSection } from './MediaSection'
import ui from './pro.module.css'

const COLORS: { value: WineColor; label: string }[] = [
  { value: 'rouge', label: 'Rouge' },
  { value: 'blanc', label: 'Blanc' },
  { value: 'rose', label: 'Rosé' },
  { value: 'bulles', label: 'Bulles' },
  { value: 'orange', label: 'Orange' },
]

export function WineScreen() {
  const { id } = useParams()
  const isNew = id === 'nouvelle'
  const wine = useWine(isNew ? undefined : id)

  if (!isNew && wine.isLoading) return <p className={ui.lead}>Chargement…</p>
  if (!isNew && !wine.data) return <p className={ui.error}>Cuvée introuvable.</p>

  return (
    <section className={ui.page}>
      <Link to="/pro" className={ui.back}>← Mes cuvées</Link>
      <h1 className={ui.title}>{isNew ? 'Nouvelle cuvée' : wine.data!.name}</h1>
      {!isNew && <MediaSection wine={wine.data!} />}
      <WineForm key={wine.data?.id ?? 'new'} wine={isNew ? undefined : wine.data} />
    </section>
  )
}

function WineForm({ wine }: { wine?: Wine }) {
  const domaine = useMyDomaine().data
  const adhesions = useAdhesions(domaine?.id).data?.filter((a) => a.status === 'active') ?? []
  const qc = useQueryClient()
  const navigate = useNavigate()
  const [name, setName] = useState(wine?.name ?? '')
  const [color, setColor] = useState<WineColor>(wine?.color ?? 'rouge')
  const [vintage, setVintage] = useState(wine?.vintage?.toString() ?? '')
  const [appellationId, setAppellationId] = useState(wine?.appellation_id ?? '')
  const [grapes, setGrapes] = useState(wine?.grapes ?? '')
  const [abv, setAbv] = useState(wine?.abv?.toString() ?? '')
  const [price, setPrice] = useState(wine?.price_cents != null ? (wine.price_cents / 100).toString() : '')
  const [stock, setStock] = useState(wine?.stock?.toString() ?? '0')
  const [published, setPublished] = useState(wine?.is_published ?? false)
  const [label, setLabel] = useState<File | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  if (!domaine) return null

  async function submit(e: FormEvent) {
    e.preventDefault()
    setBusy(true)
    setError(null)
    const id = wine?.id ?? crypto.randomUUID()
    let labelPath = wine?.label_image_path ?? null
    if (label) {
      const photo = await compressImage(label)
      const ext = photo.name.split('.').pop()?.toLowerCase() || 'jpg'
      labelPath = `${domaine!.id}/${id}/etiquette.${ext}`
      const up = await supabase.storage.from('labels').upload(labelPath, photo, { upsert: true, contentType: photo.type })
      if (up.error) {
        setBusy(false)
        return setError("La photo de l'étiquette n'a pas pu être envoyée. Essaie avec une autre photo, au format JPG ou PNG.")
      }
    }
    const fields = {
      name,
      color,
      vintage: vintage ? Number(vintage) : null,
      appellation_id: appellationId || null,
      grapes: grapes || null,
      abv: abv ? Number(abv.replace(',', '.')) : null,
      price_cents: price ? Math.round(Number(price.replace(',', '.')) * 100) : null,
      stock: Number(stock) || 0,
      is_published: published,
      label_image_path: labelPath,
    }
    const { error } = wine
      ? await supabase.from('wines').update(fields).eq('id', wine.id)
      : await supabase.from('wines').insert({ ...fields, id, domaine_id: domaine!.id, slug: slugify(name) })
    setBusy(false)
    if (error) return setError("Ça n'a pas marché. Vérifie les champs et réessaie.")
    await qc.invalidateQueries({ queryKey: ['wines', domaine!.id] })
    await qc.invalidateQueries({ queryKey: ['wine', id] })
    if (!wine) navigate(`/pro/cuvees/${id}`, { replace: true })
  }

  return (
    <form onSubmit={submit} className={ui.form}>
      {wine && <h2 className={ui.h2}>La fiche</h2>}
      <label className={ui.field}>
        <span>Nom de la cuvée</span>
        <input required value={name} onChange={(e) => setName(e.target.value)} placeholder="Chant des Cigales" />
      </label>
      <fieldset className={ui.field}>
        <span>Couleur</span>
        <div className={ui.chips}>
          {COLORS.map((c) => (
            <button type="button" key={c.value} className={ui.chip} aria-pressed={color === c.value} onClick={() => setColor(c.value)}>
              {c.label}
            </button>
          ))}
        </div>
      </fieldset>
      <div className={ui.grid2}>
        <label className={ui.field}>
          <span>Millésime</span>
          <input inputMode="numeric" pattern="[0-9]{4}" value={vintage} onChange={(e) => setVintage(e.target.value)} placeholder="2023" />
        </label>
        <label className={ui.field}>
          <span>Degré (%)</span>
          <input inputMode="decimal" value={abv} onChange={(e) => setAbv(e.target.value)} placeholder="13,5" />
        </label>
      </div>
      <label className={ui.field}>
        <span>Appellation</span>
        <select value={appellationId} onChange={(e) => setAppellationId(e.target.value)}>
          <option value="">Aucune</option>
          {adhesions.map((a) => <option key={a.appellation_id} value={a.appellation_id}>{a.appellations.name}</option>)}
        </select>
      </label>
      <label className={ui.field}>
        <span>Cépages</span>
        <input value={grapes} onChange={(e) => setGrapes(e.target.value)} placeholder="Grenache, Syrah" />
      </label>
      <div className={ui.grid2}>
        <label className={ui.field}>
          <span>Prix (€)</span>
          <input inputMode="decimal" value={price} onChange={(e) => setPrice(e.target.value)} placeholder="12,50" />
        </label>
        <label className={ui.field}>
          <span>Stock (bouteilles)</span>
          <input inputMode="numeric" value={stock} onChange={(e) => setStock(e.target.value)} />
        </label>
      </div>
      <label className={ui.field}>
        <span>Photo de l'étiquette</span>
        <input type="file" accept="image/*" onChange={(e) => setLabel(e.target.files?.[0] ?? null)} />
      </label>
      <label className={ui.check}>
        <input type="checkbox" checked={published} onChange={(e) => setPublished(e.target.checked)} />
        <span>Visible dans l'app</span>
      </label>
      {error && <p className={ui.error}>{error}</p>}
      <button className={ui.primary} disabled={busy}>{busy ? 'Enregistrement…' : wine ? 'Enregistrer' : 'Créer la cuvée'}</button>
    </form>
  )
}
