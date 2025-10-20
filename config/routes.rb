Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  mount ActionCable.server => "/cable"

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
  namespace :admin do
    post "categories/create_from_shopping_list_item", to: "categories#create_from_shopping_list_item", as: "create_category_from_shopping_list_item"
  end
  namespace :api do
    namespace :v1 do
      resources :shop_items do
        post "create", on: :collection
        post "create_by_scrape", on: :collection
      end
      resources :shopping_lists, param: :slug, only: [:create, :show, :update, :destroy] do
        resources :shopping_list_items, only: [:create, :destroy, :update], shallow: true
        delete "delete_all_purchased_shopping_list_items", on: :member # Add this line
      end
      resources :users, only: [] do
        post :login_or_create, on: :collection
        patch :update_group_shopping_lists_items_by, on: :collection
        patch :update_active_shopping_list, on: :collection
        post :add_shopping_list, on: :collection
        post :remove_shopping_list, on: :collection
        get :fetch_all_shopping_lists_slugs, on: :collection
      end
      get "/search/products", to: "search#products", defaults: { format: :json }
      get "/search/products_with_shop_items", to: "search#products_with_shop_items", defaults: { format: :json }
      get "categories/:category_uuid/shop_items", to: "categories#shop_items"
    end
  end
end
