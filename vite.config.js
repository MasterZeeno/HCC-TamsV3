import { defineConfig } from 'vite'

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