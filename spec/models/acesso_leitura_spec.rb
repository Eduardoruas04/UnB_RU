require "rails_helper"

RSpec.describe Acesso, ".registrar_leitura!" do
  let(:restaurante) { Restaurante.create!(nome: "RU Darcy Ribeiro", campus: "Darcy Ribeiro", ativo: true) }
  let(:catraca) { Catraca.create!(restaurante: restaurante, codigo_identificador: "CAT-01", status: "ativa") }
  let(:turno) { Turno.create!(nome: "Almoço", horario_inicio: "11:00", horario_fim: "14:00", valor_refeicao_centavos: 500) }
  let(:aluno) { Usuario.create!(nome: "Aluno", matricula: "190012345", email: "aluno@aluno.unb.br", password: "senha123", papel: "estudante", ativo: true) }

  def registrar
    Acesso.registrar_leitura!(usuario: aluno, catraca: catraca, turno: turno)
  end

  it "libera o aluno cujo saldo cobre a refeição, sem debitar" do
    Carteira.create!(usuario: aluno, saldo_centavos: 500)
    acesso = registrar
    expect(acesso).to be_persisted
    expect(acesso.autorizado).to be true
    expect(acesso.motivo_recusa).to be_nil
    expect(acesso.aguardando_passagem?).to be true
    expect(aluno.carteira.reload.saldo_centavos).to eq(500)
  end

  it "recusa por saldo insuficiente" do
    Carteira.create!(usuario: aluno, saldo_centavos: 499)
    acesso = registrar
    expect(acesso.autorizado).to be false
    expect(acesso.motivo_recusa).to eq("Saldo insuficiente")
    expect(acesso.aguardando_passagem?).to be false
  end

  it "recusa o aluno sem carteira" do
    acesso = registrar
    expect(acesso.autorizado).to be false
    expect(acesso.motivo_recusa).to eq("Saldo insuficiente")
  end
end
