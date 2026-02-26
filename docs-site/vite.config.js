import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  base: '/flutter_statemanagement/',
  build: {
    outDir: '../docs',
    emptyOutDir: true,
  },
})
