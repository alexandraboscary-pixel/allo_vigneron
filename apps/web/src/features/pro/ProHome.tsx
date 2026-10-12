import { Link } from 'react-router-dom'
import { useQueryClient } from '@tanstack/react-query'
import { supabase } from '../../lib/supabase'
import { formatPrice } from './format'
import { useAdhesions, useAppellations, useMyDomaine, useWines } from './queries'
import { DomaineForm } from './DomaineForm'
import ui from './pro.module.css'

const statusLabel = { pending: 'En attente de validation', active: 'Validé', suspended: 'Suspendu' } as const

export function ProHome() {
  const domaine = useMyDomaine()
  const wines = useWines(domaine.data?.id)

  if (domaine.isLoading) return <p className={ui.lead}>Chargement…</p>
  if (domaine.error) return <p className={ui.error}>Impossible de charger ton domaine.</p>

  if (!domaine.data) {
    return (
      <section className={ui.page}>
        <h1 className={ui.title}>Bienvenue !</h1>
        <p className={ui.lead}>Commence par présenter ton domaine. Allô Vino le valide, puis tes vins sont visibles.</p>
        <DomaineForm />
      </section>
    )
  }

  const d = domaine.data
  return (
    <section className={ui.page}>
      <div className={ui.domaineCard} style={{ background: `linear-gradient(135deg, ${d.color_1}, ${d.color_2})` }}>
        <span className={ui.badge}>{statusLabel[d.status]}</span>
        <h1 className={ui.title}>{d.name}</h1>
        <p>{d.first_name} · {d.region}</p>
        <Link to="/pro/domaine" className={ui.cardLink}>Modifier ma fiche</Link>
      </div>

      <Appellations domaineId={d.id} />

      <div className={ui.row}>
        <h2 className={ui.h2}>Mes cuvées</h2>
        <Link to="/pro/cuvees/nouvelle" className={ui.primarySmall}>Ajouter une cuvée</Link>
      </div>
      {wines.data?.length === 0 && <p className={ui.lead}>Pas encore de cuvée. Ajoute la première, puis enregistre-toi pour en parler.</p>}
      <ul className={ui.list}>
        {wines.data?.map((w) => (
          <li key={w.id}>
            <Link to={`/pro/cuvees/${w.id}`} className={ui.item}>
              <span className={ui.dot} data-color={w.color} />
              <span className={ui.itemMain}>
                <strong>{w.name}</strong>
                <small>{[w.vintage, w.color, formatPrice(w.price_cents)].filter(Boolean).join(' · ')}</small>
              </span>
              <span className={ui.muted}>{w.is_published ? 'En ligne' : 'Brouillon'}</span>
            </Link>
          </li>
        ))}
      </ul>
    </section>
  )
}

function Appellations({ domaineId }: { domaineId: string }) {
  const qc = useQueryClient()
  const adhesions = useAdhesions(domaineId)
  const all = useAppellations()
  const joined = new Set(adhesions.data?.filter((a) => a.status !== 'left').map((a) => a.appellation_id))
  const others = all.data?.filter((a) => !joined.has(a.id)) ?? []

  async function request(appellationId: string) {
    const { error } = await supabase.from('appellation_domaines').insert({ appellation_id: appellationId, domaine_id: domaineId })
    if (!error) qc.invalidateQueries({ queryKey: ['adhesions', domaineId] })
  }

  return (
    <div className={ui.block}>
      <h2 className={ui.h2}>Mes appellations</h2>
      {adhesions.data?.filter((a) => a.status !== 'left').map((a) => (
        <p key={a.appellation_id} className={ui.chipLine}>
          {a.appellations.name} <span className={ui.muted}>{a.status === 'active' ? 'Adhérent' : 'Demande envoyée'}</span>
        </p>
      ))}
      {others.length > 0 && (
        <details className={ui.details}>
          <summary>Rejoindre une appellation</summary>
          {others.map((a) => (
            <p key={a.id} className={ui.chipLine}>
              {a.name} <button className={ui.link} onClick={() => request(a.id)}>Demander à adhérer</button>
            </p>
          ))}
        </details>
      )}
    </div>
  )
}
