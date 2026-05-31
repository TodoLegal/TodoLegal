import { Controller } from "@hotwired/stimulus"

// Toggles a password field between type=password and type=text.
// Each instance is scoped to its own wrapper div, so multiple toggles
// on the same page work independently with no IDs or global functions.
//
// Usage:
//   <div class="relative" data-controller="password-toggle">
//     <input type="password" data-password-toggle-target="input">
//     <button data-action="click->password-toggle#toggle">
//       <svg data-password-toggle-target="eye">...</svg>
//       <svg data-password-toggle-target="eyeOff" class="hidden">...</svg>
//     </button>
//   </div>
export default class extends Controller {
  static targets = ["input", "eye", "eyeOff"]

  toggle() {
    const isHidden = this.inputTarget.type === "password"
    this.inputTarget.type = isHidden ? "text" : "password"
    this.eyeTarget.classList.toggle("hidden", !isHidden)
    this.eyeOffTarget.classList.toggle("hidden", isHidden)
  }
}
