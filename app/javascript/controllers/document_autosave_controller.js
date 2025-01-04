import { Controller } from "@hotwired/stimulus"
import debounce from "lodash.debounce";

// Connects to data-controller="document-autosave"
export default class extends Controller {
  connect() {
    console.log("Connected to document-autosave controller");
    this.form = this.element.closest("form");
    this.formData = new FormData(this.form);

    // Set the URL to point to 'documents/:id/edit'
    this.url = this.form.action;
    // Get the autosave delay from the form's data-autosave_delay attribute
    const autosaveDelay = this.form.dataset.autosaveDelay;
    this.autosaveDelayAsInt = parseInt(autosaveDelay);
    const requestToDelay = () => this.sendRequest(this.url, this.formData);

    // Debounce the request to avoid sending multiple requests
    // The request will be sent after the delay has passed since the last call to a debounced function 
    this.debouncedRequest = debounce(requestToDelay, this.autosaveDelayAsInt);

    // Initialize TinyMCE change event listener
    if (typeof tinymce !== 'undefined') {
      console.log("TinyMCE is loaded");
      tinymce.init({
        selector: '.tinymce',
        setup: (editor) => {
          editor.on('change', () => {
            console.log("TinyMCE change event");
            this.save();
          });
          editor.on('keyup', () => {
            console.log("TinyMCE keyup event");
            this.save();
          });
        }
      });
    }
  }

  save() {
    console.log("Saving document...");
    this.formData = new FormData(this.form);

    // Update the formData with the TinyMCE content
    if (typeof tinymce !== 'undefined') {
      tinymce.triggerSave();
    }

    // Call the debounced request with the new form
    this.debouncedRequest(this.url, this.formData);
  }

  sendRequest(url, formData) {
    // Fetch and trigger turbo_stream response
    fetch(url, {
      method: 'PATCH',
      body: formData,
      headers: {
        "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
        "Accept": "text/vnd.turbo-stream.html",
      },
      credentials: 'same-origin'
    }).then((response) => {
      response.text().then((html) => {
        document.body.insertAdjacentHTML('beforeend', html);
      });
    });
  }
}