# ==============================================================================
# Testes de Requisição HTTP (RSpec): RecargasController (spec/requests/recargas_spec.rb)
# ==============================================================================
# Valida o ciclo completo de requisições e respostas HTTP dos endpoints de recarga:
# - GET /recargas/new (renderização do formulário de recarga com usuário autenticado)
# - GET /recargas/:id (exibição dos detalhes do PIX gerado)
# - POST /recargas/:id/confirmar (confirmação do pagamento e crédito atômico no saldo)
# ==============================================================================

require "rails_helper"

RSpec.describe "Recargas", type: :request do
  # Prepara o usuário estudante para os testes de integração
  let!(:usuario) do
    Usuario.find_or_create_by!(matricula: "221045999") do |u|
      u.nome = "Estudante Teste"
      u.email = "estudante@unb.br"
      u.password = "password123"
      u.papel = "estudante"
      u.ativo = true
    end
  end

  # Cria a carteira com saldo inicial de R$ 18,00 (1800 centavos = 4 refeições)
  let!(:carteira) { usuario.carteira || usuario.create_carteira(saldo_centavos: 1800) }

  # Cria uma recarga de teste prévia com status pendente e identificador PIX
  let!(:recarga) do
    usuario.recargas.create!(
      carteira: carteira,
      quantidade_refeicoes: 5,
      valor_centavos: 2250,
      status: "pendente",
      metodo_pagamento: "PIX Instantâneo",
      txid_pix: "PIX-TESTE"
    )
  end

  # Efetua login automático antes de cada requisição do bloco de testes
  before do
    post "/dev_login", params: { usuario_id: usuario.id }
  end

  # ----------------------------------------------------------------------------
  # GET /recargas/new
  # ----------------------------------------------------------------------------
  describe "GET /new" do
    it "returns http success quando autenticado" do
      get "/recargas/new"
      expect(response).to have_http_status(:success)
    end
  end

  # ----------------------------------------------------------------------------
  # GET /recargas/:id
  # ----------------------------------------------------------------------------
  describe "GET /show" do
    it "returns http success quando autenticado" do
      get "/recargas/#{recarga.id}"
      expect(response).to have_http_status(:success)
    end
  end

  # ----------------------------------------------------------------------------
  # POST /recargas/:id/confirmar (Webhook / Simulação de Pagamento)
  # ----------------------------------------------------------------------------
  describe "POST /recargas/:id/confirmar" do
    it "aprova a recarga e credita a carteira" do
      # Garante que o saldo da carteira é incrementado exatamente pelo valor em centavos
      expect {
        post "/recargas/#{recarga.id}/confirmar"
      }.to change { carteira.reload.saldo_centavos }.by(2250)

      # Valida que o status foi atualizado para pago e ocorreu redirecionamento
      expect(recarga.reload.status).to eq("paga")
      expect(response).to redirect_to(new_recarga_path)
    end
  end
end
