import { defineConfig } from 'vite'
import { readFileSync, existsSync, cpSync } from 'fs'
import { resolve } from 'path'

export default defineConfig({
  publicDir: 'public',
  server: {
    fs: {
      allow: ['..'],
    },
  },
  build: {
    outDir: 'dist',
  },
  plugins: [
    {
      name: 'serve-examples',
      configureServer(server) {
        // Dev: serve /examples/* from examples/
        server.middlewares.use('/examples', (req, res, next) => {
          const filePath = resolve(__dirname, 'examples', req.url?.slice(1) || '')
          if (existsSync(filePath)) {
            res.setHeader('Content-Type', 'text/plain; charset=utf-8')
            res.end(readFileSync(filePath, 'utf-8'))
          } else {
            next()
          }
        })
      },
      closeBundle() {
        // Build: copy examples/ to dist/examples/
        cpSync('examples', 'dist/examples', { recursive: true })
        console.log('Copied examples/ to dist/examples/')
      },
    },
  ],
})
