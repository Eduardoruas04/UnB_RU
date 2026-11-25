
require "rails_helper"

RSpec.describe "Recargas", type: :request do
  let!(:usuario) do
    Usuario.find_or_create_by!(matricula: "221045999") do |u|
      u.nome = "Estudante Teste"
      u.email = "estudante@unb.br"
      u.password = "password123"
      u.papel = "estudante"
      u.ativo = true
    end
  end

  let!(:carteira) do
    usuario.carteira || usuario.create_carteira(saldo_centavos: 1800)
  end

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

  before do
    post "/dev_login", params: { usuario_id: usuario.id }
  end

  describe "GET /recargas/new" do
    it "exibe a tela de recarga quando autenticado" do
      get new_recarga_path

      expect(response).to have_http_status(:success)
    end

    it "calcula a quantidade e o valor da recarga informados" do
      get new_recarga_path, params: {
        quantidade_refeicoes: "10"
      }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("10")
      expect(response.body).to include("45,00")
    end

    it "utiliza a quantidade padrão quando o valor informado é inválido" do
      get new_recarga_path, params: {
        quantidade_refeicoes: "0"
      }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("22,50")
    end
  end

  describe "GET /recargas/:id" do
    it "exibe os detalhes da recarga quando autenticado" do
      get recarga_path(recarga)

      expect(response).to have_http_status(:success)
    end

    it "não permite acessar uma recarga pertencente a outro usuário" do
      outro_usuario = Usuario.create!(
        matricula: "221045998",
        nome: "Outro Estudante",
        email: "outro@unb.br",
        password: "password123",
        papel: "estudante",
        ativo: true
      )

      outra_carteira = outro_usuario.create_carteira!(
        saldo_centavos: 0
      )

      outra_recarga = outro_usuario.recargas.create!(
        carteira: outra_carteira,
        quantidade_refeicoes: 5,
        valor_centavos: 2250,
        status: "pendente",
        metodo_pagamento: "PIX Instantâneo",
        txid_pix: "PIX-OUTRO"
      )

      get recarga_path(outra_recarga)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /recargas" do
    it "não cria recarga quando a forma de pagamento não é informada" do
      expect {
        post recargas_path, params: {
          quantidade_refeicoes: "5"
        }
      }.not_to change(Recarga, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Selecione uma forma de pagamento")
    end

    it "não cria recarga quando a quantidade não é numérica" do
      expect {
        post recargas_path, params: {
          metodo_pagamento: "PIX Instantâneo",
          quantidade_refeicoes: "abc"
        }
      }.not_to change(Recarga, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Informe uma quantidade numérica válida")
    end

    it "não cria recarga quando a quantidade é menor que o mínimo permitido" do
      expect {
        post recargas_path, params: {
          metodo_pagamento: "PIX Instantâneo",
          quantidade_refeicoes: "0"
        }
      }.not_to change(Recarga, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("A quantidade mínima é de 1 refeição")
    end

    it "não cria recarga quando a quantidade ultrapassa o limite permitido" do
      expect {
        post recargas_path, params: {
          metodo_pagamento: "PIX Instantâneo",
          quantidade_refeicoes: "101"
        }
      }.not_to change(Recarga, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("A quantidade máxima é de 100 refeições")
    end

    it "aprova o pagamento com cartão de crédito válido" do
      expect {
        post recargas_path, params: {
          metodo_pagamento: "Cartão de Crédito",
          quantidade_refeicoes: "5",
          cartao_status: "valido"
        }
      }.to change(Recarga, :count).by(1)

      expect(response).to redirect_to(new_recarga_path)
      expect(flash[:notice]).to eq("Recarga realizada com sucesso")

      nova_recarga = usuario.recargas.order(:created_at).last

      expect(nova_recarga.status).to eq("paga")
      expect(nova_recarga.valor_centavos).to eq(2250)
      expect(nova_recarga.metodo_pagamento).to eq("Cartão de Crédito")
      expect(carteira.reload.saldo_centavos).to eq(4050)
    end

    it "não aprova o pagamento com cartão vencido" do
      expect {
        post recargas_path, params: {
          metodo_pagamento: "Cartão de Crédito",
          quantidade_refeicoes: "5",
          cartao_status: "vencido"
        }
      }.not_to change(Recarga, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Cartão vencido")
      expect(carteira.reload.saldo_centavos).to eq(1800)
    end

    it "não aprova o pagamento com cartão recusado" do
      expect {
        post recargas_path, params: {
          metodo_pagamento: "Cartão de Crédito",
          quantidade_refeicoes: "5",
          cartao_status: "recusado"
        }
      }.not_to change(Recarga, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Pagamento recusado")
      expect(carteira.reload.saldo_centavos).to eq(1800)
    end

    it "cria uma recarga pendente para pagamento via PIX" do
      expect {
        post recargas_path, params: {
          metodo_pagamento: "PIX Instantâneo",
          quantidade_refeicoes: "3"
        }
      }.to change(Recarga, :count).by(1)

      nova_recarga = usuario.recargas.order(:created_at).last

      expect(response).to redirect_to(recarga_path(nova_recarga))
      expect(nova_recarga.status).to eq("pendente")
      expect(nova_recarga.quantidade_refeicoes).to eq(3)
      expect(nova_recarga.valor_centavos).to eq(1350)
      expect(nova_recarga.metodo_pagamento).to eq("PIX Instantâneo")
      expect(nova_recarga.txid_pix).to be_present
      expect(carteira.reload.saldo_centavos).to eq(1800)
    end
  end

  describe "POST /recargas/:id/confirmar" do
    it "aprova a recarga e credita a carteira" do
      expect {
        post confirmar_recarga_path(recarga)
      }.to change { carteira.reload.saldo_centavos }.by(2250)

      expect(recarga.reload.status).to eq("paga")
      expect(response).to redirect_to(new_recarga_path)
      expect(flash[:notice]).to eq("Recarga realizada com sucesso")
    end

    it "cancela a recarga quando o pagamento expira" do
      expect {
        post confirmar_recarga_path(recarga), params: {
          expirado: "true"
        }
      }.not_to change { carteira.reload.saldo_centavos }

      expect(recarga.reload.status).to eq("cancelada")
      expect(response).to redirect_to(new_recarga_path)
      expect(flash[:alert]).to eq("Pagamento não confirmado")
    end
  end
end
