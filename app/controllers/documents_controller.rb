class DocumentsController < ApplicationController
  before_action :require_admin
  before_action :set_document, only: %i[show destroy reindex status]

  def index
    @documents = Document.recent
  end

  def show
    @chunks = @document.chunks.order(:position)
  end

  def create
    file = params[:file]
    document = Document.new(file: file, title: file.original_filename)
    document.content_type = file.content_type
    document.file_size = file.size

    if document.save
      IndexDocumentJob.perform_later(document)
      render json: { id: document.id, status: document.status }, status: :created
    else
      render json: { error: document.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def reindex
    @document.update!(status: "queued", error: nil)
    IndexDocumentJob.perform_later(@document)
    redirect_to documents_path, notice: "Re-indexing #{@document.title} in the background."
  end

  def destroy
    @document.destroy
    redirect_to documents_path, notice: "Deleted #{@document.title}."
  end

  def status
    render json: { id: @document.id, status: @document.status, chunk_count: @document.chunk_count, error: @document.error }
  end

  private

  def set_document
    @document = Document.find(params[:id])
  end
end
