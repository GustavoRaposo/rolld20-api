Rails.application.routes.draw do
  devise_for :users,
    path: "",
    path_names: {
      sign_in: "api/v1/auth/login",
      sign_out: "api/v1/auth/logout",
      registration: "api/v1/auth/register"
    },
    controllers: {
      sessions: "api/v1/auth/sessions",
      registrations: "api/v1/auth/registrations"
    }

  namespace :api do
    namespace :v1 do
      get "auth/me", to: "auth/users#me"

      resources :campaigns, only: [:index, :create, :show] do
        resources :characters, only: [:create, :show], shallow: true do
          member do
            get  :level_up
            post :level_up
            post :roll_attributes
          end
        end
        resources :turns,    only: [:index, :create]
        resources :memories, only: [:index, :update, :destroy], controller: "campaign_memories"
        resource  :world, only: [:show, :create], controller: "worlds" do
          resources :npcs, only: [:index, :create], controller: "world_npcs"
        end
        member do
          post :start
          post :archive
          get  :recap
        end
      end

      namespace :admin do
        resources :users,     only: [:index, :update]
        resources :campaigns, only: [:index, :destroy]
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
