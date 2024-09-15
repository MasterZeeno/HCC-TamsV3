import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = fileURLToPath(new URL('.', import.meta.url))
const zeeScript = resolve(__dirname, 'bin', 'zee.sh')

console.log(zeeScript)
