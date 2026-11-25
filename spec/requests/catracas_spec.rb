
require "rails_helper"

RSpec.describe "Gestão de catracas", type: :request do
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

  let!(:catraca) do
    Catraca.create!(
      restaurante: restaurante,
      codigo_identificador: "CAT-001",
      status: "ativa"
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
      get edit_catraca_path(catraca)

      expect(response).to redirect_to("/login")
    end

    it "bloqueia usuários que não são administradores" do
      autenticar(funcionario)

      get edit_catraca_path(catraca)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Acesso restrito a administradores")
    end
  end

  describe "cadastro de catracas" do
    before do
      autenticar_como_administrador
    end

    it "cadastra uma catraca com dados válidos" do
      expect {
        post catracas_path, params: {
          catraca: {
            codigo_identificador: "CAT-002",
            restaurante_id: restaurante.id,
            status: "ativa"
          }
        }
      }.to change(Catraca, :count).by(1)

      expect(response).to redirect_to(restaurantes_path)
      expect(flash[:notice]).to eq("Catraca cadastrada com sucesso")
    end

    it "não cadastra uma catraca com identificador duplicado" do
      expect {
        post catracas_path, params: {
          catraca: {
            codigo_identificador: "CAT-001",
            restaurante_id: restaurante.id,
            status: "ativa"
          }
        }
      }.not_to change(Catraca, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Gestão de restaurantes e catracas")
      expect(response.body).to include(
        "Já existe uma catraca com este identificador"
      )
    end
  end

  describe "edição de catracas" do
    before do
      autenticar_como_administrador
    end

    it "exibe o formulário de edição" do
      get edit_catraca_path(catraca)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Editar catraca")
      expect(response.body).to include("CAT-001")
      expect(response.body).to include("Restaurante Central")
    end
  end

  describe "atualização de catracas" do
    before do
      autenticar_como_administrador
    end

    it "atualiza uma catraca com dados válidos" do
      patch catraca_path(catraca), params: {
        catraca: {
          codigo_identificador: "CAT-010",
          restaurante_id: outro_restaurante.id,
          status: "manutencao"
        }
      }

      expect(response).to redirect_to(restaurantes_path)
      expect(flash[:notice]).to eq("Catraca atualizada com sucesso")

      catraca.reload
      expect(catraca.codigo_identificador).to eq("CAT-010")
      expect(catraca.restaurante).to eq(outro_restaurante)
      expect(catraca.status).to eq("manutencao")
    end

    it "não atualiza uma catraca com identificador duplicado" do
      Catraca.create!(
        restaurante: outro_restaurante,
        codigo_identificador: "CAT-002",
        status: "ativa"
      )

      patch catraca_path(catraca), params: {
        catraca: {
          codigo_identificador: "CAT-002",
          restaurante_id: restaurante.id,
          status: "ativa"
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(
        "Já existe uma catraca com este identificador"
      )

      expect(catraca.reload.codigo_identificador).to eq("CAT-001")
    end
  end

  describe "remoção de catracas" do
    before do
      autenticar_como_administrador
    end

    it "remove uma catraca cadastrada" do
      expect {
        delete catraca_path(catraca)
      }.to change(Catraca, :count).by(-1)

      expect(response).to redirect_to(restaurantes_path)
      expect(flash[:notice]).to eq("Catraca removida com sucesso")
    end
  end
end
