export type Status = 'pending' | 'active' | 'suspended'
export type WineColor = 'rouge' | 'rose' | 'blanc' | 'bulles' | 'orange'
export type MediaKind = 'audio' | 'video'
export type MediaStatus = 'uploaded' | 'processing' | 'review' | 'published' | 'error'

export interface Domaine {
  id: string
  slug: string
  name: string
  first_name: string
  region: string
  bio: string | null
  color_1: string
  color_2: string
  status: Status
}

export interface Appellation {
  id: string
  slug: string
  name: string
  kind: 'aop' | 'igp'
  region: string
}

export interface Adhesion {
  appellation_id: string
  status: 'pending' | 'active' | 'left'
  appellations: Appellation
}

export interface Wine {
  id: string
  domaine_id: string
  appellation_id: string | null
  slug: string
  name: string
  color: WineColor
  vintage: number | null
  grapes: string | null
  abv: number | null
  price_cents: number | null
  stock: number
  label_image_path: string | null
  is_published: boolean
}

export interface Media {
  id: string
  wine_id: string
  kind: MediaKind
  status: MediaStatus
  duration_s: number | null
  created_at: string
}
