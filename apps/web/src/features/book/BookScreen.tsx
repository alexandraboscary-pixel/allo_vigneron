import { Link } from 'react-router-dom'
import styles from '../screen.module.css'

export function BookScreen() {
  return (
    <section>
      <h1 className={styles.title}>Ton book</h1>
      <p className={styles.lead}>Les vins que tu gardes et ceux que tu achètes. Bientôt ici.</p>
      <p className={styles.lead}>Tu fais du vin ? <Link to="/pro" className={styles.link}>Ouvre ton espace vigneron</Link></p>
    </section>
  )
}
