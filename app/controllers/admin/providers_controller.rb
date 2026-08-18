module Admin
  class ProvidersController < ApplicationController
    before_action :require_admin
    before_action :set_provider, only: %i[edit update activate toggle test]

    def index
      @providers = Provider.ordered
      @active_provider = Provider.active_provider
    end

    def edit
    end

    def update
      if @provider.update(provider_params)
        redirect_to admin_providers_path, notice: "Saved #{@provider.name} configuration."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # Only one provider can be the chat provider at a time.
    def activate
      Provider.update_all(active: false)
      @provider.update!(active: true)
      redirect_to admin_providers_path, notice: "#{@provider.name} is now the active chat provider."
    end

    def toggle
      @provider.update!(enabled: !@provider.enabled)
      redirect_to admin_providers_path, notice: "#{@provider.name} #{@provider.enabled? ? 'enabled' : 'disabled'}."
    end

    # Live sanity check: embed a ping + ask a one-liner through the real API.
    def test
      result = TestProviderService.call(@provider)
      if result[:ok]
        flash[:notice] = "OK — #{result[:details]}"
      else
        flash[:alert] = "Failed: #{result[:error]}"
      end
      redirect_to admin_providers_path
    end

    private

    def set_provider
      @provider = Provider.find(params[:id])
    end

    def provider_params
      params.require(:provider).permit(:api_key, :base_url, :api_version, :chat_model, :embedding_model, :embedding_dimensions, :enabled, :notes)
    end
  end
end
