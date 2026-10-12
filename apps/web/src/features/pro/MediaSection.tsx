import { useState } from 'react'
import { useQueryClient } from '@tanstack/react-query'
import { supabase } from '../../lib/supabase'
import type { Media, MediaKind, MediaStatus, Wine } from '../../lib/types'
import { useMedias } from './queries'
import { MAX_S, MIN_S, Recorder, type Take } from './Recorder'
import ui from './pro.module.css'

// Limite d'envoi de l'offre gratuite Supabase (50 Mo par fichier)
const MAX_IMPORT_MB = 50

const statusLabel: Record<MediaStatus, string> = {
  uploaded: 'Envoyé, en attente de traitement',
  processing: 'En cours de traitement',
  review: 'Prêt à relire',
  published: 'En ligne',
  error: 'Problème de traitement, renvoie-le',
}

function extFor(blob: Blob, kind: MediaKind) {
  const t = blob.type
  if (t.includes('mp4')) return kind === 'audio' ? 'm4a' : 'mp4'
  if (t.includes('webm')) return 'webm'
  if (t.includes('quicktime')) return 'mov'
  if (t.includes('mpeg')) return 'mp3'
  if (t.includes('wav')) return 'wav'
  if (t.includes('ogg')) return 'ogg'
  return kind === 'audio' ? 'm4a' : 'mp4'
}

function readDuration(file: File, kind: MediaKind) {
  return new Promise<number>((resolve) => {
    const el = document.createElement(kind)
    el.preload = 'metadata'
    el.onloadedmetadata = () => {
      resolve(Number.isFinite(el.duration) ? Math.round(el.duration) : 0)
      URL.revokeObjectURL(el.src)
    }
    el.onerror = () => resolve(0)
    el.src = URL.createObjectURL(file)
  })
}

export function MediaSection({ wine }: { wine: Wine }) {
  const medias = useMedias(wine.id)
  const qc = useQueryClient()
  const [kind, setKind] = useState<MediaKind>('audio')
  const [take, setTake] = useState<Take | null>(null)
  const [mode, setMode] = useState<'record' | 'import'>('record')
  const [busy, setBusy] = useState(false)
  const [message, setMessage] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  async function importFile(file: File | undefined) {
    setError(null)
    setTake(null)
    if (!file) return
    const fileKind: MediaKind = file.type.startsWith('video') ? 'video' : 'audio'
    if (file.size > MAX_IMPORT_MB * 1024 * 1024) return setError(`Fichier trop lourd : ${MAX_IMPORT_MB} Mo maximum.`)
    const duration = await readDuration(file, fileKind)
    if (duration > MAX_S) return setError(`Ton fichier dure ${duration} s : ${MAX_S} s maximum.`)
    setKind(fileKind)
    setTake({ blob: file, kind: fileKind, duration })
  }

  async function send() {
    if (!take) return
    if (take.duration && take.duration < MIN_S) return setError(`Parle au moins ${MIN_S} s pour qu'on comprenne ton vin.`)
    setBusy(true)
    setError(null)
    const id = crypto.randomUUID()
    const path = `${wine.domaine_id}/${wine.id}/${id}.${extFor(take.blob, take.kind)}`
    // Le fichier d'abord : n8n le télécharge dès que la ligne est créée
    const up = await supabase.storage.from('medias-raw').upload(path, take.blob, { contentType: take.blob.type || undefined })
    if (up.error) {
      setBusy(false)
      return setError("L'envoi n'a pas marché. Vérifie ta connexion et réessaie.")
    }
    const { error } = await supabase.from('medias').insert({
      id, wine_id: wine.id, domaine_id: wine.domaine_id, kind: take.kind, storage_path: path, duration_s: take.duration || null,
    })
    setBusy(false)
    if (error) {
      await supabase.storage.from('medias-raw').remove([path])
      return setError("L'envoi n'a pas marché. Réessaie dans un instant.")
    }
    setTake(null)
    setMessage(take.kind === 'video'
      ? "Vidéo envoyée ! On prépare ta fiche, tu recevras un e-mail pour la relire."
      : "Audio envoyé ! On prépare ta fiche, tu recevras un e-mail pour la relire.")
    qc.invalidateQueries({ queryKey: ['medias', wine.id] })
  }

  async function remove(m: Media) {
    if (!confirm('Supprimer cet enregistrement ?')) return
    await supabase.from('medias').delete().eq('id', m.id)
    qc.invalidateQueries({ queryKey: ['medias', wine.id] })
  }

  return (
    <div className={ui.block}>
      <h2 className={ui.h2}>Parle de ton vin</h2>
      <p className={ui.lead}>Entre {MIN_S} et {MAX_S} secondes, comme si tu parlais à un ami qui n'y connaît rien. Rien n'est publié sans ta relecture.</p>

      {medias.data && medias.data.length > 0 && (
        <ul className={ui.list}>
          {medias.data.map((m) => (
            <li key={m.id} className={ui.item}>
              <span className={ui.itemMain}>
                <strong>{m.kind === 'video' ? 'Vidéo' : 'Audio'}{m.duration_s ? ` · ${m.duration_s} s` : ''}</strong>
                <small>{statusLabel[m.status]}</small>
              </span>
              {m.status !== 'published' && <button className={ui.link} onClick={() => remove(m)}>Supprimer</button>}
            </li>
          ))}
        </ul>
      )}

      {message && <p className={ui.success}>{message}</p>}

      <div className={ui.chips} role="group" aria-label="Type d'enregistrement">
        <button type="button" className={ui.chip} aria-pressed={mode === 'record' && kind === 'audio'}
          onClick={() => { setMode('record'); setKind('audio'); setTake(null); setMessage(null) }}>Audio</button>
        <button type="button" className={ui.chip} aria-pressed={mode === 'record' && kind === 'video'}
          onClick={() => { setMode('record'); setKind('video'); setTake(null); setMessage(null) }}>Vidéo</button>
        <button type="button" className={ui.chip} aria-pressed={mode === 'import'}
          onClick={() => { setMode('import'); setTake(null); setMessage(null) }}>Importer un fichier</button>
      </div>

      {mode === 'record'
        ? <Recorder key={kind} kind={kind} onTake={setTake} />
        : (
          <label className={ui.field}>
            <span>Audio ou vidéo, {MAX_S} s et {MAX_IMPORT_MB} Mo maximum</span>
            <input type="file" accept="audio/*,video/*" onChange={(e) => importFile(e.target.files?.[0])} />
          </label>
        )}

      {error && <p className={ui.error}>{error}</p>}
      {take && (
        <button type="button" className={ui.primary} onClick={send} disabled={busy}>
          {busy ? 'Envoi…' : take.kind === 'video' ? 'Envoyer ma vidéo' : 'Envoyer mon audio'}
        </button>
      )}
    </div>
  )
}
