import { defineConfig } from 'vite'
import { fileURLToPath } from 'url'
import path from 'path'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        entryFileNames: 'assets/index.min.js',
        chunkFileNames: 'assets/[name]-[hash].js',
        assetFileNames: ({ name }) => {
          if (name && name.endsWith('.css')) {
            return 'assets/styles.min.css'
          }
          return 'assets/[name].[ext]'
        }
      }
    },
    minify: 'esbuild',
    cssMinify: 'esbuild',
    sourcemap: 'hidden'
  }
})