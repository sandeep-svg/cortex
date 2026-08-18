Rails.application.routes.draw do
  # Public product page — everyone can see this.
  root "pages#home"

  # Auth
  resource :session
  resource :registration, only: %i[new create]
  resources :passwords, param: :token

  # Signed-in users (any role): chat over the document library.
  resources :queries, only: %i[index create] do
    member do
      post :stream
    end
    collection do
      delete :clear
    end
  end

  # Admin-only area
  get "dashboard", to: "dashboard#index"
  resources :users, only: %i[index update]
  resources :documents, only: %i[index show create destroy] do
    member do
      post :reindex
      get :status
    end
  end

  namespace :admin do
    resources :providers, only: %i[index edit update] do
      member do
        post :activate
        post :toggle
        post :test
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
