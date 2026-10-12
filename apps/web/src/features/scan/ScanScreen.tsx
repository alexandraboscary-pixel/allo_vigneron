import styles from '../screen.module.css'

export function ScanScreen() {
  return (
    <section>
      <h1 className={styles.title}>Scanne une bouteille</h1>
      <p className={styles.lead}>Vise le QR « Écoute le vigneron » sur l'étiquette.</p>
    </section>
  )
}
