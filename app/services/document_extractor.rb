# Extracts plain text from an uploaded file, whatever the format.
#
# Supported today:
#   - PDF          via the pdf-reader gem
#   - Word .docx   via the docx gem
#   - HTML         via Nokogiri (strip tags, keep text)
#   - Markdown     stored as-is (plain text)
#   - Plain text   stored as-is
#   - CSV          rows joined into paragraphs
#   - JSON         pretty-printed
#
# Add a new format by adding a branch to `extract_for` — that's the whole pattern.
require "csv"

class DocumentExtractor
  class UnsupportedFormatError < StandardError; end

  class << self
    def extract(document)
      blob = document.file.blob
      text = extract_for(blob)
      text = text.gsub(/\r\n/, "\n").gsub(/[ \t]+/, " ").strip
      raise UnsupportedFormatError, "No readable text found in #{blob.filename}" if text.blank?

      text
    end

    private

    def extract_for(blob)
      case content_type(blob)
      when "application/pdf"
        extract_pdf(blob)
      when "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        extract_docx(blob)
      when "text/html", "application/xhtml+xml"
        extract_html(blob)
      when "text/markdown", "text/plain", "text/x-markdown"
        blob.download
      when "text/csv", "application/csv"
        extract_csv(blob)
      when "application/json", "text/json"
        extract_json(blob)
      else
        raise UnsupportedFormatError,
              "Unsupported format: #{blob.content_type || 'unknown'} (supported: pdf, docx, html, markdown, txt, csv, json)"
      end
    end

    def content_type(blob)
      blob.content_type.presence || blob.filename.extension_with_delimiter&.delete_prefix(".")
    end

    def extract_pdf(blob)
      blob.open do |file|
        PDF::Reader.new(file.path).pages.map(&:text).join("\n\n")
      end
    end

    def extract_docx(blob)
      blob.open do |file|
        Docx::Document.open(file.path).paragraphs.map(&:text).join("\n")
      end
    end

    def extract_html(blob)
      doc = Nokogiri::HTML(blob.download)
      doc.css("script, style, noscript").each(&:remove)
      doc.at_css("body")&.text || doc.text
    end

    def extract_csv(blob)
      blob.download.then do |content|
        CSV.parse(content, headers: false).map { |row| row.join(", ") }.join("\n")
      end
    end

    def extract_json(blob)
      JSON.pretty_generate(JSON.parse(blob.download))
    rescue JSON::ParserError => e
      raise UnsupportedFormatError, "Invalid JSON: #{e.message}"
    end
  end
end
