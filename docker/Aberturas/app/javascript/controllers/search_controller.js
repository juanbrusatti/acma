import { Controller } from "@hotwired/stimulus"

// Conecta un formulario de búsqueda con debounce y envío automático
// Uso en la vista:
// <form data-controller="search" data-turbo-frame="projects_table"> ...
//   <input data-action="input->search#onInput">
//   <select data-action="change->search#submit">
// </form>
export default class extends Controller {
  static values = {
    delay: { type: Number, default: 300 }
  }

  connect() {
    this._timer = null
  }

  disconnect() {
    this._clearTimer()
  }

  onInput() {
    this._debounce(() => this.submit())
  }

  submit() {
    // Usa requestSubmit para mantener el método GET y los parámetros
    this.element.requestSubmit()
  }

  _debounce(callback) {
    this._clearTimer()
    this._timer = setTimeout(callback, this.delayValue)
  }

  _clearTimer() {
    if (this._timer) {
      clearTimeout(this._timer)
      this._timer = null
    }
  }
}
