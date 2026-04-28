import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    host: true, // This allows external access (replaces --host flag)
    port: 5173,
    proxy: {
      '/chat': 'http://localhost:5000' // Keep localhost as backend is on the same server
    }
  }
})
