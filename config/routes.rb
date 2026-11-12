Rails.application.routes.draw do
  # Rota raiz (Menu de Testes Visuais da Fase 0)
  root "home#index"

  # Rota provisoria de fallback para login enquanto a Issue #4 (Hagatta) esta sendo desenvolvida
  get "login", to: "home#index"

  # Acoes de login e logout rapido da Central de Testes (Fase 0)
  post "dev_login", to: "home#dev_login"
  delete "dev_logout", to: "home#dev_logout"

  # ============================================================================
  # BLOCOS DEMARCADOS POR INTEGRANTE (Cole suas rotas dentro do seu bloco)
  # ============================================================================

  # --- Eduardo Ruas (Issues #1 e #15) ---
  # Exemplo: resources :usuarios, only: [:new, :create]

  # --- Pablo Trajano (Issues #2 e #11) ---
  # Issue #2 (MVP): Recarga de Saldo de Refeicoes com PIX e Cartao (Figma US03)
  # - GET  /recargas/new           => Formulario de recarga com pacotes e calculo dinâmico
  # - POST /recargas               => Processa a compra (gera PIX pendente ou aprova cartao)
  # - GET  /recargas/:id           => Tela de pagamento PIX com QR Code e chave copia-e-cola
  # - POST /recargas/:id/confirmar => Simula compensacao bancaria, credita carteira via transacao ACID
  resources :recargas, only: [ :new, :create, :show ] do
    member do
      post :confirmar
    end
  end

  # --- Hagatta Reis (Issues #4 e Bonus) ---
  # Exemplo: get "login", to: "sessions#new"

  # --- Luiz Felipe Bessa (Issues #6 e #10) ---
  # Exemplo: get "cardapio", to: "cardapios#atual"

  # --- Victor Malta (Issues #7 e #8) ---
  # Exemplo: namespace :admin do ... end
end
