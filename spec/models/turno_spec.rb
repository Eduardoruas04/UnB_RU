require "rails_helper"

RSpec.describe Turno, type: :model do
  it "exige um preço positivo para a refeição" do
    turno = described_class.new(nome: "Almoço", horario_inicio: "11:00", horario_fim: "14:00")

    aggregate_failures do
      [ nil, 0, -1 ].each do |valor|
        turno.valor_refeicao_centavos = valor
        expect(turno).not_to be_valid
        expect(turno.errors[:valor_refeicao_centavos]).not_to be_empty
      end

      turno.valor_refeicao_centavos = 450
      expect(turno).to be_valid
    end
  end
end
