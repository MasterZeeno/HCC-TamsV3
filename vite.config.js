import { defineConfig } from 'vite'

export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        entryFileNames: 'assets/[name].[ext]',
        chunkFileNames: 'assets/[name]-[hash].[ext]',
        assetFileNames: 'assets/[name].[ext]'
      }
    },
    minify: 'esbuild',
    cssMinify: 'esbuild'
  }
})