require "rails_helper"

RSpec.describe Carteira, "saldo para a refeição" do
  let(:aluno) { Usuario.create!(nome: "Aluno", matricula: "190012345", email: "aluno@aluno.unb.br", password: "senha123", papel: "estudante", ativo: true) }
  let(:carteira) { Carteira.create!(usuario: aluno, saldo_centavos: 500) }

  describe "#cobre?" do
    it "cobre um valor igual ao saldo" do
      expect(carteira.cobre?(500)).to be true
    end

    it "cobre um valor menor que o saldo" do
      expect(carteira.cobre?(1)).to be true
    end

    it "não cobre um valor maior que o saldo" do
      expect(carteira.cobre?(501)).to be false
    end
  end

  describe "#debitar!" do
    it "desconta o valor do saldo" do
      carteira.debitar!(200)
      expect(carteira.reload.saldo_centavos).to eq(300)
    end

    it "recusa um débito que deixaria o saldo negativo" do
      expect { carteira.debitar!(501) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(carteira.reload.saldo_centavos).to eq(500)
    end
  end
end
