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

  // Action: jump to article index provided in articleIndexInput target
  jumpToArticle(event) {
    if (event) event.preventDefault()
    if (this.loadingJump) return
    const value = this.hasArticleIndexInputTarget ? parseInt(this.articleIndexInputTarget.value, 10) : NaN
    if (Number.isNaN(value)) return this.reportFailure('Índice de artículo inválido')
    this.performJump({ kind: 'article', index: value })
  }

  // Action: jump to container specified by type + position
  jumpToContainer(event) {
    if (event) event.preventDefault()
    if (this.loadingJump) return
    if (!this.hasContainerTypeSelectTarget || !this.hasContainerPositionInputTarget) return
    const type = this.containerTypeSelectTarget.value
    const position = parseInt(this.containerPositionInputTarget.value, 10)
    if (!type || Number.isNaN(position)) return this.reportFailure('Datos de estructura inválidos')
    this.performJump({ kind: 'container', type, position })
  }

  // Unified performJump using descriptor pattern
  performJump(descriptor) {
    this.beginJump()
    if (window.MANIFEST_DEBUG) console.debug('[law-jump-navigation] performJump', descriptor)
    if (descriptor.kind === 'container') {
      const { type, position } = descriptor
      const headingId = `${type}_${position}`
      const headingEl = document.getElementById(headingId)
      if (headingEl) {
        this.ensureArticlesTabActive().then(() => {
          if (window.MANIFEST_DEBUG) console.debug('[law-jump-navigation] scrolling to existing container heading', headingId)
          headingEl.scrollIntoView({ block: 'start' })
          try { history.replaceState(null, '', `#${headingId}`) } catch(_) {}
          this.pulseHighlight(headingEl)
          this.finishJump(headingEl)
        })
        return
      }
      // Need chunk: compute from subset
      const firstIdx = ManifestLoader.getFirstArticleIndexForContainer(type, position)
      if (firstIdx == null) return this.failJump(new Error('Rango no disponible'))
      const page = ManifestLoader.computeChunkPageForIndex(firstIdx)
      return this.loadChunkIfNeeded(page)
        .then(() => {
          const el = document.getElementById(headingId)
          if (!el) throw new Error('Encabezado no encontrado tras cargar chunk')
          this.ensureArticlesTabActive().then(() => {
            if (window.MANIFEST_DEBUG) console.debug('[law-jump-navigation] scrolling to loaded container heading', headingId)
            el.scrollIntoView({ block: 'start' })
            try { history.replaceState(null, '', `#${headingId}`) } catch(_) {}
            this.pulseHighlight(el)
            this.finishJump(el)
          })
        })
        .catch(err => this.failJump(err))
    } else if (descriptor.kind === 'article') {
      const { index } = descriptor
      const articleEl = document.getElementById(`article_idx_${index}`)
      if (articleEl) {
        const headingId = articleEl.id
        this.ensureArticlesTabActive().then(() => {
          articleEl.scrollIntoView({ block: 'start' })
          try { history.replaceState(null, '', `#${headingId}`) } catch(_) {}
          this.pulseHighlight(articleEl)
          this.finishJump(articleEl)
        })
        return
      }
      // Need manifest to know chunk page
      ManifestLoader.ensureFull()
        .then(() => ManifestLoader.getArticleMeta(index))
        .then(meta => {
          if (!meta) throw new Error('Artículo no encontrado')
          const page = meta.chunk_page
          return this.loadChunkIfNeeded(page)
            .then(() => document.getElementById(`article_idx_${index}`))
        })
        .then(el => {
          if (!el) throw new Error('Artículo no disponible tras cargar chunk')
          const headingId = el.id
          this.ensureArticlesTabActive().then(() => {
            el.scrollIntoView({ block: 'start', behavior: 'auto' })
            try { history.replaceState(null, '', `#${headingId}`) } catch(_) {}
            this.pulseHighlight(el)
            this.finishJump(el)
          })
        })
        .catch(err => this.failJump(err))
    } else {
      this.failJump(new Error('Descriptor inválido'))
    }
  }

  // Ensure the articles tab is active before performing an operation that depends on it being visible.
  ensureArticlesTabActive() {
    const pane = document.querySelector('#articulos')
    const trigger = document.querySelector('#articulos-tab,[href="#articulos"],[data-bs-target="#articulos"]')
    return new Promise(resolve => {
      if (!pane) return resolve()
      if (pane.classList.contains('active')) return resolve()
      let resolved = false
      const done = () => { if (resolved) return; resolved = true; resolve() }
      if (trigger) {
        const handler = () => { trigger.removeEventListener('shown.bs.tab', handler); done() }
        trigger.addEventListener('shown.bs.tab', handler, { once: true })
        trigger.click()
        setTimeout(done, 600) // fallback
      } else {
        pane.classList.add('active')
        done()
      }
    })
  }

  // Load chunk via endpoint if page not loaded yet
  loadChunkIfNeeded(chunkPage) {
    if (!chunkPage || chunkPage <= this.highestLoadedPage) return Promise.resolve()
    if (window.MANIFEST_DEBUG) console.debug('[law-jump-navigation] loading chunk', { chunkPage, highestLoadedPage: this.highestLoadedPage })
    const lawId = this.lawIdValue || ManifestLoader.lawId()
    if (!lawId) return Promise.reject(new Error('Ley no disponible para cargar chunk'))
    const url = `${this.chunkUrlValue || `/laws/${lawId}/chunk`}?page=${chunkPage}`
    return fetch(url, { headers: { 'Accept': 'text/vnd.turbo-stream.html' } })
      .then(resp => {
        if (!resp.ok) throw new Error(`Error HTTP ${resp.status}`)
        return resp.text()
      })
      .then(html => {
        const template = document.createElement('template')
        template.innerHTML = html.trim()
        template.content.querySelectorAll('turbo-stream').forEach(stream => document.documentElement.appendChild(stream))
        this.highestLoadedPage = Math.max(this.highestLoadedPage, chunkPage)
        if (window.MANIFEST_DEBUG) console.debug('[law-jump-navigation] chunk appended; new highestLoadedPage', this.highestLoadedPage)
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
}
