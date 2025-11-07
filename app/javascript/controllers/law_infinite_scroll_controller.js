import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="law-infinite-scroll"
// Handles progressive law content loading with intersection observers
export default class extends Controller {
  static targets = ["loading", "retryButton"]
  static values = { 
    lawId: Number,
    currentPage: Number, 
    hasMoreChunks: Boolean,
    chunkUrl: String 
  }

  // State management
  loading = false
  error = false
  retryCount = 0
  maxRetries = 3
  observer = null

  connect() {
    console.log("📜 Law infinite scroll controller connected")
    console.log(`Law ID: ${this.lawIdValue}, Page: ${this.currentPageValue}, Has More: ${this.hasMoreChunksValue}`)
    
    // Initialize intersection observer for automatic loading
    this.setupIntersectionObserver()
    
    // Setup manual fallback button visibility
    this.setupFallbackButton()
  }

  disconnect() {
    console.log("📜 Law infinite scroll controller disconnected")
    
    // Clean up intersection observer
    if (this.observer) {
      this.observer.disconnect()
      this.observer = null
    }
  }

  // Setup intersection observer for automatic chunk loading
  setupIntersectionObserver() {
    // Check if Intersection Observer is supported
    if (!window.IntersectionObserver) {
      console.log("🔧 Intersection Observer not supported, enabling fallback button")
      this.showFallbackButton()
      return
    }

    // Only setup observer if we have more content to load
    if (!this.hasMoreChunksValue) {
      console.log("📜 No more chunks to load, skipping observer setup")
      return
    }

    // Find the loading trigger element
    const loadingTrigger = this.hasLoadingTarget ? this.loadingTarget : null
    
    if (!loadingTrigger) {
      console.warn("⚠️ Loading trigger element not found")
      this.showFallbackButton()
      return
    }

    // Create intersection observer
    const options = {
      root: null, // Use viewport as root
      rootMargin: '200px 0px', // Start loading 200px before element is visible
      threshold: 0.1 // Trigger when 10% of element is visible
    }

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting && !this.loading && this.hasMoreChunksValue) {
          console.log("👁️ Loading trigger visible, loading next chunk...")
          this.loadNextChunk()
        }
      })
    }, options)

    // Start observing the loading trigger
    this.observer.observe(loadingTrigger)
    console.log("👁️ Intersection observer setup complete")
  }

  // Setup fallback manual loading button
  setupFallbackButton() {
    // Show fallback button if intersection observer is not available
    // or as a backup option for users who prefer manual control
    if (!window.IntersectionObserver) {
      this.showFallbackButton()
    }
  }

  // Show the manual "Load More" button
  showFallbackButton() {
    const buttons = document.querySelectorAll('.load-more-btn')
    buttons.forEach(button => {
      button.style.display = 'inline-block'
    })
    console.log("🔘 Manual load more button enabled")
  }

  // Hide the manual "Load More" button
  hideFallbackButton() {
    const buttons = document.querySelectorAll('.load-more-btn')
    buttons.forEach(button => {
      button.style.display = 'none'
    })
  }

  // Load the next chunk of content
  async loadNextChunk() {
    // Prevent multiple simultaneous requests
    if (this.loading || !this.hasMoreChunksValue) {
      console.log("⏸️ Already loading or no more chunks available")
      return
    }

    console.log(`📥 Loading chunk: page ${this.currentPageValue + 1}`)
    
    this.loading = true
    this.error = false
    this.showLoadingState()

    try {
      const nextPage = this.currentPageValue + 1
      const url = `${this.chunkUrlValue}?page=${nextPage}&format=turbo_stream`
      
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Accept': 'text/vnd.turbo-stream.html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }

      const html = await response.text()
      
      // Let Turbo handle the stream response
      // Turbo will automatically process turbo-stream tags and update the DOM
      Turbo.renderStreamMessage(html)
      
      // Update our state
      this.currentPageValue = nextPage
      this.retryCount = 0
      
      // Re-setup observer for the new loading trigger element
      this.reattachObserver()
      
      console.log(`✅ Successfully loaded chunk ${nextPage}`)
      
    } catch (error) {
      console.error('❌ Error loading chunk:', error)
      this.handleError(error.message)
    } finally {
      this.loading = false
      this.hideLoadingState()
    }
  }

  // Re-attach intersection observer to new loading element after DOM update
  reattachObserver() {
    // Small delay to ensure DOM is fully updated by Turbo
    setTimeout(() => {
      if (this.hasMoreChunksValue && this.hasLoadingTarget) {
        // Disconnect existing observer
        if (this.observer) {
          this.observer.disconnect()
        }
        
        // Find the new loading trigger
        const newLoadingTrigger = this.loadingTarget
        
        if (newLoadingTrigger) {
          // Re-create and attach observer
          const options = {
            root: null,
            rootMargin: '200px 0px',
            threshold: 0.1
          }

          this.observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
              if (entry.isIntersecting && !this.loading && this.hasMoreChunksValue) {
                console.log("👁️ New loading trigger visible, loading next chunk...")
                this.loadNextChunk()
              }
            })
          }, options)

          this.observer.observe(newLoadingTrigger)
          console.log("🔄 Observer re-attached to new loading trigger")
        } else {
          console.warn("⚠️ New loading trigger not found after DOM update")
          this.showFallbackButton()
        }
      } else {
        console.log("🏁 No more chunks or loading target not available")
      }
    }, 150) // Small delay for DOM update
  }

  // Manual retry action (triggered by retry button)
  retry() {
    console.log(`🔄 Retry attempt ${this.retryCount + 1}/${this.maxRetries}`)
    
    if (this.retryCount < this.maxRetries) {
      this.retryCount++
      this.loadNextChunk()
    } else {
      console.error(`❌ Max retries (${this.maxRetries}) exceeded`)
      this.showMaxRetriesError()
    }
  }

  // Handle loading errors
  handleError(errorMessage) {
    this.error = true
    
    // Update error state in the DOM if error container exists
    const errorContainer = document.getElementById('loading-indicator')
    if (errorContainer) {
      // The error state will be handled by the controller's error response
      // We just log it here and let the Turbo stream handle the UI update
      console.error(`💥 Chunk loading failed: ${errorMessage}`)
    }
  }

  // Show loading spinner and text
  showLoadingState() {
    const spinner = document.querySelector('.law-loading-spinner')
    const loadMoreText = document.querySelector('.load-more-text')
    
    if (spinner) {
      spinner.style.display = 'block'
    }
    
    if (loadMoreText) {
      loadMoreText.textContent = 'Cargando más artículos...'
    }
    
    // Hide manual button while loading
    this.hideFallbackButton()
  }

  // Hide loading spinner
  hideLoadingState() {
    const spinner = document.querySelector('.law-loading-spinner')
    
    if (spinner) {
      spinner.style.display = 'none'
    }
    
    // Show manual button again if needed
    if (!window.IntersectionObserver || this.error) {
      this.showFallbackButton()
    }
  }

  // Show max retries exceeded error
  showMaxRetriesError() {
    const loadMoreText = document.querySelector('.load-more-text')
    
    if (loadMoreText) {
      loadMoreText.innerHTML = `
        <span class="text-danger">
          <i class="fas fa-exclamation-triangle me-1"></i>
          Error: Máximo de reintentos alcanzado
        </span>
      `
    }
  }

  // Update chunk state after successful turbo stream response
  updateChunkState(page, hasMore) {
    console.log(`📊 Updating state: page ${page}, has more: ${hasMore}`)
    
    this.currentPageValue = page
    this.hasMoreChunksValue = hasMore
    
    // Re-setup intersection observer for new loading trigger
    if (hasMore && this.observer) {
      // Find new loading trigger and observe it
      setTimeout(() => {
        const newLoadingTrigger = document.querySelector('[data-law-infinite-scroll-target="loading"]')
        if (newLoadingTrigger && this.observer) {
          this.observer.observe(newLoadingTrigger)
          console.log("👁️ Observing new loading trigger")
        }
      }, 100) // Small delay to ensure DOM is updated
    }
    
    // Hide fallback button if we're done loading
    if (!hasMore) {
      this.hideFallbackButton()
      
      // Disconnect observer since we're done
      if (this.observer) {
        this.observer.disconnect()
        this.observer = null
        console.log("🏁 All chunks loaded, observer disconnected")
      }
    }
  }

  // Debug method to check controller state
  debugState() {
    return {
      lawId: this.lawIdValue,
      currentPage: this.currentPageValue,
      hasMore: this.hasMoreChunksValue,
      loading: this.loading,
      error: this.error,
      retryCount: this.retryCount,
      observerActive: !!this.observer
    }
  }

  // Method to handle Turbo Stream updates that may change our state
  // This can be called from Turbo Stream actions
  handleTurboUpdate(event) {
    console.log("🔄 Handling Turbo update", event)
    
    // Check if our container still has the right data attributes
    const container = this.element
    if (container) {
      // Update values from DOM if they've changed
      const newPage = parseInt(container.dataset.lawInfiniteScrollCurrentPageValue)
      const newHasMore = container.dataset.lawInfiniteScrollHasMoreChunksValue === 'true'
      
      if (newPage !== this.currentPageValue || newHasMore !== this.hasMoreChunksValue) {
        this.updateChunkState(newPage, newHasMore)
      }
    }
  }

  // Value change callbacks (Stimulus automatically calls these)
  currentPageValueChanged(newValue, oldValue) {
    if (oldValue !== undefined) {
      console.log(`📄 Page changed: ${oldValue} → ${newValue}`)
    }
  }

  hasMoreChunksValueChanged(newValue, oldValue) {
    if (oldValue !== undefined) {
      console.log(`🔄 Has more chunks changed: ${oldValue} → ${newValue}`)
      
      if (!newValue && this.observer) {
        // No more chunks, clean up
        this.observer.disconnect()
        this.observer = null
        this.hideFallbackButton()
      }
    }
  }
}