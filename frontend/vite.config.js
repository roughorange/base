import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',  // Expose on all network interfaces
    port: 3000        // Specify the port (3000 is typical for Vite)
  }
})
