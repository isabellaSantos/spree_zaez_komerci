Spree::Core::Engine.routes.draw do
  namespace :admin do
    resource :komerci_settings, only: [:show, :edit, :update]
  end
end
