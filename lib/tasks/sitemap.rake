namespace :sitemap do
  desc "Clear sitemap cache"
  task clear_cache: :environment do
    puts "Clearing sitemap cache..."
    Api::V1::SitemapController.clear_cache
    puts "✓ Sitemap cache cleared successfully!"
  end
  
  desc "Show sitemap cache statistics"
  task cache_stats: :environment do
    puts "Sitemap Cache Statistics:"
    puts "=" * 40
    
    stats = Api::V1::SitemapController.cache_stats
    stats.each do |key, status|
      puts "#{key.ljust(35)}: #{status}"
    end
    
    puts "\nTotal published documents: #{Document.where(publish: true).count}"
  end
  
  desc "Warm up sitemap cache"
  task warm_cache: :environment do
    puts "Warming up sitemap cache (24-hour duration)..."
    
    # Warm up main sitemap
    puts "- Warming main sitemap cache..."
    Rails.cache.fetch('sitemap_main_documents', expires_in: 24.hours) do
      Document.where(publish: true)
              .includes(:document_type, :tags)
              .order(publication_date: :desc, id: :desc)
              .limit(50000)
              .to_a
    end
    
    # Warm up document count
    puts "- Warming document count cache..."
    total_docs = Rails.cache.fetch('sitemap_total_documents_count', expires_in: 24.hours) do
      Document.where(publish: true).count
    end
    
    # Warm up first few pages
    total_pages = (total_docs / 50000.0).ceil
    pages_to_warm = [total_pages, 3].min # Warm up first 3 pages or total pages if less
    
    (1..pages_to_warm).each do |page|
      puts "- Warming page #{page} cache..."
      offset = (page - 1) * 50000
      Rails.cache.fetch("sitemap_documents_page_#{page}", expires_in: 24.hours) do
        Document.where(publish: true)
                .includes(:document_type, :tags)
                .order(publication_date: :desc, id: :desc)
                .limit(50000)
                .offset(offset)
                .to_a
      end
    end
    
    puts "✓ Sitemap cache warmed up successfully!"
    puts "  Total documents: #{total_docs}"
    puts "  Total pages: #{total_pages}"
    puts "  Pages warmed: #{pages_to_warm}"
    puts "  Cache duration: 24 hours"
  end
  
  desc "Daily sitemap regeneration - clears cache and warms it up"
  task daily_regenerate: :environment do
    puts "Daily sitemap regeneration started at #{Time.current}"
    puts "=" * 50
    
    # Clear existing cache
    puts "1. Clearing existing sitemap cache..."
    Api::V1::SitemapController.clear_cache
    
    # Warm up cache with fresh data
    puts "\n2. Warming up cache with fresh data..."
    Rake::Task['sitemap:warm_cache'].invoke
    
    puts "\n✓ Daily sitemap regeneration completed at #{Time.current}"
    puts "  Next regeneration scheduled for: #{24.hours.from_now}"
  end
  
  desc "Test sitemap generation performance"
  task performance_test: :environment do
    puts "Testing sitemap generation performance..."
    puts "=" * 50
    
    # Test without cache
    Rails.cache.clear
    start_time = Time.current
    Document.where(publish: true).includes(:document_type, :tags).limit(1000).to_a
    uncached_time = Time.current - start_time
    
    # Test with cache
    start_time = Time.current
    Rails.cache.fetch('test_documents', expires_in: 1.hour) do
      Document.where(publish: true).includes(:document_type, :tags).limit(1000).to_a
    end
    first_cached_time = Time.current - start_time
    
    # Test cached retrieval
    start_time = Time.current
    Rails.cache.fetch('test_documents', expires_in: 1.hour) do
      Document.where(publish: true).includes(:document_type, :tags).limit(1000).to_a
    end
    cached_time = Time.current - start_time
    
    puts "Results for 1000 documents:"
    puts "- Without cache: #{(uncached_time * 1000).round(2)}ms"
    puts "- First cache:   #{(first_cached_time * 1000).round(2)}ms"
    puts "- Cached read:   #{(cached_time * 1000).round(2)}ms"
    puts "- Speed improvement: #{(uncached_time / cached_time).round(1)}x faster"
    
    Rails.cache.delete('test_documents')
  end
end
