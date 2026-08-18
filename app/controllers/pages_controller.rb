class PagesController < ApplicationController
  allow_unauthenticated_access

  def home
    @provider = Provider.active_provider
  end
end
