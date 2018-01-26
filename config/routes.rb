Rails.application.routes.draw do
  root 'marketing#home'

  get    '/nice_job'                  => 'pages#nice_job', as: :nice_job
  get    '/welcome'                   => 'pages#welcome', as: :welcome
  get    '/thank_you'                 => 'pages#thank_you', as: :thank_you
  get    '/privacy'                   => 'marketing#privacy', as: :privacy
  get    '/running_costs'             => 'marketing#running_costs', as: :running_costs
  get    '/philosophy'                => 'marketing#philosophy', as: :philosophy

  get    '/dashboard'                 => 'dashboard#show', as: :dashboard
  get    '/today'                     => 'today#show', as: :today
  get    '/today/new'                 => 'today#new', as: :new_today
  post   '/today'                     => 'today#create'
  get    '/tomorrow'                  => 'tomorrow#new', as: :tomorrow
  post   '/tomorrow'                  => 'tomorrow#create'
  get    '/reflect/:date'             => 'reflections#new', as: :reflect
  get    '/login'                     => 'sessions#new', as: :login
  post   '/login'                     => 'sessions#create'
  get    '/get_google_sign_in_iframe' => 'sessions#get_google_sign_in_iframe'
  delete '/logout'                    => 'sessions#destroy', as: :logout
  get    '/settings'                  => 'users#edit', as: :settings
  get    '/add_google_sign_in'        => 'users#add_google_sign_in', as: :add_google_sign_in
  get    '/this_week'                 => 'week_plan#show', as: :week_plan
  post   '/add_weekly_todo'           => 'week_plan#add_todo', as: :add_weekly_todo
  post   '/move_weekly_todo'          => 'week_plan#move_todo', as: :move_weekly_todo
  delete '/remove_weekly_todo'        => 'week_plan#remove_todo', as: :remove_weekly_todo

  resources :todos,       only: [:update]
  resources :days,        only: [:show], param: :date
  resources :reflections, only: [:create]
  resources :payments,    only: [:new, :create]
  resources :users

  require 'sidekiq/web'
  mount Sidekiq::Web, at: '/sidekiq'
end
