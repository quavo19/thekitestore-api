Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Assistant service boundary: disabled unless explicitly configured; no general JWTs.
      namespace :assistant do
        get "catalog", to: "catalog#index"
        get "catalog/:id", to: "catalog#show"
        get "catalog/:id/availability", to: "catalog#availability"
        post "onboarding/authenticate", to: "onboarding#authenticate"
        post "onboarding/verify", to: "onboarding#verify"
        post "delegations/exchange", to: "delegations#exchange"
        post "delegations/validate", to: "delegations#validate"
        post "delegations/revoke", to: "delegations#revoke"
      end

      # Authentication routes
      devise_for :users, path: "auth", path_names: {
        sign_in: "login",
        sign_out: "logout",
        registration: "signup",
        password: "password"
      },
      controllers: {
        sessions: "api/v1/auth/sessions",
        registrations: "api/v1/auth/registrations",
        passwords: "api/v1/auth/passwords",
        omniauth_callbacks: "api/v1/auth/omniauth_callbacks"
      }

      # User management routes
      namespace :users do
        post "otp/verify", to: "otp#verify"
        post "otp/toggle", to: "otp#toggle"
        get "profile", to: "profile#show"
        put "profile", to: "profile#update"
        patch "profile", to: "profile#update"
        put "password", to: "passwords#update"
        patch "password", to: "passwords#update"
      end

      # Admin routes
      resources :roles, only: [ :index, :update ]
      resources :permissions, only: [ :index ]
      post "uploads", to: "uploads#create"
      post "uploads/presign", to: "uploads#presign"
      post "uploads/confirm", to: "uploads#confirm"
      delete "uploads", to: "uploads#destroy"
      resource :affiliate_profile, only: [ :show, :create, :update ]
      resource :affiliate_dashboard, only: [ :show ], controller: "affiliate_dashboard"
      resource :affiliate_settings, only: [ :show, :update ]
      resource :affiliate_payout_settings, only: [ :show, :update ]
      resources :affiliate_signup_referrals, only: [ :create ]
      resources :affiliate_withdrawals, only: [ :index, :create ]
      resources :admin_affiliate_withdrawals, path: "affiliate_withdrawal_requests", only: [ :index ] do
        member do
          post :approve
          post :reject
          post :pay
        end
      end
      resources :transactions, only: [ :index ]
      resources :affiliate_clicks, only: [ :create ]
      resources :affiliates, only: [ :index, :show, :update ] do
        member do
          post :approve
          post :reject
          post :suspend
          post :reactivate
        end
      end
      resources :categories, only: [ :index, :show, :create, :update, :destroy ]
      resources :sub_categories, only: [ :index, :show, :create, :update, :destroy ]
      resources :delivery_zones, only: [ :index, :show, :create, :update, :destroy ]
      resources :delivery_weight_tiers, only: [ :index, :show, :create, :update, :destroy ]
      resources :delivery_high_value_rates, only: [ :index, :show, :create, :update, :destroy ]
      resource :delivery_settings, only: [ :show, :update ]
      resources :contacts, only: [ :index, :create, :destroy ], controller: "contacts"
      resources :support_requests, only: [ :index, :show, :create, :update, :destroy ]
      resources :badges, only: [ :index, :show, :create, :update, :destroy ] do
        member do
          post "users/:user_id", to: "badges#add_user", as: :add_user
          delete "users/:user_id", to: "badges#remove_user", as: :remove_user
        end
      end

      # User management (admin only)
      resources :users, only: [ :index, :show ], controller: "users/users" do
        member do
          post "role/:role_id", to: "users/users#assign_role", as: "assign_role"
          post "permissions", to: "users/users#assign_permissions"
          delete "permissions", to: "users/users#unassign_permissions"
          post "block", to: "users/users#block"
          post "unblock", to: "users/users#unblock"
        end
      end

      # Payments
      namespace :payments do
        post "paystack/initialize", to: "paystack#initialize_payment"
        get "paystack/verify", to: "paystack#verify"
        post "paystack/webhook", to: "paystack#webhook"
      end

      namespace :products do
        resources :products, only: [ :index, :show, :create, :update, :destroy ] do
          resources :reviews, only: [ :index, :create, :destroy ], controller: "reviews"
          resources :product_meta, only: [ :index, :create, :update, :destroy ], controller: "product_meta"
          resources :variants, only: [ :index, :create ], controller: "variants"
          resources :images, only: [ :index, :create, :destroy ], controller: "products/images", path_names: { images: "images" }
        end
        resources :variants, only: [ :show, :update, :destroy ], controller: "variants" do
          get "options", to: "variants#index_options"
          post "options", to: "variants#create_option"
          put "options/:option_id", to: "variants#update_option"
          patch "options/:option_id", to: "variants#update_option"
          delete "options/:option_id", to: "variants#destroy_option"
          get "options/:option_id/images", to: "variants/images#index"
          post "options/:option_id/images", to: "variants/images#create"
          delete "options/:option_id/images/:id", to: "variants/images#destroy"
        end
        resources :images, only: [ :index, :create, :update, :destroy ], controller: "images"
      end

      namespace :inventory do
        resources :variant_stocks, only: [ :index, :show, :create, :update, :destroy ]
        resources :downtimes, only: [ :index, :create, :show, :update, :destroy ] do
          member do
            post :end_early
          end
        end
      end

      resources :orders, only: [ :index, :create, :show, :update, :destroy ], controller: "orders/orders" do
        member do
          post :cancel
        end
      end

      resources :warehouses, only: [ :index, :create, :show, :update, :destroy ] do
        resources :images, only: [ :index, :create, :destroy ], controller: "warehouses/images"
      end

      # Customer routes
      namespace :customer do
        resources :delivery_zones, only: [ :index ], controller: "delivery_zones"
        resources :products, only: [ :index, :show ], controller: "products/products" do
          resources :reviews, only: [ :index, :create ], controller: "products/reviews"
        end
        resources :cart_items, path: "cart", only: [ :index, :create, :update, :destroy ]
        resources :wishlist_items, path: "wishlist", only: [ :index, :create, :destroy ]
        resources :addresses, only: [ :index, :show, :create, :update, :destroy ], controller: "addresses/addresses" do
          member do
            post :set_default
          end
        end
        resources :warehouses, only: [ :index ], controller: "warehouses/warehouses"
        scope module: "orders", path: "orders" do
          resources :orders, only: [ :index, :show, :create ], controller: "orders" do
            member do
              post :mark_received
            end
          end
        end
      end

      # Customer admin / staff order management routes
      namespace :customer_admin do
        scope module: "orders", path: "orders" do
          resources :orders, only: [ :index, :show, :update ], controller: "orders" do
            collection do
              get :assigned
            end
          end
        end
      end
    end
  end

  # Sidekiq Web UI
  # In development: open access
  # In production: requires HTTP Basic Auth (set SIDEKIQ_USERNAME and SIDEKIQ_PASSWORD env vars)
  if defined?(Sidekiq::Web)
    if Rails.env.development?
      mount Sidekiq::Web => "/sidekiq"
    elsif Rails.env.production?
      # Add HTTP Basic Auth for production
      require "rack/auth/basic"
      Sidekiq::Web.use Rack::Auth::Basic do |username, password|
        ActiveSupport::SecurityUtils.secure_compare(
          ::Digest::SHA256.hexdigest(username),
          ::Digest::SHA256.hexdigest(ENV.fetch("SIDEKIQ_USERNAME", ""))
        ) &
        ActiveSupport::SecurityUtils.secure_compare(
          ::Digest::SHA256.hexdigest(password),
          ::Digest::SHA256.hexdigest(ENV.fetch("SIDEKIQ_PASSWORD", ""))
        )
      end
      mount Sidekiq::Web => "/sidekiq"
    end
  end
end
