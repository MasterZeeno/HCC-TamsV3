import { resolve } from 'node:path'
import { defineConfig } from 'vite'
import camelCase from 'camelcase'
import packageJson from './package.json'

const packageName = packageJson.name.split('/').pop() || packageJson.name
const srcFolder = resolve(__dirname, 'src')
const assetsFolder = resolve(srcFolder, 'assets')

export default defineConfig({
  build: {
    modulePreload: {
      polyfill: true
    },
    lib: {
      entry: resolve(srcFolder, 'index.js'),
      formats: ['iife'],
      name: camelCase(packageName, {
        pascalCase: true
      }),
      fileName: packageName
    },
    chunkSizeWarningLimit: 999
  },
  resolve: {
    alias: {
      '@': srcFolder,
      '+': assetsFolder
    }
  }
})