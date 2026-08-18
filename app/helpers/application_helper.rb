module ApplicationHelper
  MARKDOWN_RENDERER = Redcarpet::Markdown.new(
    Redcarpet::Render::HTML.new(escape_html: true, hard_wrap: true),
    autolink: true, tables: true, fenced_code_blocks: true, strikethrough: true
  )

  # Renders LLM markdown answers as safe HTML (raw HTML is escaped).
  def markdown(text)
    MARKDOWN_RENDERER.render(text.to_s).html_safe
  end

  def nav_link_class(path)
    current_page?(path) ? "nav-link active" : "nav-link"
  end

  def status_badge_class(status)
    case status
    when "completed" then "badge badge-ok"
    when "processing" then "badge badge-busy"
    when "queued" then "badge badge-wait"
    when "failed" then "badge badge-fail"
    else "badge"
    end
  end
end
