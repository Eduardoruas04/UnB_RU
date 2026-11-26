require "rails_helper"

RSpec.describe Usuario, type: :model do
  subject(:usuario) do
    described_class.new(nome: "Maria Silva", matricula: "190012345", email: "maria@aluno.unb.br",
      password: "senha1234", papel: "estudante")
  end

  it "persiste um estudante válido e autentica apenas com a senha correta" do
    usuario.save!
    expect(usuario.reload.authenticate("senha1234")).to eq(usuario)
    expect(usuario.authenticate("outra-senha")).to be(false)
  end

  it "rejeita um e-mail já cadastrado mesmo com matrícula diferente" do
    usuario.save!
    outro = usuario.dup
    outro.matricula = "190012346"

    expect(outro.save).to be(false)
    expect(outro.errors.of_kind?(:email, :taken)).to be(true)
  end
end
