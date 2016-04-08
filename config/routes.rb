Rails.application.routes.draw do
  
  get 'tokens/create'

  post 'tokens' => "tokens#create"
  #Paths used for facebook login
  get 'auth/:provider/callback', to: 'sessions#create'
  get 'auth/failure', to: redirect('/')
  get 'signout', to: 'sessions#destroy', as: 'signout'
  resources :sessions, only: [:create, :destroy]

  #pages
  post '/game_attendees/:id' => 'game_attendees#create', as: :create_game_attendee
  delete '/game_attendees/:id' => 'game_attendees#destroy', as: :destroy_game_attendee
  resources :games
  resources :users, except: [:new, :create]
  root "home#show"
  
end
