Rails.application.routes.draw do
  # Rota raiz (Menu de Testes Visuais da Fase 0)
  root "home#index"
  post "dev_login", to: "home#dev_login"
  delete "dev_logout", to: "home#dev_logout"

  # ============================================================================
  # BLOCOS DEMARCADOS POR INTEGRANTE (Cole suas rotas dentro do seu bloco)
  # ============================================================================

  # --- Eduardo Ruas (Issues #1 e #15) ---
  resources :notificacoes, only: [ :index ]
  # Exemplo: resources :usuarios, only: [:new, :create]

  # --- Pablo Trajano (Issues #2 e #11) ---
  # Exemplo: resources :recargas, only: [:new, :create, :show]

  # --- Hagatta Reis (Issues #4 e Bonus) ---
  # Exemplo: get "login", to: "sessions#new"

  # --- Luiz Felipe Bessa (Issues #6 e #10) ---
  # Exemplo: get "cardapio", to: "cardapios#atual"

  # --- Victor Malta (Issues #7 e #8) ---
  # Exemplo: namespace :admin do ... end
end
