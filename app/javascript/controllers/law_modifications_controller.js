import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="law-modifications"  
export default class extends Controller {
  static targets = ["modificationTypeSelect", "urlInput", "submitButton"]

  connect() {
    console.log("Connected to law-modifications controller");
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

  // Check if URL is valid (contains law ID)
  isValidUrl(url) {
    if (!url) return false;
    
    // Check for law ID in URL patterns
    const patterns = [
      /laws\/(\d+)/,          // laws/123
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

  // Extract law ID from URL and show preview
  extractAndShowId() {
    const url = this.urlInputTarget.value.trim();
    const previewElement = this.element.querySelector('.law-preview');
    
    if (!previewElement) return;

    if (!url) {
      previewElement.innerHTML = '';
      return;
    }

    const lawId = this.extractId(url);
    
    if (lawId) {
      previewElement.innerHTML = `
        <small class="text-success">
          <i class="fas fa-check-circle"></i> 
          Se detectó la ley ID: <strong>${lawId}</strong>
        </small>
      `;
    } else {
      previewElement.innerHTML = `
        <small class="text-danger">
          <i class="fas fa-exclamation-circle"></i> 
          No se pudo extraer el ID de la ley de esta URL
        </small>
      `;
    }
  }

  // Extract law ID from URL
  extractId(url) {
    const patterns = [
      /laws\/(\d+)/,          // laws/123
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
    this.submitButtonTarget.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Creando modificación...';
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
    
    const previewElement = this.element.querySelector('.law-preview');
    if (previewElement) previewElement.innerHTML = '';
  }
}
