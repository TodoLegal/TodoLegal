# frozen_string_literal: true

# Configuration module for law display functionality
# Centralizes constants, limits, and configuration options
# for law rendering and chunking strategies
module LawDisplayConfig
  extend ActiveSupport::Concern

  # Default chunk size for loading articles in batches
  # Based on performance analysis - 200 articles balance memory vs queries
  DEFAULT_CHUNK_SIZE = 100

  # Chunk sizes for different scenarios
  CHUNK_SIZES = {
    search: 100,        # Smaller chunks for search results (faster initial load)
    normal: 100,        # Standard chunk size for regular law browsing
    mobile: 50         # Smaller chunks for mobile devices
  }.freeze

  # User access limits based on subscription status
  ACCESS_LIMITS = {
    basic: 5,           # Basic users see only first 5 articles
    pro: nil,       # Pro users have unlimited access
  }.freeze

  # Search configuration
  SEARCH_CONFIG = {
    highlight_enabled: true,
    max_results: 1000,
    min_query_length: 2
  }.freeze

  # Cache configuration for law components
  CACHE_CONFIG = {
    ttl: 1.hour,                    # Cache time-to-live
    version_key: 'law_display_v1',  # Cache version for invalidation
    compress: true                  # Enable cache compression for large laws
  }.freeze

  class_methods do
    # Get appropriate chunk size based on context
    # @param user [User, nil] Current user
    # @param context [Symbol] Context (:search, :normal, :mobile)
    # @return [Integer] Chunk size to use
    def chunk_size_for(user: nil, context: :normal)
      return CHUNK_SIZES[:mobile] if mobile_request?
      return CHUNK_SIZES[:search] if context == :search
      
      CHUNK_SIZES[:normal]
    end

    # Get basic access limit for service layer
    # Note: Law-specific access is handled by controller's user_can_access_law method
    # @param user [User, nil] Current user
    # @return [Integer, nil] Access limit or nil for unlimited
    def access_limit_for(user)
      # Simple check: authenticated users get unlimited in service, 
      # controller will apply law-specific restrictions
      user ? ACCESS_LIMITS[:pro] : ACCESS_LIMITS[:basic]
    end

    # Check if this is a mobile request
    # @return [Boolean] True if mobile user agent detected
    def mobile_request?
      # This would typically check user agent or device detection
      # For now, return false - can be enhanced later
      false
    end
  end

  included do
    # Instance methods available to including classes
    
    # Get chunk size for current context
    # @param user [User, nil] Current user
    # @param context [Symbol] Context (:search, :normal, :mobile)
    # @return [Integer] Chunk size to use
    def chunk_size_for(user: nil, context: :normal)
      self.class.chunk_size_for(user: user, context: context)
    end

    # Get access limit for current user
    # @param user [User, nil] Current user
    # @return [Integer, nil] Access limit or nil for unlimited
    def access_limit_for(user)
      self.class.access_limit_for(user)
    end

    # Check if user has unlimited access (in service layer)
    # @param user [User, nil] Current user
    # @return [Boolean] True if user has unlimited access
    def unlimited_access?(user)
      access_limit_for(user).nil?
    end
  end
end