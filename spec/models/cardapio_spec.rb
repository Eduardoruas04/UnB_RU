require "rails_helper"

RSpec.describe Cardapio, type: :model do
  it "exige uma data para a refeição" do
    cardapio = described_class.new(
      restaurante: Restaurante.new(nome: "RU Darcy Ribeiro"),
      turno: Turno.new(nome: "Almoço", horario_inicio: "11:00", horario_fim: "14:00",
                       valor_refeicao_centavos: 450)
    )

    expect(cardapio).not_to be_valid
    expect(cardapio.errors.of_kind?(:data_refeicao, :blank)).to be(true)

    cardapio.data_refeicao = Date.new(2026, 11, 26)
    expect(cardapio).to be_valid
  end
end
