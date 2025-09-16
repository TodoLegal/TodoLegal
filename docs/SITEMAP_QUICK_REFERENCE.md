# TodoLegal Sitemap Quick Reference

## Current Status (September 2025)
- **Published Documents**: ~24,000
- **Strategy**: Single sitemap (`/api/v1/sitemap.xml`)
- **Transition Point**: 45,000 documents

## Daily Commands

```bash
# Check sitemap status
rails sitemap:cache_stats

# Manual regeneration (if needed)
rails sitemap:daily_regenerate

# Check growth toward 50K limit
rails runner "puts 'Published: #{Document.where(publish: true).count}/50000'"
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
"
```
