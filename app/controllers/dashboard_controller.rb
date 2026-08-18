class DashboardController < ApplicationController
  before_action :require_admin

  def index
    @documents = Document.recent.limit(6)
    @queries = Query.completed.recent.limit(5)
    @provider = Provider.active_provider
    @stats = {
      documents: Document.count,
      chunks: Chunk.count,
      queries: Query.count,
      providers: Provider.count
    }
  end
end
