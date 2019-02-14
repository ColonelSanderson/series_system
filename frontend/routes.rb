ArchivesSpace::Application.routes.draw do
  resources :mandates
  match 'mandates/:id' => 'mandates#update', :via => [:post]
  match 'mandates/:id/delete' => 'mandates#delete', :via => [:post]

  resources :functions
  match 'functions/:id' => 'functions#update', :via => [:post]
  match 'functions/:id/delete' => 'functions#delete', :via => [:post]

  match '/similar_agencies' => 'similar_agencies#index', :via => [:get]
end
