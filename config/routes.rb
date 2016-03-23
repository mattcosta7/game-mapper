Rails.application.routes.draw do

  #Paths used for facebook login
  get 'auth/:provider/callback', to: 'sessions#create'
  get 'auth/failure', to: redirect('/')
  get 'signout', to: 'sessions#destroy', as: 'signout'
  resources :sessions, only: [:create, :destroy]

  #pages
  resources :games
  resources :users, except: [:new, :create]
  root "home#show"
  
end
