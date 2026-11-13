require "rails_helper"

RSpec.describe Acesso, "passagem pela catraca" do
  let(:restaurante) { Restaurante.create!(nome: "RU Darcy Ribeiro", campus: "Darcy Ribeiro", ativo: true) }
  let(:catraca) { Catraca.create!(restaurante: restaurante, codigo_identificador: "CAT-01", status: "ativa") }
  let(:turno) { Turno.create!(nome: "Almoço", horario_inicio: "11:00", horario_fim: "14:00", valor_refeicao_centavos: 500) }
  let(:aluno) { Usuario.create!(nome: "Aluno", matricula: "190012345", email: "aluno@aluno.unb.br", password: "senha123", papel: "estudante", ativo: true) }
  let!(:carteira) { Carteira.create!(usuario: aluno, saldo_centavos: 1000) }
  let(:acesso) do
    Acesso.create!(usuario: aluno, catraca: catraca, turno: turno, autorizado: true, valor_pago_centavos: 0, data_hora: Time.current)
  end

  it "começa aguardando a passagem" do
    expect(acesso.aguardando_passagem?).to be true
  end

  it "debita o preço do turno ao confirmar a passagem" do
    expect(acesso.confirmar_passagem!).to be true
    expect(carteira.reload.saldo_centavos).to eq(500)
    expect(acesso.reload.valor_pago_centavos).to eq(500)
    expect(acesso.aguardando_passagem?).to be false
  end

  it "não debita duas vezes" do
    acesso.confirmar_passagem!
    expect(acesso.confirmar_passagem!).to be false
    expect(carteira.reload.saldo_centavos).to eq(500)
  end

  it "não debita se o saldo ficou insuficiente" do
    carteira.update!(saldo_centavos: 100)
    expect(acesso.confirmar_passagem!).to be false
    expect(carteira.reload.saldo_centavos).to eq(100)
  end

  it "encerra sem passagem sem debitar" do
    expect(acesso.encerrar_sem_passagem!).to be true
    expect(acesso.reload.motivo_recusa).to eq("Passagem não confirmada")
    expect(acesso.autorizado).to be false
    expect(carteira.reload.saldo_centavos).to eq(1000)
    expect(acesso.encerrar_sem_passagem!).to be false
  end
end
