require "rails_helper"

RSpec.describe InscricaoFastpass, type: :model do
  let(:usuario) { FactoryBot.create(:usuario, matricula: "190012345", password: "senha1234", papel: "estudante") }
  let(:sorteio) { FactoryBot.create(:sorteio_fastpass, turno: FactoryBot.create(:turno)) }

  it "persiste uma inscrição pendente para um estudante e um sorteio" do
    inscricao = sorteio.inscricoes_fastpass.create!(usuario: usuario, status: "pendente")

    expect(sorteio.inscricoes_fastpass.reload.sole).to eq(inscricao)
    expect(inscricao.reload.usuario).to eq(usuario)
  end

  it "rejeita uma inscrição sem resultado ou estado pendente informado" do
    inscricao = sorteio.inscricoes_fastpass.build(usuario: usuario, status: nil)

    expect(inscricao.save).to be(false)
    expect(inscricao.errors.of_kind?(:status, :blank)).to be(true)
  end
end
