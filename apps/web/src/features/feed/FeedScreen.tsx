import styles from '../screen.module.css'

export function FeedScreen() {
  return (
    <section>
      <h1 className={styles.title}>Le fil</h1>
      <p className={styles.lead}>Les vignerons te parlent de leurs vins. Bientôt ici.</p>
    </section>
  )
}
