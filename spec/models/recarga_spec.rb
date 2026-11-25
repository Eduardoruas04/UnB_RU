# frozen_string_literal: true

# ==============================================================================
# Testes Unitários de Model (RSpec): Recarga (spec/models/recarga_spec.rb)
# ==============================================================================
# Valida as regras de integridade do modelo Recarga (Happy Path e Sad Path):
# - Associações obrigatórias com Usuario e Carteira
# - Presença de quantidade_refeicoes, valor_centavos, status e metodo_pagamento
# - Validação numérica de valor_centavos estritamente positivo
# ==============================================================================

require "rails_helper"

RSpec.describe Recarga, type: :model do
  let(:usuario) do
    Usuario.find_or_create_by!(matricula: "221045999") do |u|
      u.nome = "Estudante Teste"
      u.email = "teste@unb.br"
      u.password = "password123"
      u.papel = "estudante"
      u.ativo = true
    end
  end

  let(:carteira) { usuario.carteira || usuario.create_carteira(saldo_centavos: 0) }

  let(:atributos_validos) do
    {
      carteira: carteira,
      quantidade_refeicoes: 5,
      valor_centavos: 2250,
      status: "pendente",
      metodo_pagamento: "PIX Instantâneo"
    }
  end

  describe "Happy Path" do
    it "é válido com dados completos" do
      recarga = usuario.recargas.build(atributos_validos)
      expect(recarga).to be_valid
    end
  end

  describe "Sad Path" do
    it "é inválido com valor_centavos igual a zero" do
      recarga = usuario.recargas.build(atributos_validos.merge(valor_centavos: 0))
      expect(recarga).not_to be_valid
      expect(recarga.errors[:valor_centavos]).not_to be_empty
    end

    it "é inválido com valor_centavos negativo" do
      recarga = usuario.recargas.build(atributos_validos.merge(valor_centavos: -450))
      expect(recarga).not_to be_valid
      expect(recarga.errors[:valor_centavos]).not_to be_empty
    end

    it "é inválido sem quantidade_refeicoes" do
      recarga = usuario.recargas.build(atributos_validos.merge(quantidade_refeicoes: nil))
      expect(recarga).not_to be_valid
      expect(recarga.errors[:quantidade_refeicoes]).not_to be_empty
    end

    it "é inválido sem status" do
      recarga = usuario.recargas.build(atributos_validos.merge(status: nil))
      expect(recarga).not_to be_valid
      expect(recarga.errors[:status]).not_to be_empty
    end

    it "é inválido sem metodo_pagamento" do
      recarga = usuario.recargas.build(atributos_validos.merge(metodo_pagamento: nil))
      expect(recarga).not_to be_valid
      expect(recarga.errors[:metodo_pagamento]).not_to be_empty
    end

    it "é inválido sem usuario associado" do
      recarga = Recarga.new(atributos_validos)
      expect(recarga).not_to be_valid
      expect(recarga.errors[:usuario]).not_to be_empty
    end

    it "é inválido sem carteira associada" do
      recarga = usuario.recargas.build(atributos_validos.merge(carteira: nil))
      expect(recarga).not_to be_valid
      expect(recarga.errors[:carteira]).not_to be_empty
    end
  end
end
