import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"

marked.setOptions({ breaks: true })

const CSRF_TOKEN = document.querySelector('meta[name="csrf-token"]')?.content

export default class extends Controller {
  static targets = ["log", "input", "sendBtn", "documentSelect", "empty"]

  connect() {
    this.scrollBottom()
  }

  async ask(event) {
    event.preventDefault()
    const question = this.inputTarget.value.trim()
    if (!question) return

    if (this.hasEmptyTarget) this.emptyTarget.remove()
    this.inputTarget.value = ""
    this.appendUserMessage(question)
    this.showTyping()

    const documentId = this.hasDocumentSelectTarget ? this.documentSelectTarget.value : ""

    try {
      const response = await fetch(this.element.dataset.chatQueriesPath, {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": CSRF_TOKEN },
        body: JSON.stringify({ question, document_id: documentId })
      })

      const data = await response.json()
      if (!response.ok) throw new Error(data.error || "Failed to create query")

      await this.streamAnswer(data.id)
    } catch (error) {
      this.finishTyping(error.message, true)
    } finally {
      this.inputTarget.focus()
    }
  }

  async streamAnswer(queryId) {
    const bubble = this.createAssistantBubble()
    this.currentBubble = bubble
    this.accumulated = ""
    const sourcesEl = this.createSourcesSlot()
    const metaEl = this.createMetaSlot()

    const stream = await fetch(`${this.element.dataset.chatQueriesPath}/${queryId}/stream`, {
      method: "POST",
      headers: { "X-CSRF-Token": CSRF_TOKEN }
    })

    if (!stream.ok || !stream.body) throw new Error("Stream failed to start")

    const reader = stream.body.getReader()
    const decoder = new TextDecoder()
    let buffer = ""

    while (true) {
      const { done, value } = await reader.read()
      if (done) break

      buffer += decoder.decode(value, { stream: true })
      const events = buffer.split("\n\n")
      buffer = events.pop()

      for (const raw of events) {
        const line = raw.trim()
        if (!line.startsWith("data:")) continue
        const event = JSON.parse(line.slice(5).trim())
        this.handleEvent(event, bubble, sourcesEl, metaEl)
      }
    }

    this.inputTarget.disabled = false
    this.sendBtnTarget.disabled = false
  }

  handleEvent(event, bubble, sourcesEl, metaEl) {
    switch (event.type) {
      case "sources":
        this.renderSources(event.payload, sourcesEl)
        break
      case "delta":
        this.accumulated += event.payload
        bubble.innerHTML = marked.parse(this.escapeHtml(this.accumulated))
        bubble.scrollIntoView({ block: "end", behavior: "smooth" })
        break
      case "error":
        bubble.textContent = `⚠️ ${event.payload}`
        break
      case "done":
        bubble.classList.remove("caret")
        break
    }
  }

  /* ---------- DOM helpers ---------- */

  appendUserMessage(question) {
    const msg = document.createElement("div")
    msg.className = "msg msg-user"
    msg.innerHTML = `
      <div class="msg-avatar">✦</div>
      <div class="msg-body"><div class="msg-bubble"></div></div>
    `
    msg.querySelector(".msg-bubble").textContent = question
    this.logTarget.appendChild(msg)
    this.scrollBottom()
  }

  showTyping() {
    this.inputTarget.disabled = true
    this.sendBtnTarget.disabled = true

    const typing = document.createElement("div")
    typing.className = "msg"
    typing.dataset.chatTyping = "true"
    typing.innerHTML = `
      <div class="msg-avatar">◈</div>
      <div class="msg-body">
        <div class="msg-bubble"><span class="typing"><span></span><span></span><span></span></span></div>
        <div class="sources"></div>
        <div class="msg-meta"></div>
      </div>
    `
    this.typingEl = typing
    this.logTarget.appendChild(typing)
    this.scrollBottom()
  }

  finishTyping(message, failed) {
    const typing = this.typingEl || this.currentBubble
    if (!typing || !typing.isConnected) return
    const bubble = typing.querySelector(".msg-bubble")
    bubble.classList.remove("caret")
    if (failed) bubble.textContent = `⚠️ ${message}`
    else bubble.classList.add("caret")
    this.typingEl = null
    this.scrollBottom()
  }

  createAssistantBubble() {
    const typing = this.typingEl
    if (typing) {
      this.typingEl = null
      const bubble = typing.querySelector(".msg-bubble")
      bubble.textContent = ""
      bubble.classList.add("caret")
      return bubble
    }

    const msg = document.createElement("div")
    msg.className = "msg"
    msg.innerHTML = `
      <div class="msg-avatar">◈</div>
      <div class="msg-body">
        <div class="msg-bubble caret"></div>
        <div class="sources"></div>
        <div class="msg-meta"></div>
      </div>
    `
    this.logTarget.appendChild(msg)
    this.scrollBottom()
    return msg.querySelector(".msg-bubble")
  }

  createSourcesSlot() {
    const last = this.lastMessage()
    return last ? last.querySelector(".sources") : null
  }

  createMetaSlot() {
    const last = this.lastMessage()
    return last ? last.querySelector(".msg-meta") : null
  }

  lastMessage() {
    const msgs = this.logTarget.querySelectorAll(".msg")
    return msgs[msgs.length - 1] || null
  }

  renderSources(sources, slot) {
    if (!slot) return
    slot.innerHTML = ""
    sources.forEach((source, index) => {
      const chip = document.createElement("span")
      chip.className = "source-chip"
      chip.title = source.snippet
      chip.innerHTML = `[${index + 1}] ${this.escapeHtml(source.document_title)} <span class="rel">· ${(source.relevance * 100).toFixed(1)}%</span>`
      slot.appendChild(chip)
    })
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text || ""
    return div.innerHTML
  }

  scrollBottom() {
    this.logTarget.scrollTop = this.logTarget.scrollHeight
  }
}