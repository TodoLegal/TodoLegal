# TodoLegal Sitemap Quick Reference

## Current Status (September 2025)
- **Published Documents**: ~24,000
- **Strategy**: Single sitemap (`/api/v1/sitemap.xml`)
- **Performance**: 2.2x speed improvement with caching
- **Transition Point**: 45,000 documents

## Daily Commands

```bash
# Check sitemap status
rails sitemap:cache_stats

# Manual regeneration
rails sitemap:daily_regenerate

# Check growth toward 50K limit
rails runner "puts 'Published: #{Document.where(publish: true).count}/50000'"

# Performance test
rails sitemap:performance_test
```

## Emergency Commands

```bash
# Clear cache if issues
rails sitemap:clear_cache

# Warm cache manually
rails sitemap:warm_cache

# Test performance
rails sitemap:performance_test
```

## Expected Cache Status (After Warming)

```
sitemap_main_documents             : cached     ✅ (24K documents)
sitemap_total_documents_count      : cached     ✅ (document count)  
sitemap_documents_page_1           : cached     ✅ (page 1 data)
sitemap_documents_page_2-10        : not cached ✅ (normal - empty pages)
```

## Performance Benchmarks

```
Performance (1000 documents):
- Without cache: 1657.32ms
- Cached read:   740.86ms  
- Speed improvement: 2.2x faster

Production Estimate (24K documents):
- Without cache: ~40 seconds
- Cached read:   ~18 seconds
- Daily regeneration: Maintains optimal performance
```

## Transition to 50K+ Strategy

### When Published Documents Reach 45,000:

1. **Check current count**:
   ```bash
   rails runner "puts Document.where(publish: true).count"
   ```

2. **Update robots.txt** in React app:
   ```diff
   - Sitemap: https://todolegal.app/api/v1/sitemap.xml
   + Sitemap: https://todolegal.app/api/v1/sitemap_index.xml
   ```

3. **Update Google Search Console**:
   - Remove old sitemap URL
   - Add new sitemap index URL

4. **Test endpoints**:
   ```bash
   curl https://todolegal.app/api/v1/sitemap_index.xml
   curl https://todolegal.app/api/v1/sitemap_documents_1.xml
   ```

## File Locations

```
app/controllers/api/v1/sitemap_controller.rb    # Main controller
app/views/api/v1/sitemap/                       # XML templates  
app/helpers/application_helper.rb               # Helper methods
lib/tasks/sitemap.rake                          # Management tasks
config/schedule.rb                              # Cron configuration
docs/SITEMAP_DOCUMENTATION.md                  # Full documentation
```

## Cron Job

```bash
# Runs daily at 12:00 AM (midnight)
0 0 * * * cd /path/to/app && RAILS_ENV=production bundle exec rake sitemap:daily_regenerate
```

## Monitoring Thresholds

- **35K docs**: Normal monitoring - check monthly
- **40K docs**: ⚠️ Start transition planning - check weekly  
- **45K docs**: 🚨 Execute transition - check daily
- **50K docs**: ❌ Must use sitemap index

**Weekly Growth Check**:
```bash
rails runner "
  published = Document.where(publish: true).count
  puts \"📊 #{published}/50000 published (#{(published.to_f/50000*100).round(1)}%)\"
  puts \"⚠️ Transition at 45K\" if published >= 40000
  puts \"🚀 Performance: 2.2x faster with caching\"
"
```

## Production Status ✅

Your sitemap implementation is **production-ready** with:
- ✅ Efficient database queries
- ✅ Multi-level caching (2.2x speed improvement)  
- ✅ Smart cache warming
- ✅ Robust error handling
- ✅ Scalable architecture for 50K+ documents
- ✅ Daily automated regeneration
