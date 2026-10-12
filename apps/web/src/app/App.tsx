import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter, Route, Routes } from 'react-router-dom'
import { Layout } from './Layout'
import { FeedScreen } from '../features/feed/FeedScreen'
import { ExploreScreen } from '../features/explore/ExploreScreen'
import { ScanScreen } from '../features/scan/ScanScreen'
import { VigneronsScreen } from '../features/domaine/VigneronsScreen'
import { BookScreen } from '../features/book/BookScreen'

const queryClient = new QueryClient()

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route element={<Layout />}>
            <Route path="/" element={<FeedScreen />} />
            <Route path="/explorer" element={<ExploreScreen />} />
            <Route path="/scan" element={<ScanScreen />} />
            <Route path="/vignerons" element={<VigneronsScreen />} />
            <Route path="/book" element={<BookScreen />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  )
}
