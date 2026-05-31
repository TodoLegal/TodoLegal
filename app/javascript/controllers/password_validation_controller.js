import { Controller } from "@hotwired/stimulus"

// Client-side validation for password set/reset forms.
// Progressive enhancement — server-side Devise validation is still authoritative.
//
// Usage:
//   <div data-controller="password-validation">
//     <input data-password-validation-target="password" data-action="input->password-validation#validate">
//     <input data-password-validation-target="confirm"  data-action="input->password-validation#validate">
//     <p    data-password-validation-target="hintLength" class="hidden">Mínimo 8 caracteres</p>
//     <p    data-password-validation-target="hintMatch"  class="hidden">Las contraseñas no coinciden</p>
//     <button data-password-validation-target="submit">Submit</button>
//   </div>
export default class extends Controller {
  static targets = ["password", "confirm", "submit", "hintLength", "hintMatch"]

  connect() {
    this.submitTarget.disabled = true
    this.submitTarget.classList.add("opacity-50", "cursor-not-allowed")
  }

  validate() {
    const pw      = this.passwordTarget.value
    const confirm = this.confirmTarget.value
    const lengthOk = pw.length >= 8
    const matchOk  = confirm.length > 0 && pw === confirm

    if (this.hasHintLengthTarget) {
      this.hintLengthTarget.classList.toggle("hidden", lengthOk || pw.length === 0)
    }
    if (this.hasHintMatchTarget) {
      this.hintMatchTarget.classList.toggle("hidden", matchOk || confirm.length === 0)
    }

    const allOk = lengthOk && matchOk
    this.submitTarget.disabled = !allOk
    this.submitTarget.classList.toggle("opacity-50", !allOk)
    this.submitTarget.classList.toggle("cursor-not-allowed", !allOk)
  }
}
