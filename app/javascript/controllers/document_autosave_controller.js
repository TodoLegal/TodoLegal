import { Controller } from "@hotwired/stimulus"
import debounce from "lodash.debounce";

// Connects to data-controller="document-autosave"
export default class extends Controller {
  connect() {
    console.log("Connected to document-autosave controller");
    // Send form data to the documents controller, edit action
    this.form = this.element.closest("form");
    this.formData = new FormData(this.form);

    // Set the URL to point to 'documents/:id/edit'
    this.url = this.form.action;
    // Get the autosave delay from the form's data-auotsave_delay attribute
    const auotsave_delay = this.form.dataset.auotsave_delay;
    this.autosaveDelayAsInt = parseInt(auotsave_delay);

    const requestToDelay = () => this.sendRequest(this.url, this.formData);

    // Debounce the request to avoid sending multiple requests
    // The request will be sent after the delay has passed since the last call to a debounced function 

    this.debouncedRequest = debounce(requestToDelay, this.autosaveDelayAsInt);

  }

  save() {
    console.log("Saving document...");
    this.formData = new FormData(this.form);

    // Call the debounced request with the new form
    this.debouncedRequest(this.url, this.formData);
  }

  sendRequest( url, formData ) {
    console.log("sending request to " + url);

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
