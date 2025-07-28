import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="document-relationships"
export default class extends Controller {
  static targets = ["modificationTypeSelect", "urlInput", "submitButton"]

  connect() {
    console.log("Connected to document-relationships controller");
    this.validateForm();
  }

  // Validate form inputs
  validateForm() {
    if (!this.hasModificationTypeSelectTarget || !this.hasUrlInputTarget) return;
    
    const modificationType = this.modificationTypeSelectTarget.value;
    const url = this.urlInputTarget.value.trim();
    
    // Enable submit button only if both fields are filled
    const isValid = modificationType && url && this.isValidUrl(url);
    this.submitButtonTarget.disabled = !isValid;
    
    if (isValid) {
      this.submitButtonTarget.classList.remove('btn-secondary');
      this.submitButtonTarget.classList.add('btn-primary');
    } else {
      this.submitButtonTarget.classList.remove('btn-primary');
      this.submitButtonTarget.classList.add('btn-secondary');
    }
  }

  // Check if URL is valid (contains document ID)
  isValidUrl(url) {
    if (!url) return false;
    
    // Check for document ID in URL patterns
    const patterns = [
      /documents\/(\d+)/,     // documents/123
      /\/(\d+)(?:\/|$)/       // /123 or /123/
    ];
    
    return patterns.some(pattern => pattern.test(url));
  }

  // Handle modification type change
  modificationTypeChanged() {
    this.validateForm();
    this.extractAndShowId();
  }

  // Handle URL input change
  urlChanged() {
    this.validateForm();
    this.extractAndShowId();
  }

  // Extract document ID from URL and show preview
  extractAndShowId() {
    const url = this.urlInputTarget.value.trim();
    const previewElement = this.element.querySelector('.document-preview');
    
    if (!previewElement) return;

    if (!url) {
      previewElement.innerHTML = '';
      return;
    }

    const documentId = this.extractId(url);
    
    if (documentId) {
      previewElement.innerHTML = `
        <small class="text-success">
          <i class="fas fa-check-circle"></i> 
          Se detectó el documento ID: <strong>${documentId}</strong>
        </small>
      `;
    } else {
      previewElement.innerHTML = `
        <small class="text-danger">
          <i class="fas fa-exclamation-circle"></i> 
          No se pudo extraer el ID del documento de esta URL
        </small>
      `;
    }
  }

  // Extract document ID from URL
  extractId(url) {
    const patterns = [
      /documents\/(\d+)/,     // documents/123
      /\/(\d+)(?:\/|$)/       // /123 or /123/
    ];
    
    for (const pattern of patterns) {
      const match = url.match(pattern);
      if (match) return match[1];
    }
    
    return null;
  }

  // Handle form submission
  submit(event) {
    if (this.submitButtonTarget.disabled) {
      event.preventDefault();
      return false;
    }
    
    // Add loading state
    this.submitButtonTarget.disabled = true;
    this.submitButtonTarget.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Creando relación...';
  }

  // Reset form after successful submission
  reset() {
    if (this.hasModificationTypeSelectTarget) {
      this.modificationTypeSelectTarget.value = '';
    }
    if (this.hasUrlInputTarget) {
      this.urlInputTarget.value = '';
    }
    
    this.validateForm();
    
    const previewElement = this.element.querySelector('.document-preview');
    if (previewElement) previewElement.innerHTML = '';
  }
}
