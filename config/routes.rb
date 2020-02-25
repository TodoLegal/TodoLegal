Rails.application.routes.draw do
  resources :user_permissions
  resources :permissions
  resources :law_modifications
  resources :subsections
  resources :sections
  resources :books
  devise_for :users
  resources :law_tags
  resources :tags
  resources :tag_types
  resources :laws
  resources :titles
  resources :chapters
  resources :articles

  root :to => "home#index"
  get '/search_law', to: 'home#search_law'
  get '/terms', to: 'home#terms_and_conditions'

  post "subscribe" => "subscriptions#subscribe", as: "subscribe"
  get "unsubscribe" => "subscriptions#unsubscribe", as: "unsubscribe"
  get "confirm_subscription" => "subscriptions#confirm_subscription", as: "confirm_subscription"
  get "admin/users" => "admin#users", as: "admin_users"
  post "admin/grant_permission" => "admin#grant_permission", as: "admin_grant_permission"
  post "admin/revoke_permission" => "admin#revoke_permission", as: "admin_revoke_permission"
  get "admin/subscriptions" => "admin#subscriptions", as: "admin_subscriptions"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
