# frozen_string_literal: true

# ==============================================================================
# Testes de Requisição HTTP (RSpec): RecargasController (spec/requests/recargas_spec.rb)
# ==============================================================================
# Valida Happy Path e Sad Path de todos os endpoints de recarga:
# - Controle de acesso para usuários não autenticados
# - GET /recargas/new (padrão, pacote/quantidade válida e fallback)
# - POST /recargas (PIX, Cartão válido, validações de entrada, cartão vencido/recusado)
# - GET /recargas/:id (exibição do PIX gerado)
# - POST /recargas/:id/confirmar (aprovação atômica e expiração de prazo)
# ==============================================================================

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

  let!(:carteira) { usuario.carteira || usuario.create_carteira(saldo_centavos: 1800) }

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

  describe "quando o usuário não está autenticado (Sad Path)" do
    it "redireciona GET /recargas/new para /login" do
      get "/recargas/new"
      expect(response).to redirect_to("/login")
    end

    it "redireciona POST /recargas para /login" do
      post "/recargas", params: { metodo_pagamento: "PIX Instantâneo", quantidade_refeicoes: "5" }
      expect(response).to redirect_to("/login")
    end
  end

  describe "quando o usuário está autenticado" do
    before do
      post "/dev_login", params: { usuario_id: usuario.id }
    end

    describe "GET /recargas/new" do
      it "renderiza com sucesso usando quantidade padrão" do
        get "/recargas/new"
        expect(response).to have_http_status(:success)
      end

      it "aceita quantidade inicial informada via parâmetro" do
        get "/recargas/new", params: { quantidade_refeicoes: 10 }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("45,00")
      end

      it "usa fallback para 5 refeições quando parâmetro é menor ou igual a zero" do
        get "/recargas/new", params: { quantidade_refeicoes: 0 }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("22,50")
      end
    end

    describe "POST /recargas" do
      context "Happy Path" do
        it "cria recarga pendente via PIX Instantâneo com TXID e redireciona para show" do
          expect {
            post "/recargas", params: { metodo_pagamento: "PIX Instantâneo", quantidade_refeicoes: "5" }
          }.to change(Recarga, :count).by(1)

          nova_recarga = Recarga.order(:id).last
          expect(nova_recarga.status).to eq("pendente")
          expect(nova_recarga.metodo_pagamento).to eq("PIX Instantâneo")
          expect(nova_recarga.valor_centavos).to eq(2250)
          expect(nova_recarga.txid_pix).to start_with("PIX-")
          expect(response).to redirect_to(recarga_path(nova_recarga))
        end

        it "cria recarga paga via Cartão de Crédito válido e credita a carteira imediatamente" do
          expect {
            post "/recargas", params: {
              metodo_pagamento: "Cartão de Crédito",
              quantidade_refeicoes: "4",
              cartao_status: "valido"
            }
          }.to change { carteira.reload.saldo_centavos }.by(1800)

          nova_recarga = Recarga.order(:id).last
          expect(nova_recarga.status).to eq("paga")
          expect(nova_recarga.metodo_pagamento).to eq("Cartão de Crédito")
          expect(flash[:notice]).to eq("Recarga realizada com sucesso")
          expect(response).to redirect_to(new_recarga_path)
        end
      end

      context "Sad Path" do
        it "rejeita quando forma de pagamento está ausente" do
          post "/recargas", params: { metodo_pagamento: "", quantidade_refeicoes: "5" }
          expect(response).to have_http_status(:unprocessable_content)
          expect(flash.now[:alert]).to eq("Selecione uma forma de pagamento")
        end

        it "rejeita quando quantidade está em branco" do
          post "/recargas", params: { metodo_pagamento: "PIX Instantâneo", quantidade_refeicoes: "" }
          expect(response).to have_http_status(:unprocessable_content)
          expect(flash.now[:alert]).to eq("Informe uma quantidade numérica válida")
        end

        it "rejeita quando quantidade não é numérica" do
          post "/recargas", params: { metodo_pagamento: "PIX Instantâneo", quantidade_refeicoes: "abc" }
          expect(response).to have_http_status(:unprocessable_content)
          expect(flash.now[:alert]).to eq("Informe uma quantidade numérica válida")
        end

        it "rejeita quando quantidade é menor que 1" do
          post "/recargas", params: { metodo_pagamento: "PIX Instantâneo", quantidade_refeicoes: "0" }
          expect(response).to have_http_status(:unprocessable_content)
          expect(flash.now[:alert]).to eq("A quantidade mínima é de 1 refeição")
        end

        it "rejeita quando quantidade é negativa" do
          post "/recargas", params: { metodo_pagamento: "PIX Instantâneo", quantidade_refeicoes: "-3" }
          expect(response).to have_http_status(:unprocessable_content)
          expect(flash.now[:alert]).to eq("A quantidade mínima é de 1 refeição")
        end

        it "rejeita quando quantidade excede 100 refeições" do
          post "/recargas", params: { metodo_pagamento: "PIX Instantâneo", quantidade_refeicoes: "101" }
          expect(response).to have_http_status(:unprocessable_content)
          expect(flash.now[:alert]).to eq("A quantidade máxima é de 100 refeições")
        end

        it "rejeita pagamento com cartão vencido sem alterar o saldo" do
          expect {
            post "/recargas", params: {
              metodo_pagamento: "Cartão de Crédito",
              quantidade_refeicoes: "5",
              cartao_status: "vencido"
            }
          }.not_to change { carteira.reload.saldo_centavos }

          expect(response).to have_http_status(:unprocessable_content)
          expect(flash.now[:alert]).to eq("Cartão vencido")
        end

        it "rejeita pagamento com cartão recusado sem alterar o saldo" do
          expect {
            post "/recargas", params: {
              metodo_pagamento: "Cartão de Crédito",
              quantidade_refeicoes: "5",
              cartao_status: "recusado"
            }
          }.not_to change { carteira.reload.saldo_centavos }

          expect(response).to have_http_status(:unprocessable_content)
          expect(flash.now[:alert]).to eq("Pagamento recusado")
        end
      end
    end

    describe "GET /recargas/:id" do
      it "retorna sucesso ao exibir detalhes do PIX" do
        get "/recargas/#{recarga.id}"
        expect(response).to have_http_status(:success)
      end
    end

    describe "POST /recargas/:id/confirmar" do
      it "aprova a recarga e credita a carteira (Happy Path)" do
        expect {
          post "/recargas/#{recarga.id}/confirmar"
        }.to change { carteira.reload.saldo_centavos }.by(2250)

        expect(recarga.reload.status).to eq("paga")
        expect(flash[:notice]).to eq("Recarga realizada com sucesso")
        expect(response).to redirect_to(new_recarga_path)
      end

      it "cancela a recarga quando o prazo do PIX expira sem alterar o saldo (Sad Path)" do
        expect {
          post "/recargas/#{recarga.id}/confirmar", params: { expirado: "true" }
        }.not_to change { carteira.reload.saldo_centavos }

        expect(recarga.reload.status).to eq("cancelada")
        expect(flash[:alert]).to eq("Pagamento não confirmado")
        expect(response).to redirect_to(new_recarga_path)
      end
    end
  end
end
