require "rails_helper"

RSpec.describe Catraca, type: :model do
  let(:restaurante) { Restaurante.create!(nome: "RU Darcy Ribeiro") }

  describe "validações" do
    it "é válida com identificador e restaurante" do
      catraca = Catraca.new(restaurante: restaurante, codigo_identificador: "CAT-01")

      expect(catraca).to be_valid
      expect(catraca.restaurante).to eq(restaurante)
    end

    it "fica com status ativa por padrão" do
      catraca = Catraca.create!(restaurante: restaurante, codigo_identificador: "CAT-01")

      expect(catraca.status).to eq("ativa")
    end

    it "mantém o status informado" do
      catraca = Catraca.create!(restaurante: restaurante, codigo_identificador: "CAT-01",
                                status: "manutencao")

      expect(catraca.status).to eq("manutencao")
    end

    it "é inválida sem identificador" do
      catraca = Catraca.new(restaurante: restaurante, codigo_identificador: "")

      expect(catraca).not_to be_valid
      expect(catraca.errors.full_messages).to include("Identificador não pode ficar em branco")
    end

    it "é inválida sem restaurante" do
      catraca = Catraca.new(codigo_identificador: "CAT-01")

      expect(catraca).not_to be_valid
      expect(catraca.errors.full_messages).to include("Selecione um restaurante")
    end

    it "é inválida com identificador duplicado" do
      Catraca.create!(restaurante: restaurante, codigo_identificador: "CAT-01")
      catraca = Catraca.new(restaurante: restaurante, codigo_identificador: "CAT-01")

      expect(catraca).not_to be_valid
      expect(catraca.errors.full_messages)
        .to include("Já existe uma catraca com este identificador")
    end

    it "permite editar outros campos sem acusar duplicidade do próprio identificador" do
      catraca = Catraca.create!(restaurante: restaurante, codigo_identificador: "CAT-01")
      catraca.status = "inativa"

      expect(catraca).to be_valid
    end
  end
end