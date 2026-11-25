
require "rails_helper"

RSpec.describe "Gestão de restaurantes", type: :request do
  let!(:restaurante) do
    Restaurante.create!(
      nome: "Restaurante Central",
      campus: "Darcy Ribeiro",
      ativo: true
    )
  end

  let!(:outro_restaurante) do
    Restaurante.create!(
      nome: "Restaurante Norte",
      campus: "Asa Norte",
      ativo: true
    )
  end

  let!(:funcionario) do
    Usuario.create!(
      matricula: "123456789",
      nome: "Funcionário Teste",
      email: "funcionario@teste.com",
      password: "senha123",
      papel: "funcionario",
      ativo: true
    )
  end

  def autenticar(usuario)
    post login_path, params: {
      matricula: usuario.matricula,
      password: "senha123"
    }
  end

  def autenticar_como_administrador
    autenticar(funcionario)
    funcionario.update!(papel: "administrador")
  end

  describe "autorização" do
    it "redireciona para o login quando não há usuário autenticado" do
      get restaurantes_path

      expect(response).to redirect_to("/login")
    end

    it "bloqueia usuários que não são administradores" do
      autenticar(funcionario)

      get restaurantes_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Acesso restrito a administradores")
    end
  end

  describe "listagem de restaurantes" do
    before do
      autenticar_como_administrador
    end

    it "exibe a página de gestão de restaurantes" do
      get restaurantes_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Restaurante Central")
      expect(response.body).to include("Restaurante Norte")
    end
  end

  describe "cadastro de restaurantes" do
    before do
      autenticar_como_administrador
    end

    it "cadastra um restaurante com dados válidos" do
      expect {
        post restaurantes_path, params: {
          restaurante: {
            nome: "Restaurante Sul",
            campus: "Gama"
          }
        }
      }.to change(Restaurante, :count).by(1)

      expect(response).to redirect_to(restaurantes_path)
      expect(flash[:notice]).to eq("Restaurante cadastrado com sucesso")
    end

    it "não cadastra um restaurante sem nome" do
      expect {
        post restaurantes_path, params: {
          restaurante: {
            nome: "",
            campus: "Gama"
          }
        }
      }.not_to change(Restaurante, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("não pode ficar em branco")
    end

    it "não cadastra um restaurante com nome duplicado" do
      expect {
        post restaurantes_path, params: {
          restaurante: {
            nome: "restaurante central",
            campus: "Gama"
          }
        }
      }.not_to change(Restaurante, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(
        "Já existe um restaurante com este nome"
      )
    end
  end

  describe "edição de restaurantes" do
    before do
      autenticar_como_administrador
    end

    it "exibe o formulário de edição" do
      get edit_restaurante_path(restaurante)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Restaurante Central")
      expect(response.body).to include("Darcy Ribeiro")
    end
  end

  describe "atualização de restaurantes" do
    before do
      autenticar_como_administrador
    end

    it "atualiza um restaurante com dados válidos" do
      patch restaurante_path(restaurante), params: {
        restaurante: {
          nome: "Restaurante Central Atualizado",
          campus: "Planaltina"
        }
      }

      expect(response).to redirect_to(restaurantes_path)
      expect(flash[:notice]).to eq("Restaurante atualizado com sucesso")

      restaurante.reload
      expect(restaurante.nome).to eq("Restaurante Central Atualizado")
      expect(restaurante.campus).to eq("Planaltina")
    end

    it "não atualiza um restaurante com nome inválido" do
      patch restaurante_path(restaurante), params: {
        restaurante: {
          nome: "",
          campus: "Planaltina"
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("não pode ficar em branco")

      expect(restaurante.reload.nome).to eq("Restaurante Central")
    end

    it "não atualiza um restaurante com nome já cadastrado" do
      patch restaurante_path(restaurante), params: {
        restaurante: {
          nome: "Restaurante Norte",
          campus: "Planaltina"
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(
        "Já existe um restaurante com este nome"
      )

      expect(restaurante.reload.nome).to eq("Restaurante Central")
    end
  end

  describe "remoção de restaurantes" do
    before do
      autenticar_como_administrador
    end

    it "remove um restaurante sem catracas vinculadas" do
      expect {
        delete restaurante_path(restaurante)
      }.to change(Restaurante, :count).by(-1)

      expect(response).to redirect_to(restaurantes_path)
      expect(flash[:notice]).to eq("Restaurante removido com sucesso")
    end

    it "impede a remoção de um restaurante que possui catracas" do
      Catraca.create!(
        restaurante: restaurante,
        codigo_identificador: "CAT-001",
        status: "ativa"
      )

      expect {
        delete restaurante_path(restaurante)
      }.not_to change(Restaurante, :count)

      expect(response).to redirect_to(restaurantes_path)
      expect(flash[:alert]).to include(
        "Remova as catracas deste restaurante antes de excluí-lo"
      )
    end
  end
end
