require "rails_helper"

RSpec.describe Turno, "em atendimento" do
  include ActiveSupport::Testing::TimeHelpers

  let!(:almoco) { Turno.create!(nome: "Almoço", horario_inicio: "11:00", horario_fim: "14:00", valor_refeicao_centavos: 450) }
  let!(:jantar) { Turno.create!(nome: "Jantar", horario_inicio: "17:30", horario_fim: "20:00", valor_refeicao_centavos: 450) }

  def as(hora)
    Time.find_zone("America/Sao_Paulo").parse("2026-11-09 #{hora}")
  end

  it "encontra o turno que está sendo servido" do
    expect(Turno.em_atendimento(as("12:30"))).to eq(almoco)
    expect(Turno.em_atendimento(as("18:00"))).to eq(jantar)
  end

  it "considera o início do turno e não o fim" do
    expect(Turno.em_atendimento(as("11:00"))).to eq(almoco)
    expect(Turno.em_atendimento(as("14:00"))).to be_nil
  end

  it "retorna nil fora dos turnos" do
    expect(Turno.em_atendimento(as("15:30"))).to be_nil
  end

  it "usa o horário atual por padrão" do
    travel_to(as("12:00")) { expect(Turno.em_atendimento).to eq(almoco) }
  end
end
