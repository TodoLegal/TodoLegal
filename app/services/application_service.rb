# frozen_string_literal: true

# Base class for all service objects following Rails conventions
# Provides consistent interface with class method `.call` and result pattern
#
# Usage:
#   class MyService < ApplicationService
#     def initialize(params)
#       @params = params
#     end
#
#     private
#
#     def call
#       # Implementation here
#       ServiceResult.success(data: result)
#     end
#   end
#
#   result = MyService.call(params)
#   if result.success?
#     # Handle success
#   else
#     # Handle failure
#   end
class ApplicationService
  # Class method interface - delegates to instance
  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  private

  # Override this method in subclasses
  def call
    raise NotImplementedError, "#{self.class} must implement #call"
  end

  # Helper method to create successful results
  # @param data [Object] The successful result data
  # @param metadata [Hash] Additional metadata for the result
  # @return [ServiceResult] A successful service result
  def success(data = nil, metadata = {})
    ServiceResult.success(data, metadata)
  end

  # Helper method to create failure results
  # @param errors [Array, String] The error messages
  # @param metadata [Hash] Additional metadata for the result
  # @return [ServiceResult] A failed service result
  def failure(errors, metadata = {})
    ServiceResult.failure(errors, metadata)
  end
end
