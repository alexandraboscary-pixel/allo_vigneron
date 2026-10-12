import { useQuery } from '@tanstack/react-query'
import { supabase } from '../../lib/supabase'
import { useAuth } from '../../lib/auth'
import type { Adhesion, Appellation, Domaine, Media, Wine } from '../../lib/types'

// Le domaine du vigneron connecté (un seul domaine par compte pour le MVP)
export function useMyDomaine() {
  const { session } = useAuth()
  const userId = session?.user.id
  return useQuery({
    queryKey: ['my-domaine', userId],
    enabled: Boolean(userId),
    queryFn: async () => {
      const { data, error } = await supabase
        .from('domaine_members')
        .select('domaines(*)')
        .eq('user_id', userId!)
        .limit(1)
        .maybeSingle()
      if (error) throw error
      return (data?.domaines as unknown as Domaine | null) ?? null
    },
  })
}

export function useWines(domaineId: string | undefined) {
  return useQuery({
    queryKey: ['wines', domaineId],
    enabled: Boolean(domaineId),
    queryFn: async () => {
      const { data, error } = await supabase
        .from('wines').select('*').eq('domaine_id', domaineId!).order('created_at', { ascending: false })
      if (error) throw error
      return data as Wine[]
    },
  })
}

export function useWine(id: string | undefined) {
  return useQuery({
    queryKey: ['wine', id],
    enabled: Boolean(id),
    queryFn: async () => {
      const { data, error } = await supabase.from('wines').select('*').eq('id', id!).single()
      if (error) throw error
      return data as Wine
    },
  })
}

export function useAdhesions(domaineId: string | undefined) {
  return useQuery({
    queryKey: ['adhesions', domaineId],
    enabled: Boolean(domaineId),
    queryFn: async () => {
      const { data, error } = await supabase
        .from('appellation_domaines')
        .select('appellation_id, status, appellations(id, slug, name, kind, region)')
        .eq('domaine_id', domaineId!)
      if (error) throw error
      return data as unknown as Adhesion[]
    },
  })
}

export function useAppellations() {
  return useQuery({
    queryKey: ['appellations'],
    queryFn: async () => {
      const { data, error } = await supabase.from('appellations').select('id, slug, name, kind, region').order('name')
      if (error) throw error
      return data as Appellation[]
    },
  })
}

export function useMedias(wineId: string | undefined) {
  return useQuery({
    queryKey: ['medias', wineId],
    enabled: Boolean(wineId),
    // Le traitement n8n fait avancer le statut : on rafraîchit tant qu'un média est en cours
    refetchInterval: (q) =>
      (q.state.data as Media[] | undefined)?.some((m) => m.status === 'uploaded' || m.status === 'processing') ? 5000 : false,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('medias').select('id, wine_id, kind, status, duration_s, created_at')
        .eq('wine_id', wineId!).order('created_at', { ascending: false })
      if (error) throw error
      return data as Media[]
    },
  })
}
