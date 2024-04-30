Rails.application.routes.draw do
  resources :verification_histories
  resources :datapoints
  resources :users_preferences, only: [:index, :edit, :update, :create]
  resources :users_preferences_tags
  require 'sidekiq/web'


    


  resources :alternative_tag_names
  use_doorkeeper
  resources :documents
  resources :user_permissions
  resources :permissions
  resources :law_modifications
  devise_for :users, controllers: { 
    confirmations: 'users/confirmations', 
    registrations: "users/registrations", 
    sessions: "users/sessions",
    omniauth_callbacks: 'users/omniauth_callbacks', 
    passwords: "users/passwords" 
  }
  get "/token_login/:authentication_token" => "home#token_login", as: "token_login"
  resources :law_tags
  resources :document_tags
  resources :issuer_document_tags
  resources :tags
  resources :tag_types
  resources :laws
  resources :titles, only: [:edit, :update]
  resources :books, only: [:edit, :update]
  resources :chapters, only: [:edit, :update]
  resources :sections, only: [:edit, :update]
  resources :subsections, only: [:edit, :update]
  resources :articles, only: [:edit, :update, :destroy]


  root :to => "home#index"
  get '/search_law', to: 'home#search_law'
  get '/pricing', to: 'home#pricing'
  get '/invite_friends', to: 'home#invite_friends'
  get '/covid', to: 'home#google_drive_covid_search', as: "google_drive_covid_search"
  get '/drive_search', to: 'home#google_drive_covid_search', as: "drive_search"
  get '/refer', to: 'home#refer', as: "refer"
  get '/crash_tester', to: 'home#crash_tester', as: "crash_tester"
  get '/maintenance', to: 'home#maintenance', as: "maintenance"
  get '/checkout', to: 'billing#checkout', as: "checkout"
  post "/charge" => "billing#charge", as: "charge"
  post "/create_customer_portal_session" => "billing#create_customer_portal_session", as: "create_customer_portal_session"
  get '/home', to: 'home#home'
  get "/home/send_confirmation_email" => "home#send_confirmation_email", as: "send_confirmation_email"
  get "admin/users" => "admin#users", as: "admin_users"
  post "admin/grant_permission" => "admin#grant_permission", as: "admin_grant_permission"
  post "admin/revoke_permission" => "admin#revoke_permission", as: "admin_revoke_permission"
  post "admin/set_law_access" => "admin#set_law_access", as: "admin_set_law_access"
  post 'adduser', to: 'mailing_list#addEmail', as: "add_to_mailing_list"
  get 'admin/enable_edit_mode', to: 'admin#enable_edit_mode', as: "enable_edit_mode"
  get 'admin/disable_edit_mode', to: 'admin#disable_edit_mode', as: "disable_edit_mode"
  get 'admin/gazettes', to: 'admin#gazettes', as: "gazettes"
  get 'admin/mailchimp', to: 'admin#mailchimp', as: "admin_mailchimp"
  get 'admin/gazettes/:publication_number', to: 'admin#gazette', as: "gazette"
  get "signed_in" => "home#index", as: "signed_in"
  get "signed_up" => "home#index", as: "signed_up"
  get "signed_out" => "home#index", as: "signed_out"
  get "download_all_users" => "admin#download_all_users", as: "download_all_users"
  get '/gacetas', to: redirect('https://valid.todolegal.app'), as: "google_drive_search"
  post "admin/deactivate_notifications" => "admin#deactivate_notifications", as: "deactivate_notifications"
  post "admin/activate_notifications" => "admin#activate_notifications", as: "activate_notifications"
  get 'users_preferences/skip_notifications', to: 'users_preferences#skip_notifications', as: "skip_notifications"
  get '/confirm_email_view', to: 'home#confirm_email_view', as:"confirm_email_view"
  post "admin/activate_batch_of_users" => "admin#activate_batch_of_users", as: "activate_batch_of_users"
  post "laws/insert_article", to: "laws#insert_article", as: "insert_article"
  post "documents/process_documents_batch", to: "documents#process_documents_batch", as: "process_documents_batch"

  get '/rails/active_storage/blobs/redirect/:signed_id/*filename', to: 'active_storage_redirect#show'
  
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  namespace :api, defaults: {format: :json} do
    namespace :v1 do
      devise_for :users, controllers: { registrations: 'api/v1/registrations', sessions: 'api/v1/sessions' }
      devise_scope :user do
        get "/me", to: 'sessions#me'
      end
      resource :examples do
        member do
          get :action_test
        end
      end
      resource :documents do
        member do
          get "/:id", to: 'documents#get_document'
          get "/", to: 'documents#get_documents'
        end
      end
      resource :laws do
        member do
          get "/:id", to: 'laws#get_law'
        end
      end
      resource :tags do
        member do
          get "/", to: 'tags#get_tags'
          get "/preference_tags", to: 'tags#get_preference_tags_list'
        end
      end
      resource :users_preferences do
        member do
          get "/", to: 'users_preferences#get_user_preferences'
          patch "/", to: 'users_preferences#update'
          patch "/deactivate_notifications", to: 'users_preferences#deactivate_notifications'
        end
      end
    end
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
