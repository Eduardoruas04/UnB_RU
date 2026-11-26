require "rails_helper"

RSpec.describe ItemCardapio, type: :model do
  it "exige categoria e descrição para o prato" do
    item = described_class.new(cardapio: Cardapio.new)

    expect(item).not_to be_valid
    expect(item.errors.of_kind?(:categoria, :blank)).to be(true)
    expect(item.errors.of_kind?(:descricao, :blank)).to be(true)

    item.assign_attributes(categoria: "prato_principal_padrao", descricao: "Frango assado")
    expect(item).to be_valid
  end
end
