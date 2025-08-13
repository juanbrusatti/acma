import { Application } from "@hotwired/stimulus"

import Swal from "sweetalert2"

window.Swal = Swal

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
