import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL as string | undefined
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined

export const isSupabaseConfigured = Boolean(url && anonKey)

// Client public uniquement (clé anon / publishable). La clé service ne doit jamais apparaître côté front.
export const supabase = createClient(url || 'http://localhost:54321', anonKey || 'cle-manquante')
