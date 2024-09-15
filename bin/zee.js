#!/usr/bin/env node

import { exec, spawn } from "child_process"
import { resolve, dirname } from "node:path"
import { fileURLToPath } from "node:url"

const __dirname = fileURLToPath(new URL(".", import.meta.url))
const pkgJsonPath = resolve(__dirname, "../package.json")
const zee = resolve(__dirname, "zee.sh")
const args = process.argv.slice(2)

const run = (script, args=[]) => {
  args = Array.isArray(args) ? args : [args]
  
  const runner = spawn('bash', [script, ...args])
  
  runner.stdout.on('data', (data) => {
    console.log(`Output: ${data}`)
  })
  
  runner.stderr.on('data', (data) => {
    console.error(`Error: ${data}`)
  })
  
  runner.on('close', (code) => {
    console.log(`Process exited with code ${code}`)
  })
}

const command = args.shift()

switch (command) {
  case "push:g":
    run(zee, ["push:p:g", pkgJsonPath])
    break
    
  case "push:n":
    run(zee, ["push:p:n", pkgJsonPath])
    break

  default:
    run(`chmod +x ${zee}`)
}
