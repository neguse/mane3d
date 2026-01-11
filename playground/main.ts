import './style.css'
import { createEditor, getCode, setCode } from './editor'
import { loadGist, saveGist } from './gist'
import { initWasm } from './wasm'

const app = document.querySelector<HTMLDivElement>('#app')!

app.innerHTML = `
  <div class="container">
    <header class="toolbar">
      <button id="run-btn">▶ Run</button>
      <button id="reset-btn">Reset</button>
      <select id="sample-select">
        <option value="">-- Samples --</option>
        <option value="triangle">Triangle</option>
        <option value="raytracer">Raytracer</option>
        <option value="breakout">Breakout</option>
      </select>
      <button id="share-btn">📤 Share</button>
    </header>
    <main class="editor-canvas">
      <div id="editor"></div>
      <div id="canvas-container">
        <canvas id="canvas"></canvas>
      </div>
    </main>
  </div>
`

// Initialize editor
const editorContainer = document.querySelector<HTMLDivElement>('#editor')!
createEditor(editorContainer)

// Button handlers
document.querySelector('#run-btn')?.addEventListener('click', async () => {
  const canvas = document.querySelector<HTMLCanvasElement>('#canvas')!
  console.log('Starting WASM...')
  await initWasm(canvas)
  console.log('WASM ready')
})

document.querySelector('#reset-btn')?.addEventListener('click', () => {
  location.reload()
})

document.querySelector('#share-btn')?.addEventListener('click', async () => {
  const code = getCode()
  const url = await saveGist(code)
  if (url) {
    await navigator.clipboard.writeText(url)
    alert(`URL copied: ${url}`)
  }
})

// Sample selection
document.querySelector('#sample-select')?.addEventListener('change', async (e) => {
  const sample = (e.target as HTMLSelectElement).value
  if (!sample) return
  const res = await fetch(`/examples/${sample}.lua`)
  if (res.ok) {
    setCode(await res.text())
  }
})

// Load from URL params
const params = new URLSearchParams(location.search)
const gistId = params.get('gist')
if (gistId) {
  loadGist(gistId).then((code) => {
    if (code) setCode(code)
  })
}
