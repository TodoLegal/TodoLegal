import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="alert"
export default class extends Controller {
  connect() {
    // removeAlert is "true" or "false" string so we need to convert it to boolean
    let removeAlert = this.element.dataset.removeAlert === "true";
    let fadeTimeout = this.element.dataset.fadeTimeout;
    fadeTimeout = parseInt(fadeTimeout, 10);

    if ( fadeTimeout > 0 ) {
      setTimeout(() => {
        if (removeAlert) {
          this.element.remove();
        }else{
          this.element.classList.remove("show");
          this.element.classList.add("animate__fadeOut");
        }
      }, fadeTimeout);
    }
  }
}