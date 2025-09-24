Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "/categories_export", to: "categories_export#index", defaults: { format: :xml }

  # Defines the root path route ("/")
  # root "posts#index"
  #
  # Defines the root path route ("/")
  root "api/v1/search#index"
  get "/search", to: "api/v1/search#index"
  #
  #
  namespace :api do
    namespace :v1 do
      resources :shop_items, only: [:create]
      resources :shopping_lists, param: :slug, only: [:create, :show, :update, :destroy] do
        resources :shopping_list_items, only: [:create, :destroy, :update], shallow: true
      end
      get "/search/products", to: "search#products", defaults: { format: :json }
      get "/search/products_with_shop_items", to: "search#products_with_shop_items", defaults: { format: :json }
    end
  end
end
