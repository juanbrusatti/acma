// Import Stimulus Controller base class for creating interactive components
import { Controller } from "@hotwired/stimulus"

// MEP Form Controller - Handles MEP dollar rate updates for supply prices
export default class extends Controller {
  // Define Stimulus targets that this controller will interact with
  static targets = ["input", "submit"]

  // Lifecycle method called when controller is connected to the DOM
  connect() {
    console.log("MEP form controller connected")
  }

  // Handle form submission with validation and user confirmation
  submit(event) {
    // Get the MEP rate value from the input field
    const mepRate = this.inputTarget.value
    
    // Validate MEP rate input - must be present and positive
    if (!mepRate || mepRate <= 0) {
      event.preventDefault() // Prevent form submission
      alert("Por favor ingrese un valor válido para el dólar MEP (mayor a 0)")
      return
    }

    // Show confirmation dialog to user before applying changes to all supply prices
    if (!confirm(`¿Está seguro que desea actualizar el dólar MEP a $${mepRate} y recalcular todos los precios de insumos?`)) {
      event.preventDefault() // Cancel submission if user declines
      return
    }

    // Disable submit button and show loading state during form submission
    this.submitTarget.disabled = true
    this.submitTarget.textContent = "Actualizando..."
  }

  // Lifecycle method called when controller is disconnected from the DOM
  // Reset button state to prevent UI inconsistencies
  disconnect() {
    // Check if submit target exists before attempting to modify it
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = false
      this.submitTarget.textContent = "Actualizar"
    }
  }
}
