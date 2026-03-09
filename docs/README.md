# TodoLegal Documentation Hub

**Last Updated:** February 2026  
**Purpose:** Central navigation for TodoLegal technical documentation

---

## 🎯 Law Display & Search (Core Epic)

### [LAW_DISPLAY_OPTIMIZATION.md](performance_optimizations/LAW_DISPLAY_OPTIMIZATION.md) — **START HERE**
Unified reference for the law display performance epic: service architecture, chunked loading, Turbo Streams, focus mode, manifest system, search optimization, and production results. Covers everything from the original monolithic `get_raw_law` refactor through progressive loading.

**Key results:**
- Page load: 5,762 ms → 556 ms (90% improvement)
- Search SQL: 8,763 ms → 11 ms (99% improvement)

### [SYSTEM_ARCHITECTURE.md](performance_optimizations/SYSTEM_ARCHITECTURE.md)
Visual companion to the above — Mermaid diagrams for service layer, request flows, database schema, and the stream-building algorithm.

### Search Performance Deep-Dives
- [SEARCH_POR_R1.md](performance_optimizations/SEARCH_POR_R1.md) — Round 1: N+1 query elimination, Stripe API caching, view rendering (88% faster)
- [SEARCH_POR_R2.md](performance_optimizations/SEARCH_POR_R2.md) — Round 2: GIN index + materialized tsvector (99% SQL improvement)

---

## 🛡️ Security

### [BOT_PROTECTION_IMPLEMENTATION.md](BOT_PROTECTION_IMPLEMENTATION.md)
Multi-layer bot defense: Rack::Attack, honeypots, email validation, name detection. Includes deployment checklist and monitoring.

---

## 📄 Document Processing

### [DOCUMENT_PROCESSING_JOB.md](document_processing_job/DOCUMENT_PROCESSING_JOB.md)
Full implementation guide for DocumentProcessingJob — architecture, error handling, configuration, monitoring.

### [DOCUMENT_PROCESSING_QUICK_REFERENCE.md](document_processing_job/DOCUMENT_PROCESSING_QUICK_REFERENCE.md)
Emergency troubleshooting: stuck jobs, health checks, deployment checklists.

### [DOCUMENT_PROCESSING_PERFORMANCE_ANALYSIS.md](document_processing_job/DOCUMENT_PROCESSING_PERFORMANCE_ANALYSIS.md)
Sept 16th incident analysis — timeline, root cause, before/after metrics.

### [DOCUMENT_BATCH_PROCESSING.md](DOCUMENT_BATCH_PROCESSING.md)
Batch processing workflows and operations.

### [DOCUMENT_RELATIONSHIPS_DOCUMENTATION.md](DOCUMENT_RELATIONSHIPS_DOCUMENTATION.md)
Document relationship system architecture.

---

## 🗺️ Sitemap

- [SITEMAP_DOCUMENTATION.md](sitemap/SITEMAP_DOCUMENTATION.md) — Full implementation guide (50K+ docs, SEO)
- [SITEMAP_QUICK_REFERENCE.md](sitemap/SITEMAP_QUICK_REFERENCE.md) — Commands, thresholds, emergency procedures

---

## ⚡ Other Performance Work

- [GAZETTE_PERFORMANCE_OPTIMIZATION.md](performance_optimizations/GAZETTE_PERFORMANCE_OPTIMIZATION.md) — Gazette loading optimization


---

## 📚 Other

- [NOTIFICATION_RESCHEDULING.md](NOTIFICATION_RESCHEDULING.md) — Notification scheduling and management
- [rails_guide.md](rails_guide.md) — Rails development reference

