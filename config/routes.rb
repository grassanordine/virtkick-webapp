Rails.application.routes.draw do
  root 'setup#index'
  get 'ping', to: 'ping#index', as: 'ping'

  devise_for :users

  resources :guests, only: [:index, :create]

  get '/setup', to: 'setup#index', as: 'setup'
  get '/setup/recheck', to: 'setup#recheck', as: 'recheck_setup'
  post '/setup/perform/:mode', to: 'setup#perform', as: 'perform_setup'

  # get '/billing', to: 'billing#index', as: 'billing'
  # put '/billing', to: 'billing#update', as: 'billing_update'
  # post '/billing/payment', to: 'billing#payment', as: 'billing_payment'
  # get '/billing/usage', to: 'billing#usage', as: 'billing_usage'
  # get '/billing/invoices', to: 'billing#invoices', as: 'billing_invoices'

  # namespace :billing do
  #   resource :payment do
  #
  #   end
  #   resource :method do
  #
  #   end
  #   resources :invoices do
  #     member do
  #
  #     end
  #   end
  # end
  # resource :billing

  # get '/billing/data', to: :data
  # post '/billing/data', to: :data


  resources :machines do
    member do
      get 'power'
      get 'console'
      get 'storage'
      get 'settings'

      post 'start'
      post 'pause'
      post 'resume'
      post 'stop'
      post 'force_stop'
      post 'restart'
      post 'force_restart'

      post 'mount_iso'

      get 'state'
      get 'vnc'
    end

    resources :disks do
      member do
        post 'resize'
        post 'snapshot'
      end
    end
  end

  get '/progress/:id', to: 'progress#progress', as: 'progress'
  get '/machine_progress/:id', to: 'progress#machine', as: 'machine_progress'

  # mount Payment::Engine => '/payment'
end
