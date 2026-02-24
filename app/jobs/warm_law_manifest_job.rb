# frozen_string_literal: true

# Background job to warm the manifest cache for a law
# This prevents the first user from experiencing cache-miss penalty
# Triggered automatically after law create/update via model callback
class WarmLawManifestJob < ApplicationJob
  queue_as :default
  
  # Retry with exponential backoff if cache warming fails
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  
  def perform(law_id)
    law = Law.find(law_id)
    
    # Warm inline, flat structure, and full manifest caches
    Rails.logger.info "Warming manifest cache for Law ##{law_id} (#{law.name})"
    
    start_time = Time.current
    
    # Build and cache inline subset (used for initial page loads)
    Laws::ManifestCache.inline_subset(law)
    
    # Build and cache flat structure (optimized for LawDisplayService)
    Laws::ManifestCache.flat_structure(law)
    
    # Build and cache full manifest (used for navigation and article lookups)
    Laws::ManifestCache.full(law)
    
    elapsed = ((Time.current - start_time) * 1000).round(2)
    Rails.logger.info "Manifest cache warmed for Law ##{law_id} in #{elapsed}ms"
    
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "Law ##{law_id} not found, skipping manifest cache warming"
  rescue => e
    Rails.logger.error "Failed to warm manifest cache for Law ##{law_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise # Re-raise to trigger retry logic
  end
end
