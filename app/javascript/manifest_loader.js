// manifest_loader.js
// Phase 2: Client-side manifest handling.
// Responsibilities:
// 1. Parse inline subset (<script id="law-manifest-structure">) for immediate structure availability.
// 2. Fetch full manifest (articles index) lazily from /laws/:id/manifest.json when needed.
// 3. Build fast lookup maps for O(1) navigation: articleByIndex, containersByType, rangesByTypeAndPosition.
// 4. Provide helper APIs (getArticleMeta, getContainerRange).
// 5. Handle version mismatch by refetching.
// NOTE: This module intentionally avoids coupling to DOM rendering of articles.

const ManifestLoader = (() => {
  let subset = null;          // Inline structure subset
  let fullManifest = null;    // Full manifest including articles index
  let articleByIndex = {};    // { global_index: articleMeta }
  let containersByType = {};  // { type: [ { position, range, number, name } ] }
  let rangesByTypeAndPosition = {}; // { type => { position => { first_article_index, last_article_index } } }
  let lawId = null;
  let version = null;
  let loadingFull = false;
  let loadPromise = null;

  // Internal: parse inline subset script tag if present.
  function parseInlineSubset() {
    const tag = document.getElementById('law-manifest-structure');
    if (!tag) return;
    try {
      subset = JSON.parse(tag.textContent);
      lawId = subset.law_id;
      version = subset.version;
      buildStructureIndexes(subset.structure || []);
      // Emit event so late-attached controllers can render after subset becomes available.
      document.dispatchEvent(new CustomEvent('law:manifest:subset', { detail: { lawId } }));
    } catch (e) {
      console.error('[ManifestLoader] Failed to parse inline subset:', e);
      subset = null;
    }
  }

  // Internal: build structure lookup maps for hierarchy navigation.
  function buildStructureIndexes(structureTree) {
    containersByType = {};
    rangesByTypeAndPosition = {};
    const stack = [...structureTree];
    while (stack.length) {
      const node = stack.shift();
      const { type, position, range, number, name, children } = node;
      if (!containersByType[type]) containersByType[type] = [];
      containersByType[type].push({ position, range, number, name });
      if (!rangesByTypeAndPosition[type]) rangesByTypeAndPosition[type] = {};
      rangesByTypeAndPosition[type][position] = range;
      if (children && children.length) stack.push(...children);
    }
    Object.keys(containersByType).forEach(t => {
      containersByType[t].sort((a, b) => a.position - b.position);
    });
  }

  // Fetch full manifest only once; reuse promise for concurrent callers.
  function fetchFullManifest() {
    if (fullManifest) return Promise.resolve(fullManifest);
    if (loadingFull) return loadPromise;
    if (!lawId) return Promise.reject(new Error('Law ID not available; ensure subset parsed.'));
    loadingFull = true;
    const url = `/laws/${lawId}/manifest.json`;
    loadPromise = fetch(url, { headers: { 'Accept': 'application/json' } })
      .then(resp => {
        if (!resp.ok) throw new Error(`Manifest fetch failed: ${resp.status}`);
        return resp.json();
      })
      .then(json => {
        // Version mismatch: rebuild structure indexes if necessary.
        if (version && json.version !== version) {
          console.warn('[ManifestLoader] Version mismatch: refetching structure indexes.');
          buildStructureIndexes(json.structure || []);
          version = json.version;
        }
        console.log("Manifest loaded")
        fullManifest = json;
        buildArticleIndex(fullManifest.articles || []);
        return fullManifest;
      })
      .finally(() => { loadingFull = false; });
    return loadPromise;
  }

  // Internal: build flat article index map.
  function buildArticleIndex(articles) {
    articleByIndex = {};
    for (const a of articles) {
      articleByIndex[a.global_index] = a;
    }
  }

  // Public: ensure full manifest loaded; returns promise resolved with manifest.
  function ensureFull() {
    return fetchFullManifest();
  }

  // Public: get article metadata by global index (lazy load full manifest if absent).
  function getArticleMeta(globalIndex) {
    if (articleByIndex[globalIndex]) return Promise.resolve(articleByIndex[globalIndex]);
    return ensureFull().then(() => articleByIndex[globalIndex] || null);
  }

  // Public: get container range by type + position.
  function getContainerRange(type, position) {
    return (rangesByTypeAndPosition[type] || {})[position] || null;
  }

  // Helper: chunk size from subset or full manifest
  function getChunkSize() {
    return (subset?.chunking?.chunk_size) || (fullManifest?.chunking?.chunk_size) || null;
  }

  // Helper: first article index for container (without full manifest)
  function getFirstArticleIndexForContainer(type, position) {
    const range = getContainerRange(type, position);
    return range?.first_article_index ?? null;
  }

  // Helper: compute chunk page for an article index using chunk size
  function computeChunkPageForIndex(globalIndex) {
    const size = getChunkSize();
    if (!size || globalIndex == null) return null;
    return Math.floor(globalIndex / size) + 1;
  }

  // Public: get container metadata
  function getContainerMeta(type, position) {
    const list = containersByType[type] || [];
    return list.find(c => c.position == position) || null;
  }

  // Initialize immediately on module import.
  parseInlineSubset();

  function ensureSubsetParsed() { if (!subset) parseInlineSubset(); }

  return {
    subsetLoaded: () => { ensureSubsetParsed(); return !!subset; },
    fullLoaded: () => !!fullManifest,
    lawId: () => lawId,
    version: () => version,
    // Expose structure tree (prefer subset; fallback to full manifest)
    getStructureTree: () => { ensureSubsetParsed(); return (subset?.structure) || (fullManifest?.structure) || []; },
    ensureFull,
    getArticleMeta,
    getContainerRange,
    getChunkSize,
    getFirstArticleIndexForContainer,
    computeChunkPageForIndex,
    getContainerMeta
  };
})();

// Expose globally for console debugging (optional). Safe noop on server.
if (typeof window !== 'undefined' && !window.ManifestLoader) {
  window.ManifestLoader = ManifestLoader;
}

export default ManifestLoader;
