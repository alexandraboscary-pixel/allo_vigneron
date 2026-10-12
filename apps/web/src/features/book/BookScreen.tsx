import styles from '../screen.module.css'

export function BookScreen() {
  return (
    <section>
      <h1 className={styles.title}>Ton book</h1>
      <p className={styles.lead}>Les vins que tu gardes et ceux que tu achètes. Bientôt ici.</p>
    </section>
  )
}
