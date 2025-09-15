# TodoLegal Sitemap Implementation Documentation

## Overview

This document provides comprehensive documentation for the TodoLegal sitemap implementation, including setup, usage, monitoring, and scaling strategies for SEO optimization.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Implementation Details](#implementation-details)
3. [Configuration](#configuration)
4. [Usage Instructions](#usage-instructions)
5. [Monitoring and Maintenance](#monitoring-and-maintenance)
6. [Scaling Strategy (50K+ Documents)](#scaling-strategy-50k-documents)
7. [Performance Optimization](#performance-optimization)
8. [Troubleshooting](#troubleshooting)
9. [SEO Best Practices](#seo-best-practices)

---

## Architecture Overview

### Current Status
- **Published Documents**: ~24,000 (growing)
- **Total Documents**: ~35,000
- **Current Strategy**: Single sitemap (`/api/v1/sitemap.xml`)
- **Cache Duration**: 24 hours
- **Regeneration**: Daily at 2:00 AM

### Core Components

```
app/controllers/api/v1/sitemap_controller.rb    # Main controller
app/views/api/v1/sitemap/                       # XML templates
app/helpers/application_helper.rb               # Helper methods
lib/tasks/sitemap.rake                          # Management tasks
config/schedule.rb                              # Cron job configuration
```

---

## Implementation Details

### 1. Controller Actions

#### `GET /api/v1/sitemap.xml` - Main Sitemap
- **Purpose**: Primary sitemap for 0-50,000 documents
- **Cache**: 24 hours
- **Limit**: 50,000 documents
- **Order**: Most recent first (`publication_date DESC, id DESC`)

#### `GET /api/v1/sitemap_index.xml` - Sitemap Index
- **Purpose**: Master sitemap pointing to paginated sitemaps
- **Use When**: 50,000+ documents
- **Cache**: 24 hours

#### `GET /api/v1/sitemap_documents_:page.xml` - Paginated Documents
- **Purpose**: Individual pages of 50,000 documents each
- **Use When**: Used automatically by sitemap index
- **Cache**: 24 hours per page

### 2. Helper Methods

```ruby
# URL Generation
document_sitemap_url(document)     # Full sitemap URL
get_document_type_slug(document)   # Document type slug
get_document_url_slug(document)    # Document URL slug

# SEO Optimization (Currently Simplified)
document_priority(document)        # Returns 0.8 (uniform)
document_changefreq(document)      # Returns 'monthly' (uniform)
```

### 3. URL Structure

TodoLegal sitemap generates URLs in this format:
```
https://valid.todolegal.app/:documentType/honduras/:url/:documentId
```

**Examples**:
```
https://valid.todolegal.app/decreto/honduras/pcm-134-2021/879
https://valid.todolegal.app/ley/honduras/ley-de-transparencia/1234
https://valid.todolegal.app/sentencia/honduras/caso-civil-456/789
```

**URL Generation Priority**:
1. `document.url` (if present)
2. `document.name.parameterize` (if present)  
3. `document.issue_id.parameterize` (if present)
4. `'documento'` (fallback)

---

## Configuration

### 1. Routes Configuration

```ruby
# config/routes.rb
namespace :api, defaults: {format: :json} do
  namespace :v1 do
    # Sitemap routes
    get 'sitemap.xml', to: 'sitemap#index', defaults: { format: 'xml' }
    get 'sitemap_index.xml', to: 'sitemap#sitemap_index', defaults: { format: 'xml' }
    get 'sitemap_documents_:page.xml', to: 'sitemap#documents', defaults: { format: 'xml' }
  end
end
```

### 2. Cron Job Configuration

```ruby
# config/schedule.rb
# Sitemap regeneration - runs daily at 2 AM
every 1.day, at: '2:00 am' do
  rake "sitemap:daily_regenerate"
end
```

### 3. Cache Configuration

- **Storage**: Rails.cache (Redis/Memcached recommended for production)
- **Duration**: 24 hours for all sitemap data
- **Keys**:
  - `sitemap_main_documents`
  - `sitemap_total_documents_count`
  - `sitemap_documents_page_N` (where N is page number)

---

## Usage Instructions

### 1. Development Setup

```bash
# Test sitemap generation
rails sitemap:warm_cache
rails sitemap:cache_stats

# View generated sitemap
curl http://localhost:3000/api/v1/sitemap.xml

# Test daily regeneration
rails sitemap:daily_regenerate
```

### 2. Production Deployment

#### Step 1: Deploy Code
```bash
git push origin main
```

#### Step 2: Set Up Cron Job
```bash
# SSH to production server
ssh user@your-server.com

# Navigate to Rails app
cd /path/to/rails/app

# Install cron job
bundle exec whenever --update-crontab --set environment=production

# Verify installation
crontab -l
```

#### Step 3: Submit to Search Engines

**Add to React app's `public/robots.txt`**:
```
User-agent: *
Allow: /

Sitemap: https://todolegal.app/api/v1/sitemap.xml
```

**Submit to Google Search Console**:
1. Go to Google Search Console
2. Select your property
3. Navigate to Sitemaps
4. Add sitemap URL: `https://todolegal.app/api/v1/sitemap.xml`

---

## Monitoring and Maintenance

### 1. Available Rake Tasks

```bash
# Check cache status
rails sitemap:cache_stats

# Clear cache manually
rails sitemap:clear_cache

# Warm up cache
rails sitemap:warm_cache

# Daily regeneration (automated)
rails sitemap:daily_regenerate

# Performance testing
rails sitemap:performance_test
```

### 2. Monitoring Commands

```bash
# Check document count
rails runner "puts Document.where(publish: true).count"

# Test sitemap accessibility
curl -I https://todolegal.app/api/v1/sitemap.xml

# Check cron job logs
tail -f /var/log/cron  # or appropriate log file

# Monitor growth manually
rails runner "puts 'Published: #{Document.where(publish: true).count}, Total: #{Document.count}'"
```

### 3. Key Metrics to Monitor

- **Published Documents Count**: Check manually - track growth toward 50K limit
- **Sitemap Response Time**: Should be < 1 second with caching
- **Cache Hit Rate**: Monitor cache effectiveness
- **Crawl Errors**: Check Google Search Console

**Manual Growth Monitoring**:
```bash
# Weekly check recommended
rails runner "
  published = Document.where(publish: true).count
  total = Document.count
  puts \"📊 Status: #{published} published / #{total} total (#{(published.to_f/total*100).round(1)}%)\"
  puts \"📈 Progress to 50K limit: #{published}/50000 (#{(published.to_f/50000*100).round(1)}%)\"
"
```

---

## Scaling Strategy (50K+ Documents)

### When to Transition

**Transition Trigger**: When published documents reach **45,000** (safety buffer)

**Manual Monitoring Required**: Check document count regularly:
```bash
# Check current document count
rails runner "puts 'Published: #{Document.where(publish: true).count}/50000'"
```

### Transition Steps

#### Step 1: Update robots.txt
```diff
# In React app's public/robots.txt
- Sitemap: https://todolegal.app/api/v1/sitemap.xml
+ Sitemap: https://todolegal.app/api/v1/sitemap_index.xml
```

#### Step 2: Test New Endpoints
```bash
# Test sitemap index
curl https://todolegal.app/api/v1/sitemap_index.xml

# Test first page
curl https://todolegal.app/api/v1/sitemap_documents_1.xml

# Test second page (if exists)
curl https://todolegal.app/api/v1/sitemap_documents_2.xml
```

#### Step 3: Update Search Engines
1. **Google Search Console**:
   - Remove old sitemap: `sitemap.xml`
   - Add new sitemap: `sitemap_index.xml`

2. **Bing Webmaster Tools**:
   - Same process as Google

#### Step 4: Monitor Transition
```bash
# Verify all pages are being generated
rails sitemap:cache_stats

# Check indexing status in Google Search Console
# Monitor for crawl errors
```

### Post-Transition Architecture

```
sitemap_index.xml
├── sitemap_documents_1.xml (50,000 documents)
├── sitemap_documents_2.xml (remaining documents)
└── sitemap_documents_N.xml (future growth)
```

---

## Performance Optimization

### 1. Caching Strategy

```ruby
# 24-hour cache for all components
@documents = Rails.cache.fetch('sitemap_main_documents', expires_in: 24.hours) do
  Document.where(publish: true)
          .includes(:document_type, :tags, :issuer_document_tags)
          .order(publication_date: :desc, id: :desc)
          .limit(50000)
          .to_a
end
```

### 2. Database Query Optimization

- **Eager Loading**: `includes(:document_type, :tags, :issuer_document_tags)`
- **Indexing**: Ensure indexes on `publish`, `publication_date`, `id`
- **Limit Results**: Respect 50K per sitemap limits

### 3. HTTP Caching

```ruby
# Browser/CDN caching
expires_in 24.hours, public: true
```

### 4. Performance Monitoring

```bash
# Test performance
rails sitemap:performance_test

# Expected results:
# - Without cache: ~300-500ms
# - With cache: <50ms
# - Speed improvement: 10x+ faster
```

---

## Troubleshooting

### Common Issues

#### 1. Sitemap Not Loading
```bash
# Check Rails server status
curl -I https://todolegal.app/api/v1/sitemap.xml

# Check route configuration
rails routes | grep sitemap

# Verify controller exists
ls app/controllers/api/v1/sitemap_controller.rb
```

#### 2. Cache Issues
```bash
# Clear all sitemap cache
rails sitemap:clear_cache

# Regenerate fresh cache
rails sitemap:warm_cache

# Check cache backend
rails runner "puts Rails.cache.class"
```

#### 3. Cron Job Not Running
```bash
# Check crontab
crontab -l

# Check cron service
sudo service cron status

# Check logs
tail -f /var/log/cron
tail -f /path/to/rails/log/cron_log.log
```

#### 4. Memory Issues (Large Document Sets)
```bash
# Monitor memory usage during regeneration
rails sitemap:daily_regenerate

# Consider pagination if memory usage too high
# Reduce includes() if not needed for sitemap
```

### Error Messages and Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| `Sitemap too large` | Over 50K documents in single sitemap | Switch to sitemap index |
| `Cache fetch timeout` | Large dataset, slow query | Optimize database queries |
| `Route not found` | Missing route configuration | Check `config/routes.rb` |
| `Template missing` | Missing XML view | Check `app/views/api/v1/sitemap/` |

---

## SEO Best Practices

### 1. URL Structure
- **Clean URLs**: Use parameterized document types and names
- **Consistent Pattern**: `:documentType/honduras/:url/:documentId`
- **Legal Document Hierarchy**: Organized by document type

### 2. Metadata Optimization
- **Priority**: Currently uniform (0.8) - ready for document type-based prioritization
- **Change Frequency**: Currently uniform (monthly) - ready for content-based frequencies
- **Last Modified**: Accurate timestamps from document updates

### 3. Content Strategy
- **Published Only**: Only include `publish: true` documents
- **Fresh Content**: Daily regeneration ensures current data
- **Complete Coverage**: All published legal documents included

### 4. Future SEO Enhancements

When ready to implement advanced SEO:

```ruby
# Uncomment in application_helper.rb for priority-based optimization
def document_priority(document)
  case document.document_type&.name
  when 'Ley', 'Decreto', 'Constitución'
    0.9  # Highest priority - fundamental legal documents
  when 'Acuerdo', 'Resolución', 'Reglamento'  
    0.8  # High priority - regulatory documents
  when 'Auto Acordado', 'Sentencia'
    0.7  # Medium-high priority - judicial decisions
  when 'Gaceta'
    0.6  # Medium priority - official publications
  else
    0.5  # Default priority
  end
end
```

---

## Maintenance Schedule

### Daily (Automated)
- Cache regeneration at 2:00 AM

### Weekly (Manual)
- Check document growth: `rails runner "puts Document.where(publish: true).count"`
- Check Google Search Console for crawl errors
- Monitor sitemap accessibility
- Review cache performance with `rails sitemap:cache_stats`

### Monthly (Manual)
- Analyze growth trends toward 50K limit
- Review SEO performance  
- Plan for scaling if approaching limits

### As Needed
- Clear cache if data issues: `rails sitemap:clear_cache`
- Update sitemap strategy when approaching 50K documents
- Optimize queries if performance degrades

---

## Support and Contact

For issues with sitemap implementation:

1. Check this documentation first
2. Run diagnostic commands: `rails sitemap:cache_stats`
3. Check logs: `/var/log/cron` and Rails logs
4. Test manually: `rails sitemap:daily_regenerate`

---

**Last Updated**: September 15, 2025  
**Version**: 1.0  
**Document Status**: Production Ready
