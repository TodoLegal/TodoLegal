import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="alert"
export default class extends Controller {
  connect() {
    let fadeTimeout = this.element.dataset.fadeTimeout;
    fadeTimeout = parseInt(fadeTimeout, 10);
    if ( fadeTimeout > 0 ) {
      setTimeout(() => {
        this.element.classList.remove("show");
        this.element.classList.add("animate__fadeOut");
        // this.element.remove();
      }, fadeTimeout);
    }
  }
}