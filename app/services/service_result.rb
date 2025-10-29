# frozen_string_literal: true

# Standard result object for service operations
# Provides consistent interface for success/failure states
# with data, errors, and metadata handling
class ServiceResult
  attr_reader :data, :errors, :metadata

  def initialize(success:, data: nil, errors: [], metadata: {})
    @success = success
    @data = data
    @errors = Array(errors)
    @metadata = metadata || {}
  end

  # Class method to create successful result
  # @param data [Object] The successful result data
  # @param metadata [Hash] Additional metadata
  # @return [ServiceResult] Successful result instance
  def self.success(data = nil, metadata = {})
    new(success: true, data: data, metadata: metadata)
  end

  # Class method to create failure result
  # @param errors [Array, String] Error messages
  # @param metadata [Hash] Additional metadata
  # @return [ServiceResult] Failed result instance
  def self.failure(errors, metadata = {})
    new(success: false, errors: errors, metadata: metadata)
  end

  # Check if the result represents success
  # @return [Boolean] True if successful
  def success?
    @success
  end

  # Check if the result represents failure
  # @return [Boolean] True if failed
  def failure?
    !@success
  end

  # Alias for success? to match existing codebase patterns
  def successful?
    success?
  end

  # Get first error message for convenience
  # @return [String, nil] First error message or nil
  def error_message
    @errors.first
  end

  # Get all error messages joined
  # @return [String] All errors joined by comma
  def error_messages
    @errors.join(', ')
  end

  # Add error to existing errors (for chaining operations)
  # @param error [String] Error message to add
  def add_error(error)
    @errors << error
  end

  # Get metadata value by key
  # @param key [String, Symbol] Metadata key
  # @return [Object] Metadata value
  def [](key)
    @metadata[key]
  end

  # Set metadata value by key
  # @param key [String, Symbol] Metadata key
  # @param value [Object] Metadata value
  def []=(key, value)
    @metadata[key] = value
  end
end