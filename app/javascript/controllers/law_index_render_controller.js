import { Controller } from "@hotwired/stimulus"
import ManifestLoader from "manifest_loader"

// Connects to data-controller="law-index-render"
// Renders full hierarchical índice (books, titles, chapters, sections, subsections) from manifest subset.
// Falls back to no-op when articles-only mode is active.
// Markup strategy:
//  - Each container node produces a card-header with anchor + optional collapse button.
//  - Children wrapped in a div.index-group-<type>-<position> with data-group-parent pointing to parent key.
//  - Collapse controller (law-index-collapse) toggles these group wrappers.
//  - Anchor attributes data-container-type / data-container-position used by law-jump-navigation.
//  - Initial state: top-level nodes visible; descendants hidden (display:none) until expanded.
export default class extends Controller {
  static targets = ["root"]
  static values = { articlesOnly: Boolean }

  connect() {
    if (this.hasArticlesOnlyValue && this.articlesOnlyValue) return // Do nothing in articles-only mode.
    if (!this.hasRootTarget) return
    // Avoid duplicate rendering if Turbo re-attaches
    if (this.rootTarget.dataset.rendered === 'true') return
    const rendered = this.renderIndex()
    if (!rendered) {
      // Wait for manifest subset event then attempt again
      this._subsetHandler = () => {
        if (this.rootTarget.dataset.rendered === 'true') return
        this.renderIndex()
      }
      document.addEventListener('law:manifest:subset', this._subsetHandler)
    }
  }

  disconnect() {
    if (this._subsetHandler) {
      document.removeEventListener('law:manifest:subset', this._subsetHandler)
      this._subsetHandler = null
    }
  }

  renderIndex() {
    const structure = ManifestLoader.getStructureTree() || []
    if (!Array.isArray(structure) || structure.length === 0) return false
    const frag = document.createDocumentFragment()
    structure.forEach(node => frag.appendChild(this.buildNode(node, null)))
    this.rootTarget.appendChild(frag)
    this.rootTarget.dataset.rendered = 'true'
    return true
  }

  buildNode(node, parentKey) {
    const { type, position, number, name, children } = node
    const key = `${type}-${position}`
    const wrapper = document.createElement('div')
    // Card header
    const card = document.createElement('div')
    card.className = `card-header ${type}-element index-element`
    card.setAttribute('data-group', key)

    const section = document.createElement('section')
    section.className = `index-${type}`
    section.style.whiteSpace = 'nowrap'

    const anchor = document.createElement('a')
    anchor.className = 'uncolored_link'
    anchor.href = `#${type}_${position}`
    anchor.dataset.action = 'click->law-jump-navigation#click'
    anchor.dataset.containerType = type
    anchor.dataset.containerPosition = position
    anchor.setAttribute('aria-controls', 'articulos')
    anchor.setAttribute('aria-selected', 'true')

    // Label text based on type
    const labelSpan = document.createElement('span')
    labelSpan.textContent = this.labelFor(type, number)
    anchor.appendChild(labelSpan)

    if (name) {
      const nameSpan = document.createElement(type === 'book' ? 'h4' : 'span')
      nameSpan.className = this.nameClassFor(type)
      nameSpan.textContent = name
      anchor.appendChild(nameSpan)
    }

    section.appendChild(anchor)

    // Collapse button only if children
    if (children && children.length) {
      const btn = document.createElement('button')
      btn.type = 'button'
      btn.id = `btn-collapse-${key}`
      btn.className = 'btn btn-light btn-collapse'
      btn.dataset.action = 'click->law-index-collapse#toggle'
      btn.dataset.collapseGroup = key
      btn.setAttribute('aria-expanded', 'true')
      btn.setAttribute('aria-controls', `index-group-${key}`)
      btn.innerHTML = '<i class="fas fa-chevron-down"></i>'
      section.appendChild(btn)
    }

    card.appendChild(section)
    wrapper.appendChild(card)

    // Children group wrapper
    if (children && children.length) {
      const group = document.createElement('div')
      group.className = `index-group-${key}`
      if (parentKey) group.dataset.groupParent = parentKey
      // Hidden by default except top-level (no parent)
      group.style.display = parentKey ? 'none' : 'block'
      children.forEach(child => group.appendChild(this.buildNode(child, key)))
      wrapper.appendChild(group)
    }

    return wrapper
  }

  labelFor(type, number) {
    switch(type) {
      case 'book': return `Libro ${number}`
      case 'title': return `Titulo ${number}` // original spelling retained
      case 'chapter': return `Capítulo ${number}`
      case 'section': return `Sección ${number}`
      case 'subsection': return `Sección ${number}` // legacy label kept
      default: return `${type} ${number}`
    }
  }

  nameClassFor(type) {
    switch(type) {
      case 'book': return 'title--libro'
      case 'title': return 'index-title-name'
      case 'chapter': return 'index-chapter-name'
      case 'section': return 'index-subsection-name'
      case 'subsection': return 'index-subsection-name'
      default: return ''
    }
  }
}
