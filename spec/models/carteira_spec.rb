require "rails_helper"

RSpec.describe Carteira, type: :model do
  let(:usuario) { FactoryBot.create(:usuario, matricula: "190012345", password: "senha1234", papel: "estudante") }

  it "persiste uma carteira com saldo inicial zerado" do
    carteira = usuario.create_carteira!(saldo_centavos: 0)

    expect(carteira.reload.saldo_centavos).to eq(0)
  end

  it "rejeita saldo negativo" do
    carteira = usuario.build_carteira(saldo_centavos: -1)

    expect(carteira.save).to be(false)
    expect(carteira.errors.of_kind?(:saldo_centavos, :greater_than_or_equal_to)).to be(true)
  end
end
