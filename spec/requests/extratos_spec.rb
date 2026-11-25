# frozen_string_literal: true

# ==============================================================================
# Testes de Requisição HTTP (RSpec): ExtratosController (spec/requests/extratos_spec.rb)
# ==============================================================================
# Valida o ciclo completo de requisições e respostas HTTP dos endpoints de extrato:
# - GET /extrato (renderização HTML autenticada e redirecionamento deslogado)
# - GET /extrato/exportar_pdf (geração e entrega do binário application/pdf)
# - Validação de alerta quando não existem registros para exportação
# ==============================================================================

require "rails_helper"

RSpec.describe "Extratos", type: :request do
  let!(:usuario) do
    Usuario.find_or_create_by!(matricula: "221045999") do |u|
      u.nome = "Estudante Teste"
      u.email = "estudante_teste@unb.br"
      u.password = "password123"
      u.papel = "estudante"
      u.ativo = true
    end
  end

  let!(:carteira) { usuario.carteira || usuario.create_carteira(saldo_centavos: 1800) }

  let!(:restaurante) do
    Restaurante.find_or_create_by!(nome: "Restaurante Universitário - Darcy Ribeiro") do |r|
      r.campus = "Darcy Ribeiro"
      r.ativo = true
    end
  end

  let!(:catraca) do
    Catraca.find_or_create_by!(codigo_identificador: "CAT-01") do |c|
      c.restaurante = restaurante
      c.status = "ativa"
    end
  end

  let!(:turno) do
    Turno.find_or_create_by!(nome: "Almoço") do |t|
      t.horario_inicio = "11:00"
      t.horario_fim = "14:00"
      t.valor_refeicao_centavos = 450
    end
  end

  describe "GET /extrato" do
    context "quando o usuário está autenticado" do
      before do
        post "/dev_login", params: { usuario_id: usuario.id }
      end

      it "retorna status HTTP 200 (sucesso)" do
        get "/extrato"
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Extrato e Histórico de Refeições")
      end
    end

    context "quando o usuário não está autenticado" do
      it "redireciona para a página de login" do
        get "/extrato"
        expect(response).to redirect_to("/login")
      end
    end
  end

  describe "GET /extrato/exportar_pdf" do
    context "quando o usuário está autenticado" do
      before do
        post "/dev_login", params: { usuario_id: usuario.id }
      end

      context "e possui lançamentos no extrato" do
        before do
          usuario.recargas.create!(
            carteira: carteira,
            quantidade_refeicoes: 5,
            valor_centavos: 2250,
            status: "paga",
            metodo_pagamento: "PIX Instantâneo"
          )
          usuario.acessos.create!(
            catraca: catraca,
            turno: turno,
            valor_pago_centavos: 450,
            autorizado: true,
            forma_acesso: "QR Code App",
            data_hora: Time.current
          )
        end

        it "entrega um arquivo binário em formato PDF com cabeçalhos de anexo" do
          get "/extrato/exportar_pdf"
          expect(response).to have_http_status(:success)
          expect(response.content_type).to eq("application/pdf")
          expect(response.headers["Content-Disposition"]).to include("attachment")
          expect(response.headers["Content-Disposition"]).to include("extrato_refeicoes_#{usuario.matricula}.pdf")
          expect(response.body).to start_with("%PDF-")
        end
      end

      context "e não possui lançamentos no extrato" do
        before do
          usuario.recargas.destroy_all
          usuario.acessos.destroy_all
        end

        it "redireciona para o extrato com mensagem de alerta" do
          get "/extrato/exportar_pdf"
          expect(response).to redirect_to(extrato_path)
          expect(flash[:alert]).to eq("Não há registros para exportar")
        end
      end
    end

    context "quando o usuário não está autenticado" do
      it "redireciona para a página de login" do
        get "/extrato/exportar_pdf"
        expect(response).to redirect_to("/login")
      end
    end
  end
end
