Rails.application.routes.draw do
  root 'setup#index'
  get 'ping', to: 'ping#index', as: 'ping'

  devise_for :users, skip: [:sessions]

  resources :guests, only: [:index, :create]

  get '/setup', to: 'setup#index', as: 'setup'
  get '/setup/recheck', to: 'setup#recheck', as: 'recheck_setup'
  post '/setup/perform', to: 'setup#perform', as: 'perform_setup'

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
end
