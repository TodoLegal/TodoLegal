# Law Display Optimization

**Last Updated:** February 2026  
**Status:** ✅ Complete & In Production  
**Test Law:** Código Civil (2,369 articles — largest law in system)

---

## 1. Summary

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| **Total page load** (production) | 5,762ms | 556ms | **90.3% faster** |
| **Controller execution** | 5,577ms | 424ms | **92.4% faster** |
| **User-perceived load** | ~7s | ~2s | **~70% faster** |

**Before (Oct 21, 2025):** A monolithic controller method loaded ALL 2,369 articles at once.  
**After (Nov 25, 2025):** A service layer loads 100 articles per chunk via Turbo Streams + infinite scroll.

Production profiling data: `performance_reports/sprint_mejoras_performance/law_view/`

---

## 2. What Changed

Two phases, both complete:

**Phase 1 — Service Architecture** (Oct 2025)  
Replaced a 200+ line `get_raw_law` controller method with a modular service layer. No performance change; this was the prerequisite for Phase 2.

**Phase 2 — Chunked Loading + Hotwire** (Nov 2025)  
Implemented progressive loading: first 100 articles render immediately, the rest load on scroll via Turbo Streams. Also added a manifest system for client-side navigation and a focus mode for deep linking.

---

## 3. Architecture

### Service Layer

```
Controller (get_raw_law, 25 lines)
  └─ LawDisplayService.call(law, user, params)
       ├─ Determines request type: normal / search / article filter / focus
       ├─ Loads structure components (books, titles, chapters, sections, subsections)
       ├─ Loads chunked articles (LIMIT 100 OFFSET N)
       ├─ Filters structure to match current chunk
       ├─ LawStreamBuilder.build → interleaved HTML stream
       └─ Returns ServiceResult (success/failure with data + metadata)
```

### Key Files

| File | Lines | Responsibility |
|------|-------|----------------|
| `app/services/law_display_service.rb` | 546 | Main orchestrator: routing, loading, filtering, access control |
| `app/services/law_stream_builder.rb` | 258 | Position-based interleaving of structure headings + articles |
| `app/services/service_result.rb` | 85 | Standardized success/failure result pattern |
| `app/services/application_service.rb` | 55 | Base class providing `.call` interface + `success`/`failure` helpers |
| `app/services/concerns/law_display_config.rb` | 60 | Constants: chunk sizes, access limits, search config |
| `app/services/laws/manifest_builder.rb` | 230 | Builds hierarchical manifest for client-side navigation |
| `app/services/laws/manifest_cache.rb` | 80 | Cache layer for manifests (inline subset, full, flat structure) |
| `app/jobs/warm_law_manifest_job.rb` | 30 | Background job to warm caches after law create/update |

### Controller Integration

| Controller | Action | Purpose |
|------------|--------|---------|
| `ApplicationController` | `get_raw_law` | Calls `LawDisplayService`, extracts result into instance variables |
| `LawsController` | `show` | Initial page: calls `get_raw_law`, renders HTML + inline manifest subset |
| `LawsController` | `load_chunk` | AJAX: returns Turbo Stream with next chunk (or focus mode replacement) |
| `LawsController` | `manifest` | JSON: returns full manifest for client-side navigation |

### Frontend

| File | Purpose |
|------|---------|
| `app/javascript/controllers/law_infinite_scroll_controller.js` | Stimulus: IntersectionObserver triggers chunk loading, retry logic |
| `app/javascript/controllers/manifest_loader.js` | Client-side manifest parsing, O(1) container/article position lookups |
| `app/views/laws/_law_chunk.html.erb` | Turbo Stream partial: renders articles + structure headings |
| `app/views/laws/_focus_toolbar.html.erb` | Focus mode UI: "Ver ley completa" button |
| `app/views/laws/_loading_state.html.erb` | Loading indicator for infinite scroll |

### Routes

```ruby
resources :laws do
  get :load_chunk, path: 'chunk', on: :member   # Turbo Stream chunk endpoint
  get :manifest, on: :member                      # JSON manifest endpoint
end
```

---

## 4. How Chunked Loading Works

### Initial Request (`GET /laws/:id`)

1. `LawsController#show` sets `@manifest_subset` (inline JSON for JavaScript)
2. Calls `get_raw_law` → `LawDisplayService.call(@law, user, params)`
3. Service loads page 1:
   - All structure components via DB queries (books, titles, chapters, sections, subsections)
   - First 100 articles: `articles.order(:position).limit(100).offset(0)`
   - Filters structure cumulatively (all headings up to article 100's position)
4. `LawStreamBuilder` interleaves structure + articles by position
5. Returns HTML with Turbo metadata and chunk pagination state

### Subsequent Chunks (`GET /laws/:id/chunk?page=N`)

1. Stimulus controller detects scroll near bottom (IntersectionObserver, 200px margin)
2. Fetches `Accept: text/vnd.turbo-stream.html`
3. Service loads page N:
   - Same structure (from DB or cache)
   - Articles for page N: `articles.order(:position).limit(100).offset((N-1)*100)`
   - Filters structure to **only NEW headings** within this chunk's position range
4. Turbo Stream response:
   - **Appends** chunk to `#law-stream-content`
   - **Replaces** `#loading-indicator` with updated state (or "all loaded" message)
5. Stimulus re-attaches IntersectionObserver to new loading trigger

### Chunk Sizing

```ruby
# app/services/concerns/law_display_config.rb
CHUNK_SIZES = { search: 100, normal: 100, mobile: 50 }
```

### Structure Filtering Logic

```ruby
# Page 1: cumulative — all structure up to max article position
#   → So the índice sidebar can render the full hierarchy upfront
# Page 2+: delta only — new headings within [min_position, max_position]
#   → Minimizes redundant DOM inserts
```

---

## 5. Focus Mode

When a user jumps to a deep section (from the índice or a direct article link), focus mode loads a ±1 page window around the target instead of forcing the user to scroll from page 1.

### How It Triggers

**Container jump** (from índice):  
`GET /laws/:id/chunk?page=15&mode=focus`  
→ Loads pages [14, 15, 16] with cumulative structure

**Single article lookup** (from URL or search):  
`GET /laws/:id?articles=1545`  
→ Uses manifest to find article's chunk page, builds window around it

### Implementation

```ruby
# LawDisplayService#process_focus_window_request
window_pages = [center_page - 1, center_page, center_page + 1]
  .select { |p| p >= 1 && p <= total_pages }
articles = window_pages.flat_map { |p| load_articles_for_page(p) }
```

Both paths:
- Set `has_more_chunks: false` (disables infinite scroll)
- Set `focus_mode: true`
- Render focus toolbar with "Ver ley completa" link instead of loading indicator
- Turbo Stream **replaces** `#law-stream-content` (not append)

---

## 6. Manifest System

The manifest provides client-side JavaScript with the data needed for O(1) navigation lookups, so jumping to a container or article doesn't require a server round-trip to figure out which page to request.

### ManifestBuilder Output

```ruby
# Laws::ManifestBuilder.build(law) returns:
{
  law_id: 81,
  version: "2025-11-25T09:00:00Z",       # law.updated_at for cache invalidation
  chunking: {
    chunk_size: 100,
    total_articles: 2369,
    total_pages: 24
  },
  structure: [                             # Recursive tree
    { type: "book", position: 1, number: "1", name: "De las Personas",
      range: { first_article_index: 0, last_article_index: 500 },
      children: [
        { type: "title", position: 1, ... , children: [...] }
      ]
    }
  ],
  articles: [                              # Flat index for O(1) lookups
    { global_index: 0, article_number: "1", position: 1, chunk_page: 1,
      structure_path: [{ type: "book", position: 1 }, ...] }
  ]
}
```

### Cache Layers

| Method | TTL | Contents | Used By |
|--------|-----|----------|---------|
| `ManifestCache.inline_subset(law)` | 12h | Structure tree + chunking metadata | Inline JSON in initial HTML for JS |
| `ManifestCache.full(law)` | 6h | Structure + article index | Article lookups, navigation jumps |
| `ManifestCache.flat_structure(law)` | 12h | Pre-computed flat arrays | `LawDisplayService` structure loading |

Cache keys include `law.updated_at`, so any law edit auto-invalidates.

### Background Warming

```ruby
# app/models/law.rb
after_commit :warm_manifest_cache, on: [:create, :update]
# → WarmLawManifestJob.perform_later(id)
#   Warms inline_subset, flat_structure, and full manifest
```

### Client-Side (`manifest_loader.js`)

Parses the inline subset on page load. Provides:
- `computeChunkPageForIndex(globalIndex)` → which page to fetch
- `getContainerRange(type, position)` → first/last article index
- `getFirstArticleIndexForContainer(type, position)` → jump target

Lazy-fetches the full manifest (`/laws/:id/manifest.json`) only when needed (article number lookup not resolvable from subset).

---

## 7. Database

### Schema (Relevant Tables)

**articles:**
```
number    string    — display number ("1", "23-A", "Artículo Final")
body      text      — article content (Markdown)
body_tsv  tsvector  — materialized search vector (auto-updated by trigger)
position  integer   — global ordering within law
law_id    integer   — FK to laws
```

**Structure tables** (books, titles, chapters, sections, subsections):
```
number    string    — display number
name      string    — display name
position  integer   — ordering within law
law_id    integer   — FK to laws
```

### Indexes

```
articles:
  index_articles_on_body_tsv_gin  (GIN)    — full-text search
  index_articles_on_law_id        (B-tree) — law filtering + chunk loading
  index_articles_on_number        (B-tree) — article lookup
  index_articles_on_position      (B-tree) — sorting, chunking
```

> **Missing composite index:** `(law_id, position)` would improve chunk queries. Currently separate indexes exist for `law_id` and `position` individually.

### Article Number Divergence

Display numbers may not match linear positions: "23-A", "23-B", "4-Bis", "Artículo Final", repealed gaps. The manifest's `articles` index handles this by mapping `article_number → global_index → chunk_page`.

---

## 8. Request Flows (Quick Reference)

### Normal Display
```
GET /laws/:id
  → LawsController#show
    → get_raw_law → LawDisplayService.call
      → Load structure (DB queries)
      → Load articles page 1 (LIMIT 100 OFFSET 0)
      → Filter structure (cumulative)
      → LawStreamBuilder.build (interleave by position)
    → Render HTML + inline manifest
```

### Infinite Scroll
```
Stimulus: IntersectionObserver fires
  → GET /laws/:id/chunk?page=2 (Accept: turbo-stream)
    → LawsController#load_chunk
      → LawDisplayService.call(page: 2)
        → Load articles (LIMIT 100 OFFSET 100)
        → Filter structure (delta: only new headings)
        → LawStreamBuilder.build
      → Turbo: append to #law-stream-content
```

### Focus Mode
```
GET /laws/:id/chunk?page=15&mode=focus
  → LawDisplayService: process_focus_window_request
    → Load pages [14, 15, 16]
    → Cumulative structure up to max position
    → LawStreamBuilder.build
  → Turbo: replace #law-stream-content + show focus toolbar
```

### Article Lookup
```
GET /laws/:id?articles=1545
  → LawDisplayService: process_single_article_request
    → Find article by number
    → ManifestCache.article_by_position → get global_index
    → Calculate center page, build ±1 window
    → Render with go_to_article scroll target
```

### Search
```
GET /laws/:id?query=justicia
  → LawDisplayService: process_search_request
    → Article.search_by_body_highlighted("justicia")
      → body_tsv @@ plainto_tsquery → GIN index (11ms)
    → Return highlighted results sorted by position
```

---

## 9. Performance Data

### Production Measurements (Código Civil, 2,369 articles)

**Before** (Oct 21, 2025 — monolithic, loading all articles):
```
Total:     5,762.7ms
Execution: 5,577.6ms (laws#show)
SQL:       210.4ms (132 queries)
Rendering: ~185ms
```

**After** (Nov 25, 2025 — chunked, 100 articles per page):
```
Total:     556.5ms
Execution: 424.0ms (laws#show)
SQL:       210.2ms (133 queries)
Rendering: ~132ms
```

**Key insight:** SQL time stayed roughly the same (~210ms) because the bottleneck was never the database — it was loading and interleaving 2,369 articles in Ruby memory. Chunking to 100 articles eliminated that overhead.

### Phase 1 Baseline (Dev Environment, Oct 29, 2025)

```
Full law display (no search): 52,617ms
Search query "contrato":      184ms (152 matching articles)
```

Phase 1 was slower than pre-refactor in dev because it added service layer overhead without chunking. This confirmed chunking was the critical optimization.

---

## 10. Access Control

```ruby
# LawDisplayService
if @user.nil?
  display_data[:stream] = display_data[:stream].take(5)  # Basic limit
  display_data[:user_can_access_law] = false
end

# Controller (additional check)
if !@user_can_access_law && @stream.respond_to?(:take)
  @stream = @stream.take(5)
end
```

Law access levels (from `law_access` model):
- **Pro**: Requires paid subscription
- **Básica**: Requires any logged-in user
- **Default**: Accessible to all, limited to 5 articles for anonymous users

---

## 11. Future Enhancements

| Enhancement | Expected Impact | Complexity |
|-------------|----------------|------------|
| **Structure caching** — Cache flat structure arrays in `ManifestCache.flat_structure` to avoid DB queries on every request | Eliminate 5 DB queries per page load | Low |
| **Composite DB index** — Add `(law_id, position)` composite index on articles | Faster chunk queries | Low |
| **Chunk response caching** — Cache rendered Turbo Stream HTML per chunk | -200-300ms per chunk | Medium |
| **Chunk prefetching** — Preload next page before user scrolls to bottom | Eliminate perceived latency | Medium |
| **Keyset pagination** — Replace OFFSET with `WHERE position > last` for very large laws | Better performance at high page numbers | Medium |
| **Server streaming** — HTTP/2 push or SSE for chunk delivery | Reduce request overhead | High |

---

## 12. Appendix: Service Result Pattern

All services return `ServiceResult` objects:

```ruby
result = LawDisplayService.call(@law, user: current_user, params: params)

if result.success?
  display_data = result.data      # Hash with :stream, :chunk_metadata, etc.
  metadata = result.metadata      # Hash with :law_id, :total_articles, etc.
else
  error = result.error_message    # String
end
```

This provides consistent error handling across the entire service layer. The controller never sees raw exceptions — only structured success/failure results with safe defaults on failure.
