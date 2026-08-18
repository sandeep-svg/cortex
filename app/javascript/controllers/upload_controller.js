import { Controller } from "@hotwired/stimulus"

const CSRF_TOKEN = document.querySelector('meta[name="csrf-token"]')?.content

export default class extends Controller {
  static targets = ["dropzone", "input", "progress", "progressBar", "progressLabel", "processing"]

  pick() {
    this.inputTarget.click()
  }

  dragover(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("dragover")
  }

  dragleave(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("dragover")
  }

  drop(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("dragover")
    this.uploadFiles(event.dataTransfer.files)
  }

  filesSelected(event) {
    this.uploadFiles(event.target.files)
  }

  async uploadFiles(files) {
    for (const file of Array.from(files)) {
      await this.uploadOne(file)
    }
    window.location.reload()
  }

  async uploadOne(file) {
    this.showProgress(`Uploading ${file.name}…`, 15)

    const formData = new FormData()
    formData.append("file", file)

    const response = await fetch("/documents", {
      method: "POST",
      headers: { "X-CSRF-Token": CSRF_TOKEN },
      body: formData
    })
    const data = await response.json()
    if (!response.ok) throw new Error(data.error || "Upload failed")

    this.hideProgress()
    this.showProcessing(file.name)
    await this.pollStatus(data.id)
  }

  pollStatus(id) {
    return new Promise((resolve) => {
      const timer = setInterval(async () => {
        const response = await fetch(`/documents/${id}/status`)
        const data = await response.json()
        if (data.status === "completed" || data.status === "failed") {
          clearInterval(timer)
          resolve()
        }
      }, 1500)
    })
  }

  showProgress(label, percent) {
    this.progressTarget.classList.add("active")
    this.progressLabelTarget.textContent = label
    this.progressBarTarget.style.width = `${percent}%`
  }

  hideProgress() {
    this.progressTarget.classList.remove("active")
  }

  showProcessing(filename) {
    this.processingTarget.classList.add("active")
    this.processingTarget.querySelector(".card-hint").textContent =
      `🔄 Indexing ${filename} — extracting text, chunking and embedding in the background…`
  }
}