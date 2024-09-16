import { resolve } from 'node:path'
import { defineConfig } from 'vite'
import camelCase from 'camelcase'
import packageJson from './package.json'

const packageName = packageJson.name.split('/').pop() || packageJson.name

export default defineConfig({
  build: {
    modulePreload: {
      polyfill: true
    },
    lib: {
      entry: resolve(__dirname, 'src', 'index.js'),
      formats: ['iife'],
      name: camelCase(packageName, {
        pascalCase: true
      }),
      fileName: packageName
    },
    chunkSizeWarningLimit: 999
  },
  css: {
    preprocessorOptions: {
      scss: {
        api: 'modern-compiler',
        additionalData: `$prefix: zee-;`
      }
    },
    preprocessorMaxWorkers: true
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src')
    }
  }
})