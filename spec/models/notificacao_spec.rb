require "rails_helper"

RSpec.describe Notificacao, type: :model do
  let(:usuario) { FactoryBot.create(:usuario, matricula: "190012345", password: "senha1234", papel: "estudante") }
  let(:sorteio) { FactoryBot.create(:sorteio_fastpass, turno: FactoryBot.create(:turno)) }
  subject(:notificacao) do
    FactoryBot.build(:notificacao, usuario: usuario, sorteio_fastpass: sorteio, tipo: "fastpass", status_envio: "enviada")
  end

  it "persiste a notificação associada ao usuário e ao sorteio" do
    notificacao.save!

    expect(usuario.notificacoes.reload.sole).to eq(notificacao)
    expect(notificacao.reload.sorteio_fastpass).to eq(sorteio)
  end

  it "rejeita uma notificação sem mensagem" do
    notificacao.mensagem = nil

    expect(notificacao.save).to be(false)
    expect(notificacao.errors.of_kind?(:mensagem, :blank)).to be(true)
  end
end
