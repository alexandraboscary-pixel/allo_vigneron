export function formatPrice(cents: number | null) {
  if (cents == null) return ''
  return (cents / 100).toLocaleString('fr-FR', { style: 'currency', currency: 'EUR' })
}
