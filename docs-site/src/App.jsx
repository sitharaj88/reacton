import { Routes, Route } from 'react-router-dom'
import Layout from './components/Layout'
import LandingPage from './pages/LandingPage'
import GettingStarted from './pages/GettingStarted'
import CoreConcepts from './pages/CoreConcepts'
import FlutterWidgets from './pages/FlutterWidgets'
import AsyncMiddleware from './pages/AsyncMiddleware'
import Advanced from './pages/Advanced'
import Testing from './pages/Testing'
import Tooling from './pages/Tooling'

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<LandingPage />} />
      <Route element={<Layout />}>
        <Route path="/getting-started" element={<GettingStarted />} />
        <Route path="/core-concepts" element={<CoreConcepts />} />
        <Route path="/flutter-widgets" element={<FlutterWidgets />} />
        <Route path="/async-middleware" element={<AsyncMiddleware />} />
        <Route path="/advanced" element={<Advanced />} />
        <Route path="/testing" element={<Testing />} />
        <Route path="/tooling" element={<Tooling />} />
      </Route>
    </Routes>
  )
}
