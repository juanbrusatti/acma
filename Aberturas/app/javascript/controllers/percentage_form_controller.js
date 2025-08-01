// Import Stimulus Controller base class for creating interactive components
import { Controller } from "@hotwired/stimulus"

// Percentage Form Controller - Handles global percentage updates for glass prices
export default class extends Controller {
  // Define Stimulus targets that this controller will interact with
  static targets = ["input", "submit"]

  // Lifecycle method called when controller is connected to the DOM
  connect() {
    console.log("Percentage form controller connected")
  }

  // Handle form submission with validation and user confirmation
  submit(event) {
    // Get the percentage value from the input field
    const percentage = this.inputTarget.value
    
    // Validate percentage input - must be present and non-negative
    if (!percentage || percentage < 0) {
      event.preventDefault() // Prevent form submission
      alert("Por favor ingrese un porcentaje válido (mayor o igual a 0)")
      return
    }

    // Show confirmation dialog to user before applying changes to all glass prices
    if (!confirm(`¿Está seguro que desea aplicar ${percentage}% de ganancia a todos los vidrios?`)) {
      event.preventDefault() // Cancel submission if user declines
      return
    }

    // Disable submit button and show loading state during form submission
    this.submitTarget.disabled = true
    this.submitTarget.textContent = "Aplicando..."
  }

  // Lifecycle method called when controller is disconnected from the DOM
  // Reset button state to prevent UI inconsistencies
  disconnect() {
    // Check if submit target exists before attempting to modify it
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = false
      this.submitTarget.textContent = "Aplicar"
    }
  }
}
