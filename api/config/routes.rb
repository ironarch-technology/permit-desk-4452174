Rails.application.routes.draw do
  get '/health', to: 'health#show'

  post '/sessions', to: 'sessions#create'

  resources :applications, only: %i[index show create update destroy] do
    member do
      post 'submit'
      post 'withdraw'
    end
    resource :corrections, only: %i[show create], controller: 'corrections'
    resource :payment, only: %i[create], controller: 'payments'
    resources :inspections, only: %i[index create]
  end

  get '/parcels/lookup', to: 'parcels#lookup'

  namespace :staff do
    get '/searches', to: 'searches#index'
    post '/zoning_holds/:id/resolve', to: 'zoning_holds#resolve'
  end

  post '/hooks/zoning', to: 'hooks#zoning'
  post '/hooks/cashiering', to: 'hooks#cashiering'
end
