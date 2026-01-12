import './style.css'
import { createEditor, getCode, setCode } from './editor'
import { loadGist, saveGist } from './gist'
import { initDocs } from './docs'

const app = document.querySelector<HTMLDivElement>('#app')!

app.innerHTML = `
  <div class="container">
    <header class="toolbar">
      <button id="run-btn">▶ Run (Alt+Enter)</button>
      <select id="sample-select">
        <option value="">-- Samples --</option>
        <option value="triangle">Triangle</option>
        <option value="raytracer">Raytracer</option>
        <option value="breakout">Breakout</option>
      </select>
      <button id="share-btn">📤 Share</button>
      <button id="license-btn">📜 License</button>
    </header>
    <main class="editor-canvas">
      <div id="editor"></div>
      <div id="right-panel">
        <div class="panel-tabs">
          <button class="panel-tab active" data-panel="player">Player</button>
          <button class="panel-tab" data-panel="docs">Docs</button>
        </div>
        <div id="player-panel" class="panel-content active">
          <iframe id="player-frame" src="about:blank"></iframe>
        </div>
        <div id="docs-panel" class="panel-content">
          <div id="docs-container"></div>
        </div>
      </div>
    </main>
  </div>
`

// Initialize editor
const editorContainer = document.querySelector<HTMLDivElement>('#editor')!
createEditor(editorContainer)

// Run function
function runCode() {
  const iframe = document.querySelector<HTMLIFrameElement>('#player-frame')!
  const code = getCode()

  // Listen for player ready message
  const handleMessage = (e: MessageEvent) => {
    if (e.data.type === 'playerReady') {
      iframe.contentWindow?.postMessage({ type: 'setCode', code }, '*')
      window.removeEventListener('message', handleMessage)
    }
  }
  window.addEventListener('message', handleMessage)

  // Load player
  iframe.src = '/player.html'
  console.log('Starting WASM in iframe...')
}

// Button handlers
document.querySelector('#run-btn')?.addEventListener('click', runCode)

// Alt+Enter to run
document.addEventListener('keydown', (e) => {
  if (e.altKey && e.key === 'Enter') {
    e.preventDefault()
    runCode()
  }
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
    runCode()
  }
})

// License button
document.querySelector('#license-btn')?.addEventListener('click', async () => {
  const res = await fetch('/examples/license.lua')
  if (res.ok) {
    setCode(await res.text())
    runCode()
  }
})

// Load from URL params or default to triangle
const params = new URLSearchParams(location.search)
const gistId = params.get('gist')
if (gistId) {
  loadGist(gistId).then((code) => {
    if (code) setCode(code)
  })
} else {
  // Load default sample (raytracer) and run
  fetch('/examples/raytracer.lua')
    .then(res => res.ok ? res.text() : Promise.reject('Failed to load'))
    .then(code => {
      setCode(code)
      runCode()
    })
    .catch(() => setCode('-- Failed to load default example'))
}

// Tab switching
let docsInitialized = false
document.querySelectorAll('.panel-tab').forEach(tab => {
  tab.addEventListener('click', async () => {
    const panel = (tab as HTMLElement).dataset.panel!

    // Update tab active state
    document.querySelectorAll('.panel-tab').forEach(t => t.classList.remove('active'))
    tab.classList.add('active')

    // Update panel visibility
    document.querySelectorAll('.panel-content').forEach(p => p.classList.remove('active'))
    document.getElementById(`${panel}-panel`)?.classList.add('active')

    // Lazy init docs
    if (panel === 'docs' && !docsInitialized) {
      docsInitialized = true
      const docsContainer = document.getElementById('docs-container')
      if (docsContainer) {
        await initDocs(docsContainer)
      }
    }
  })
})
