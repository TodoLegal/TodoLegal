import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="document-form-validator"
export default class extends Controller {
  static targets = ["issueId", "name", "shortDescription", "description"]

  connect() {
  }

  validate(event) {
    let isValid = true;

    // Iterate over each target and check if it is empty
    this.constructor.targets.forEach((target) => {
      const targetName = `${target}Target`;
      if (this[`has${targetName[0].toUpperCase() + targetName.substring(1)}`]) {
        const elements = this[`${target}Targets`];
        elements.forEach((element) => {
          if (element.value.trim() === "") {
            element.classList.add("is-invalid");
            isValid = false;
          } else {
            element.classList.remove("is-invalid");
          }
        });
      }
    });

    if (!isValid) {
      event.preventDefault();
      alert("Por favor llena todos los campos requeridos.");
    }
  }

}

