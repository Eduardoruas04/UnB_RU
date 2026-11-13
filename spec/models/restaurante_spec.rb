require "rails_helper"

RSpec.describe Restaurante, type: :model do
  describe "validações" do
    it "é válido apenas com o nome" do
      expect(Restaurante.new(nome: "RU Darcy Ribeiro")).to be_valid
    end

    it "é inválido sem nome" do
      restaurante = Restaurante.new(nome: "")

      expect(restaurante).not_to be_valid
      expect(restaurante.errors.full_messages).to include("Nome não pode ficar em branco")
    end

    it "é inválido com nome duplicado" do
      Restaurante.create!(nome: "RU Darcy Ribeiro")
      restaurante = Restaurante.new(nome: "RU Darcy Ribeiro")

      expect(restaurante).not_to be_valid
      expect(restaurante.errors.full_messages).to include("Já existe um restaurante com este nome")
    end

    it "não diferencia maiúsculas de minúsculas ao comparar nomes" do
      Restaurante.create!(nome: "RU Darcy Ribeiro")
      restaurante = Restaurante.new(nome: "ru darcy ribeiro")

      expect(restaurante).not_to be_valid
      expect(restaurante.errors.full_messages).to include("Já existe um restaurante com este nome")
    end

    it "permite editar outros campos sem acusar duplicidade do próprio nome" do
      restaurante = Restaurante.create!(nome: "RU Central")
      restaurante.campus = "Asa Norte"

      expect(restaurante).to be_valid
    end

    it "fica ativo por padrão" do
      expect(Restaurante.create!(nome: "RU Central").ativo).to be true
    end
  end

  describe "remoção" do
    it "remove um restaurante sem catracas" do
      restaurante = Restaurante.create!(nome: "RU Central")

      expect(restaurante.destroy).to be_truthy
      expect(Restaurante.exists?(restaurante.id)).to be false
    end

    it "bloqueia a remoção de um restaurante que ainda tem catracas" do
      restaurante = Restaurante.create!(nome: "RU Central")
      Catraca.create!(restaurante: restaurante, codigo_identificador: "CAT-01")

      expect(restaurante.destroy).to be false
      expect(restaurante.errors.full_messages)
        .to include("Remova as catracas deste restaurante antes de excluí-lo")
      expect(Restaurante.exists?(restaurante.id)).to be true
      expect(Catraca.count).to eq(1)
    end
  end
end
