import { defineConfig } from 'vite'

export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks: () => 'index.min.js',
        entryFileNames: 'assets/index.min.js'
      }
    },
    minify: 'esbuild',
    cssCodeSplit: false,
    chunkSizeWarningLimit: 999
  }
})