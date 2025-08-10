// Import Stimulus Controller base class for creating interactive components
import { Controller } from "@hotwired/stimulus"

// Supply Edit Controller - Handles inline editing of supply USD prices
export default class extends Controller {
  static targets = ["display", "form"]
  static values = { 
    supplyId: Number,
    originalUsd: String,
    originalDisplay: String 
  }

  // Cancel editing and restore original display
  cancel() {
    // Simple fetch to get the original display partial
    fetch(`/supplies/${this.supplyIdValue}`, {
      method: 'GET',
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.text())
    .then(html => {
      // Just reload the frame with the original content
      this.element.innerHTML = this.originalDisplayValue
    })
    .catch(error => {
      console.error('Error canceling edit:', error)
      // Fallback: reload the page
      window.location.reload()
    })
  }
}
