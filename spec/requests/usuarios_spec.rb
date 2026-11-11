require "rails_helper"

RSpec.describe "Cadastro de usuário", type: :request do
  let(:dados) do
    { nome: "Maria Silva", matricula: "190012345", email: "maria@aluno.unb.br", password: "senha1234" }
  end

  it "apresenta o formulário" do
    get new_usuario_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Cadastrar")
  end

  it "cria estudante e carteira zerada sem aceitar perfil ou saldo enviados" do
    expect {
      post usuarios_path, params: { usuario: dados.merge(papel: "administrador", saldo_centavos: 9999) }
    }.to change(Usuario, :count).by(1).and change(Carteira, :count).by(1)

    usuario = Usuario.find_by!(matricula: dados[:matricula])
    expect(usuario.papel).to eq("estudante")
    expect(usuario).to be_ativo
    expect(usuario.authenticate("senha1234")).to eq(usuario)
    expect(usuario.carteira.saldo_centavos).to eq(0)
    expect(response).to redirect_to(root_path)
    expect(flash[:notice]).to eq("Cadastro realizado com sucesso")
  end

  {
    matricula: [
      ["", "Matrícula não pode ficar em branco"],
      ["12345", "Matrícula deve ter 9 dígitos"],
      ["1900123456", "Matrícula deve ter 9 dígitos"],
      ["abc123def", "Matrícula deve conter apenas números"]
    ],
    password: [["123", "Senha deve ter no mínimo 8 caracteres"], ["", "Senha é obrigatória"]],
    nome: [["", "Nome é obrigatório"]]
  }.each do |campo, casos|
    casos.each do |valor, mensagem|
      it "recusa #{campo}=#{valor.inspect} sem criar usuário ou carteira" do
        expect {
          post usuarios_path, params: { usuario: dados.merge(campo => valor) }
        }.to change(Usuario, :count).by(0).and change(Carteira, :count).by(0)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(mensagem)
      end
    end
  end

  it "recusa matrícula duplicada" do
    Usuario.create!(dados.merge(papel: "estudante"))
    expect {
      post usuarios_path, params: { usuario: dados.merge(email: "outra@aluno.unb.br") }
    }.to change(Usuario, :count).by(0).and change(Carteira, :count).by(0)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Matrícula já cadastrada")
  end

  it "desfaz a criação do usuário se a carteira falhar" do
    allow_any_instance_of(Usuario).to receive(:create_carteira!).and_raise(
      ActiveRecord::RecordInvalid.new(Carteira.new)
    )
    expect {
      post usuarios_path, params: { usuario: dados }
    }.to change(Usuario, :count).by(0).and change(Carteira, :count).by(0)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Não foi possível criar a carteira")
  end
end
