Rails.application.routes.draw do

  resources :official_rates, only: [:index, :show] do
    collection do
      post :update_manual
      get :api_status
    end
  end
  resources :scraps, except: [:show, :index] do
    collection do
      post :import
    end
  end

  resources :supplies
  resources :glassplates

  get "static_pages/home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Nested routes for projects, dvhs, and glasscuttings
  resources :projects do
    member do
      get :pdf
      post :optimize
      post :refresh_glass_prices
      get :confirm_optimization
      post :accept_optimize
      get :cancel_optimize
      get :download_optimization_zip
    end
    collection do
      post :preview_pdf
    end
    resources :dvhs, only: [ :create, :edit ]
    resources :glasscuttings, only: [ :create, :edit ]
  end

  resources :glass_prices do
    collection do
      patch :update_all_percentages
      patch :update_all_supplies_mep
    end
  end
  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "static_pages#home"
end
