Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "todos#index"
  resources :todos do
    patch :toggle, on: :member
  end
end
