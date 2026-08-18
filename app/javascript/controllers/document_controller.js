import { Controller } from "@hotwired/stimulus"

// Polls a document card's status while it is queued/processing and
// reloads the page when the state changes (completed / failed).
export default class extends Controller {
  static targets = ["badge"]

  connect() {
    const id = this.element.dataset.documentId
    const status = this.badgeTarget.textContent.trim()
    if (!["queued", "processing"].includes(status)) return

    this.timer = setInterval(async () => {
      const response = await fetch(`/documents/${id}/status`)
      const data = await response.json()
      if (["completed", "failed"].includes(data.status)) {
        clearInterval(this.timer)
        window.location.reload()
      }
    }, 2000)
  }

  disconnect() {
    clearInterval(this.timer)
  }
}