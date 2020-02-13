Rails.application.routes.draw do
  resources :law_modifications
  resources :subsections
  resources :sections
  resources :books
  resources :law_tags
  resources :tags
  resources :tag_types
  resources :laws
  resources :titles
  resources :chapters
  resources :articles
  devise_for :users
  devise_for :customer_users, path: '', path_names: { sign_in: 'login', sign_up: 'sign_up'}
  
  root :to => "home#index"
  get '/search_law', to: 'home#search_law'
  get '/terms', to: 'home#terms_and_conditions'

  post "subscribe" => "subscriptions#subscribe", as: "subscribe"
  get "unsubscribe" => "subscriptions#unsubscribe", as: "unsubscribe"
  get "confirm_subscription" => "subscriptions#confirm_subscription", as: "confirm_subscription"
  get "subscriptions/admin" => "subscriptions#admin", as: "subscriptions_admin"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
