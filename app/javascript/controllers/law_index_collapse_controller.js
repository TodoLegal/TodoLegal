import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="law-index-collapse"
// Handles collapsing/expanding hierarchical index groups deterministically using type-position keys.
// Expected markup:
//  <button data-action="click->law-index-collapse#toggle" data-collapse-group="book-3">...</button>
//  <div class="index-group-book-3"> ... children ... </div>
// The controller finds all elements with class `index-group-<group>` and toggles display.
// Adds ARIA state management to the button (aria-expanded attribute).
export default class extends Controller {
  static targets = []

  toggle(event) {
    const btn = event.currentTarget
    if (!btn) return
    const group = btn.dataset.collapseGroup
    if (!group) return
    const selector = `.index-group-${group}`
    const nodes = document.querySelectorAll(selector)
    if (nodes.length === 0) return

    // Determine new state: if ANY visible -> hide all; else show all.
    const anyVisible = Array.from(nodes).some(n => n.style.display !== 'none')
    const newDisplay = anyVisible ? 'none' : 'block'
    nodes.forEach(n => { n.style.display = newDisplay })

    const expanded = !anyVisible
    btn.setAttribute('aria-expanded', expanded.toString())
    this.dispatchEvent(btn, 'collapse:changed', { group, expanded })
  }

  dispatchEvent(element, name, detail = {}) {
    element.dispatchEvent(new CustomEvent(name, { detail }))
  }
}
