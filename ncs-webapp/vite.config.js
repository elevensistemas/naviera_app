import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import basicSsl from '@vitejs/plugin-basic-ssl'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), basicSsl()],
  server: {
    host: true,
    port: 2223,
    strictPort: true,
    allowedHosts: ['falling-alfred-powerful-literacy.trycloudflare.com', '.trycloudflare.com', '.loca.lt'],
    proxy: {
      '/ezviz-api': {
        target: 'https://open.ezvizlife.com',
        changeOrigin: true,
        secure: false,
        rewrite: (path) => path.replace(/^\/ezviz-api/, '')
      },
      '/centinela-api': {
        target: 'https://192.168.2.121:5073',
        changeOrigin: true,
        secure: false,
        rewrite: (path) => path.replace(/^\/centinela-api/, '')
      },
      '/api/v1': {
        target: 'https://navieracruzdelsur.dyndns.org:6570',
        changeOrigin: true,
        secure: false
      }
    }
  }
})
