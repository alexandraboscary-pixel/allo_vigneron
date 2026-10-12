import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter, Route, Routes } from 'react-router-dom'
import { AuthProvider } from '../lib/auth'
import { Layout } from './Layout'
import { FeedScreen } from '../features/feed/FeedScreen'
import { ExploreScreen } from '../features/explore/ExploreScreen'
import { ScanScreen } from '../features/scan/ScanScreen'
import { VigneronsScreen } from '../features/domaine/VigneronsScreen'
import { BookScreen } from '../features/book/BookScreen'
import { LoginScreen } from '../features/auth/LoginScreen'
import { ProLayout } from '../features/pro/ProLayout'
import { ProHome } from '../features/pro/ProHome'
import { DomaineEditScreen } from '../features/pro/DomaineForm'
import { WineScreen } from '../features/pro/WineForm'

const queryClient = new QueryClient()

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            <Route element={<Layout />}>
              <Route path="/" element={<FeedScreen />} />
              <Route path="/explorer" element={<ExploreScreen />} />
              <Route path="/scan" element={<ScanScreen />} />
              <Route path="/vignerons" element={<VigneronsScreen />} />
              <Route path="/book" element={<BookScreen />} />
              <Route path="/connexion" element={<LoginScreen />} />
            </Route>
            <Route path="/pro" element={<ProLayout />}>
              <Route index element={<ProHome />} />
              <Route path="domaine" element={<DomaineEditScreen />} />
              <Route path="cuvees/:id" element={<WineScreen />} />
            </Route>
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  )
}
