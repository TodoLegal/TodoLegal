import { Controller } from "@hotwired/stimulus"
import ManifestLoader from "../manifest_loader"

// Connects to data-controller="law-jump-navigation"
// Responsibilities:
// - Provide actions to jump to an article index or to the first article of a container (title/chapter/section/subsection,...)
// - Request missing chunk pages before scrolling.
// - Maintain highestLoadedPage state (updated via custom events from infinite scroll controller).
// - Emit lifecycle + result events for optional analytics.
// Assumptions:
// - Chunk endpoint: /laws/:id/chunk?page=<page>
// - Article DOM id pattern: #article_idx_<global_index>
// - law:chunkLoaded event dispatched with detail { page }
// - Manifest subset script already injected (manifest_loader parsed on import)
export default class extends Controller {
  static targets = ["articleIndexInput", "containerTypeSelect", "containerPositionInput", "jumpResult"]
  static values = { lawId: Number, chunkUrl: String, prefetch: Boolean, articlesOnly: Boolean }

  highestLoadedPage = 1
  loadingJump = false

  connect() {
    if (this.hasPrefetchValue && this.prefetchValue) {
      ManifestLoader.ensureFull().catch(() => {})
    }
    // Initialize highestLoadedPage from existing articles (optional heuristic)
    this.bootstrapHighestLoadedPage()

    // Also derive from infinite scroll current page value if present
    const currentPageRaw = this.element.dataset.lawInfiniteScrollCurrentPageValue
    const currentPage = parseInt(currentPageRaw, 10)
    if (!Number.isNaN(currentPage) && currentPage > this.highestLoadedPage) {
      this.highestLoadedPage = currentPage
    }

    // Listen for chunk load events to update page tracking
    document.addEventListener('law:chunkLoaded', this.onChunkLoaded)
  }

  disconnect() {
    document.removeEventListener('law:chunkLoaded', this.onChunkLoaded)
  }

  // Heuristic: infer highest loaded page via data attribute if present.
  bootstrapHighestLoadedPage() {
    const lastChunkMarker = document.querySelector('[data-last-loaded-chunk]')
    if (lastChunkMarker) {
      const page = parseInt(lastChunkMarker.getAttribute('data-last-loaded-chunk'), 10)
      if (!Number.isNaN(page)) this.highestLoadedPage = page
    }
  }

  onChunkLoaded = (ev) => {
    const { page } = ev.detail || {}
    if (page && page > this.highestLoadedPage) {
      this.highestLoadedPage = page
    }
  }

  // Unified performJump using descriptor pattern
  async performJump(descriptor) {
    this.beginJump()
    try {
      if (window.MANIFEST_DEBUG) console.debug('[law-jump-navigation] performJump', descriptor)
      if (descriptor.kind === 'container') {
        // Container jump: resolve heading id and page, load focus window if heading missing.
        const { type, position } = descriptor
        const headingId = `${type}_${position}`
        const firstIdx = ManifestLoader.getFirstArticleIndexForContainer(type, position)
        if (firstIdx == null) throw new Error('Rango no disponible')
        const page = ManifestLoader.computeChunkPageForIndex(firstIdx)
        const headingElInitial = document.getElementById(headingId)
        if (!headingElInitial || page > this.highestLoadedPage + 1) {
          if (window.MANIFEST_DEBUG) console.debug('[law-jump-navigation] focus load for container', { type, position, page })
          await this.enterFocusMode(page)
        }
        await this.ensureArticlesTabActive()
        const headingEl = await this.waitForHeading(headingId)
        if (!headingEl) throw new Error('Encabezado no encontrado')
        this.finalizeJump(headingEl)
        return
      }
      if (descriptor.kind === 'article') {
        const { index } = descriptor
        const id = `article_idx_${index}`
        let el = document.getElementById(id)
        if (!el) {
          await ManifestLoader.ensureFull()
          const meta = ManifestLoader.getArticleMeta(index)
          if (!meta) throw new Error('Artículo no encontrado')
          await this.loadChunkIfNeeded(meta.chunk_page)
        }
        await this.ensureArticlesTabActive()
        el = await this.waitForHeading(id)
        if (!el) throw new Error('Artículo no disponible tras cargar chunk')
        this.finalizeJump(el)
        return
      }
      throw new Error('Descriptor inválido')
    } catch (err) {
      this.failJump(err)
    }
  }

  // Ensure the articles tab is active before performing an operation that depends on it being visible.
  ensureArticlesTabActive() {
    // Memoize in-flight activation to avoid duplicate listeners.
    if (this._articlesTabPromise) return this._articlesTabPromise
    const pane = document.querySelector('#articulos')
    const trigger = document.querySelector('#articulos-tab,[href="#articulos"],[data-bs-target="#articulos"]')
    this._articlesTabPromise = new Promise(resolve => {
      if (!pane) return resolve()
      if (pane.classList.contains('active')) return resolve()
      let settled = false
      const finish = () => { if (settled) return; settled = true; resolve() }
      if (trigger) {
        const handler = () => { trigger.removeEventListener('shown.bs.tab', handler); finish() }
        trigger.addEventListener('shown.bs.tab', handler, { once: true })
        trigger.click()
        setTimeout(finish, 600) // fallback ensures resolution
      } else {
        pane.classList.add('active')
        finish()
      }
    }).finally(() => { this._articlesTabPromise = null })
    return this._articlesTabPromise
  }

  // Load chunk via endpoint if page not loaded yet
  loadChunkIfNeeded(chunkPage) {
    if (!chunkPage || chunkPage <= this.highestLoadedPage) return Promise.resolve()
    if (window.MANIFEST_DEBUG) console.debug('[law-jump-navigation] loading chunk', { chunkPage, highestLoadedPage: this.highestLoadedPage })
    const lawId = this.lawIdValue || ManifestLoader.lawId()
    if (!lawId) return Promise.reject(new Error('Ley no disponible para cargar chunk'))
    const base = this.chunkUrlValue || `/laws/${lawId}/chunk`
    const url = `${base}?page=${chunkPage}&format=turbo_stream`
    return fetch(url, { headers: { 'Accept': 'text/vnd.turbo-stream.html', 'X-Requested-With': 'XMLHttpRequest' } })
      .then(resp => {
        if (!resp.ok) throw new Error(`Error HTTP ${resp.status}`)
        return resp.text()
      })
      .then(html => {
        if (window.Turbo && typeof Turbo.renderStreamMessage === 'function') {
          Turbo.renderStreamMessage(html)
        } else {
          const template = document.createElement('template')
          template.innerHTML = html.trim()
          template.content.querySelectorAll('turbo-stream').forEach(stream => document.documentElement.appendChild(stream))
        }
        this.highestLoadedPage = Math.max(this.highestLoadedPage, chunkPage)
        const detail = { page: chunkPage }
        try {
          this.element.dispatchEvent(new CustomEvent('law:chunkLoaded', { detail }))
          document.dispatchEvent(new CustomEvent('law:chunkLoaded', { detail }))
        } catch(_) {}
        if (window.MANIFEST_DEBUG) console.debug('[law-jump-navigation] chunk processed; new highestLoadedPage', this.highestLoadedPage)
      })
  }

  // Enter focus mode by requesting a window of pages around the target page
  enterFocusMode(centerPage) {
    const lawId = this.lawIdValue || ManifestLoader.lawId()
    if (!lawId) return Promise.reject(new Error('Ley no disponible para modo enfoque'))
    const base = this.chunkUrlValue || `/laws/${lawId}/chunk`
    const params = new URLSearchParams({
      page: centerPage,
      mode: 'focus',
      format: 'turbo_stream'
    })
    const url = `${base}?${params.toString()}`
    return fetch(url, { headers: { 'Accept': 'text/vnd.turbo-stream.html', 'X-Requested-With': 'XMLHttpRequest' } })
      .then(resp => {
        if (!resp.ok) throw new Error(`Error HTTP ${resp.status}`)
        return resp.text()
      })
      .then(html => {
        if (window.Turbo?.renderStreamMessage) {
          Turbo.renderStreamMessage(html)
        } else {
          const template = document.createElement('template')
          template.innerHTML = html.trim()
          template.content.querySelectorAll('turbo-stream').forEach(stream => document.documentElement.appendChild(stream))
        }
        this.highestLoadedPage = Math.max(this.highestLoadedPage, centerPage)
        if (window.MANIFEST_DEBUG) console.debug('[law-jump-navigation] focus mode stream applied', { centerPage })
      })
  }

  // Poll for heading element to appear after Turbo updated DOM.
  // Prevents race where scroll executes before insertion.
  waitForHeading(id, attempts = 20, intervalMs = 50) {
    return new Promise(resolve => {
      let tries = 0
      const tick = () => {
        const el = document.getElementById(id)
        if (el) return resolve(el)
        tries++
        if (tries >= attempts) return resolve(null)
        setTimeout(tick, intervalMs)
      }
      tick()
    })
  }
  
  // Jump lifecycle helpers
  beginJump() {
    this.loadingJump = true
    this.element.classList.add('jump-loading')
    this.dispatch('start')
  }

  finishJump(el) {
    this.loadingJump = false
    this.element.classList.remove('jump-loading')
    this.reportSuccess(el)
    this.dispatch('success', { articleId: el?.id })
  }

  failJump(err) {
    // Keep error logging minimal for visibility without verbose debug noise
    console.error('[law-jump-navigation] jump failed:', err)
    this.loadingJump = false
    this.element.classList.remove('jump-loading')
    this.reportFailure(err.message || 'Fallo desconocido')
    this.dispatch('failure', { error: err.message })
  }

  // Reporting helpers
  reportSuccess(el) {
    if (!this.hasJumpResultTarget) return
    this.jumpResultTarget.innerHTML = `<small class="text-success"><i class="fas fa-check-circle"></i> Navegado a: ${el?.id}</small>`
  }

  reportFailure(message) {
    if (!this.hasJumpResultTarget) return
    this.jumpResultTarget.innerHTML = `<small class="text-danger"><i class="fas fa-exclamation-circle"></i> ${message}</small>`
  }

  // Emit custom event
  dispatch(name, detail = {}) {
    this.element.dispatchEvent(new CustomEvent(`law-jump-navigation:${name}`, { detail }))
  }

  // Generic click handler for índice links
  click(event) {
    const el = event.currentTarget
    if (!el) return
    const cType = el.dataset.containerType
    const cPos = el.dataset.containerPosition
    const aIdx = el.dataset.articleIndex
    if (!cType && !aIdx) return
    event.preventDefault()
    if (cType && cPos) {
      const pos = parseInt(cPos, 10)
      if (!Number.isNaN(pos)) this.performJump({ kind: 'container', type: cType, position: pos })
      return
    }
    if (this.hasArticlesOnlyValue && this.articlesOnlyValue && aIdx) {
      const idx = parseInt(aIdx, 10)
      if (!Number.isNaN(idx)) this.performJump({ kind: 'article', index: idx })
    }
  }

  pulseHighlight(el) {
    if (!el) return
    el.classList.add('jump-pulse')
    setTimeout(() => el.classList.remove('jump-pulse'), 1200)
  }

  // Removed synthetic heading approach per rollback request

  // Finalize jump: unified scroll + history + highlight + finish
  finalizeJump(el) {
    if (!el) return this.failJump(new Error('Elemento no encontrado'))
    el.scrollIntoView({ block: 'start' })
    try { history.replaceState(null, '', `#${el.id}`) } catch(_) {}
    this.pulseHighlight(el)
    this.finishJump(el)
  }

  labelFor(type, number) {
    switch(type) {
      case 'book': return `Libro ${number}`
  case 'title': return `Título ${number}`
      case 'chapter': return `Capítulo ${number}`
      case 'section': return `Sección ${number}`
      case 'subsection': return `Subsección ${number}`
      default: return `${type} ${number}`
    }
  }
}
