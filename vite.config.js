import { resolve } from 'node:path'
import { defineConfig } from 'vite'
import camelCase from 'camelcase'
import packageJson from './package.json'

const packageName = packageJson.name.split('/').pop() || packageJson.name

export default defineConfig({
  build: {
    modulePreload: {
      polyfill: false
    },
    lib: {
      entry: resolve(__dirname, 'src', packageName),
      formats: ['iife'],
      name: camelCase(packageName, {
        pascalCase: true
      }),
      fileName: packageName
    },
    chunkSizeWarningLimit: 999
  }
})