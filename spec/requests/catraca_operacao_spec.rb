require "rails_helper"

RSpec.describe "Operação da catraca", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:restaurante) { Restaurante.create!(nome: "RU Darcy Ribeiro", campus: "Darcy Ribeiro", ativo: true) }
  let!(:catraca) { Catraca.create!(restaurante: restaurante, codigo_identificador: "CAT-01", status: "ativa") }
  let!(:turno) { Turno.create!(nome: "Almoço", horario_inicio: "11:00", horario_fim: "14:00", valor_refeicao_centavos: 500) }
  let(:aluno) { Usuario.create!(nome: "Aluno", matricula: "190012345", email: "aluno@aluno.unb.br", password: "senha123", papel: "estudante", ativo: true) }

  around { |exemplo| travel_to(Time.find_zone("America/Sao_Paulo").parse("2026-11-09 12:00")) { exemplo.run } }

  def ler(matricula)
    post catraca_leitura_path, params: { matricula: matricula }
    follow_redirect!
  end

  it "mostra o terminal" do
    get catraca_operacao_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("CAT-01")
  end

  it "libera o aluno com saldo sem debitar" do
    Carteira.create!(usuario: aluno, saldo_centavos: 1000)
    ler("190012345")
    expect(response.body).to include("Comando de liberação enviado")
    expect(aluno.carteira.reload.saldo_centavos).to eq(1000)
    expect(Acesso.last.aguardando_passagem?).to be true
  end

  it "nega com saldo insuficiente" do
    Carteira.create!(usuario: aluno, saldo_centavos: 499)
    ler("190012345")
    expect(response.body).to include("Saldo insuficiente")
    expect(Acesso.last.motivo_recusa).to eq("Saldo insuficiente")
  end

  it "nega aluno não cadastrado" do
    ler("000000000")
    expect(response.body).to include("Aluno não cadastrado")
    expect(Acesso.count).to eq(0)
  end

  it "nega quando não há refeição em atendimento" do
    turno.destroy
    Carteira.create!(usuario: aluno, saldo_centavos: 1000)
    ler("190012345")
    expect(response.body).to include("Nenhuma refeição em atendimento")
  end

  it "confirma a passagem e debita" do
    Carteira.create!(usuario: aluno, saldo_centavos: 1000)
    ler("190012345")
    post catraca_confirmar_path(Acesso.last)
    follow_redirect!
    expect(response.body).to include("Passagem confirmada")
    expect(aluno.carteira.reload.saldo_centavos).to eq(500)
  end

  it "encerra sem passagem e não debita" do
    Carteira.create!(usuario: aluno, saldo_centavos: 1000)
    ler("190012345")
    post catraca_encerrar_path(Acesso.last)
    follow_redirect!
    expect(response.body).to include("Entrada encerrada sem passagem")
    expect(aluno.carteira.reload.saldo_centavos).to eq(1000)
  end

  it "não confirma um acesso que não está aguardando passagem" do
    Carteira.create!(usuario: aluno, saldo_centavos: 1000)
    ler("190012345")
    acesso = Acesso.last
    acesso.encerrar_sem_passagem!
    post catraca_confirmar_path(acesso)
    follow_redirect!
    expect(response.body).to include("Este acesso não está aguardando passagem")
  end
end
