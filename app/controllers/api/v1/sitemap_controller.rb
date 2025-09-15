class Api::V1::SitemapController < ApplicationController
  protect_from_forgery with: :null_session
  include ApplicationHelper
  
  # No authentication required for sitemaps - they're public by nature
  skip_before_action :doorkeeper_authorize!, raise: false
  
  def index
    # Main sitemap with recent documents (up to 50,000 per Google guidelines)
    # Cache for 24 hours - regenerated once daily
    @documents = Rails.cache.fetch('sitemap_main_documents', expires_in: 24.hours) do
      Document.where(publish: true)
              .includes(:document_type, :tags, :issuer_document_tags)
              .order(publication_date: :desc, id: :desc)
              .limit(50000)
              .to_a # Convert to array to cache the result
    end
    
    respond_to do |format|
      format.xml { 
        # Cache the rendered XML for even better performance
        expires_in 24.hours, public: true
        render layout: false 
      }
    end
  end
  
  def sitemap_index
    # Sitemap index for large document sets
    # Cache the count calculation for better performance - 24 hours
    @total_documents = Rails.cache.fetch('sitemap_total_documents_count', expires_in: 24.hours) do
      Document.where(publish: true).count
    end
    
    @pages = (@total_documents / 50000.0).ceil
    @pages = 1 if @pages == 0 # Ensure at least one sitemap exists
    
    respond_to do |format|
      format.xml { 
        expires_in 24.hours, public: true
        render layout: false 
      }
    end
  end
  
  def documents
    # Paginated sitemap for large document sets
    limit = 50000
    page = params[:page].to_i
    page = 1 if page < 1
    offset = (page - 1) * limit
    
    # Cache each page separately with page-specific cache key - 24 hours
    cache_key = "sitemap_documents_page_#{page}"
    @documents = Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      Document.where(publish: true)
              .includes(:document_type, :tags, :issuer_document_tags)
              .order(publication_date: :desc, id: :desc)
              .limit(limit)
              .offset(offset)
              .to_a # Convert to array to cache the result
    end
    
    # Return 404 if page doesn't exist - use cached total count
    total_documents = Rails.cache.fetch('sitemap_total_documents_count', expires_in: 24.hours) do
      Document.where(publish: true).count
    end
    total_pages = (total_documents / 50000.0).ceil
    
    if page > total_pages && total_pages > 0
      head :not_found
      return
    end
    
    respond_to do |format|
      format.xml { 
        expires_in 24.hours, public: true
        render layout: false 
      }
    end
  end

private

  # Additional methods can be added here if needed for controller-specific logic
  
  # Method to clear sitemap cache (can be called from admin interface or rake task)
  def self.clear_cache
    Rails.cache.delete('sitemap_main_documents')
    Rails.cache.delete('sitemap_total_documents_count')
    
    # Clear all paginated document caches
    # We'll clear up to 100 pages (should be more than enough)
    (1..100).each do |page|
      Rails.cache.delete("sitemap_documents_page_#{page}")
    end
    
    Rails.logger.info "Sitemap cache cleared successfully"
  end
  
  # Method to get cache statistics
  def self.cache_stats
    cache_keys = [
      'sitemap_main_documents',
      'sitemap_total_documents_count'
    ]
    
    # Check first 10 pages
    (1..10).each do |page|
      cache_keys << "sitemap_documents_page_#{page}"
    end
    
    stats = {}
    cache_keys.each do |key|
      stats[key] = Rails.cache.exist?(key) ? 'cached' : 'not cached'
    end
    
    stats
  end
end
