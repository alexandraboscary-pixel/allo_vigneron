import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

// Client public uniquement (clé anon). La clé service ne doit jamais apparaître côté front.
export const supabase = url && anonKey ? createClient(url, anonKey) : null
