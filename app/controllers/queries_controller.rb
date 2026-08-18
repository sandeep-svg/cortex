class QueriesController < ApplicationController
  include ActionController::Live

  def index
    @queries = Query.where(user: current_user).recent.limit(50)
    @documents = Document.completed.order(:title)
    @active_provider = Provider.active_provider
  end

  # Creates a Query row and returns its id; the answer arrives via #stream.
  def create
    query = Query.new(question: params[:question], document_id: params[:document_id],
                      user: current_user, status: "processing")
    if query.save
      render json: { id: query.id }
    else
      render json: { error: query.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  # Clears the current user's chat history.
  def clear
    Query.where(user: current_user).delete_all
    redirect_to queries_path, notice: "Chat history cleared"
  end

  # Server-Sent Events endpoint: streams the RAG answer back to the browser.
  def stream
    query = Query.where(user: current_user).find(params[:id])
    document = query.document

    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    RagService.generate(query, document: document) do |event|
      response.stream.write("data: #{event.to_json}\n\n")
    end
  rescue StandardError => e
    response.stream.write("data: #{({ type: :error, payload: e.message }).to_json}\n\n")
  ensure
    response.stream.close
  end
end
