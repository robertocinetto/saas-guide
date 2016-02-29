Rails.application.routes.draw do

  devise_for :users
  resources :weather_grid

  get  "subscriptions/cancel_subscription" => "subscriptions#cancel_subscription"
  get  "subscriptions/update_card"         => "subscriptions#update_card"
  post "subscriptions/update_card_details" => "subscriptions#update_card_details"
  
  resources :subscriptions

  root 'home#index'

 
end
