Rails.application.routes.draw do
  # Rota raiz (Menu de Testes Visuais da Fase 0)
  root "home#index"
  post "dev_login", to: "home#dev_login"
  delete "dev_logout", to: "home#dev_logout"

  # ============================================================================
  # BLOCOS DEMARCADOS POR INTEGRANTE (Cole suas rotas dentro do seu bloco)
  # ============================================================================

  # --- Eduardo Ruas (Issues #1 e #15) ---
  # Exemplo: resources :usuarios, only: [:new, :create]

  # --- Pablo Trajano (Issues #2 e #11) ---
  # Exemplo: resources :recargas, only: [:new, :create, :show]

  # --- Hagatta Reis (Issues #4 e Bonus) ---
  # Exemplo: get "login", to: "sessions#new"

  # --- Luiz Felipe Bessa (Issues #6 e #10) ---
  # Exemplo: get "cardapio", to: "cardapios#atual"
  get "catraca/operacao", to: "catraca_operacao#show", as: :catraca_operacao
  post "catraca/operacao/leitura", to: "catraca_operacao#ler", as: :catraca_leitura
  post "catraca/operacao/acessos/:id/confirmar", to: "catraca_operacao#confirmar", as: :catraca_confirmar
  post "catraca/operacao/acessos/:id/encerrar", to: "catraca_operacao#encerrar", as: :catraca_encerrar

  # --- Victor Malta (Issues #7 e #8) ---
  # Exemplo: namespace :admin do ... end
end
