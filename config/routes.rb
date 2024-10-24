Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'api/v1/up' => 'rails/health#show', as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      namespace :geo do
        resources :address, only: %i[index]
      end

      namespace :meteo do
        resources :forecast, only: %i[create]
        resources :current_weather, only: %i[create]
      end
    end
  end
end
