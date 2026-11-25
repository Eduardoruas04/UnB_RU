
require "rails_helper"

RSpec.describe "Painel de Controle", type: :request do
  let!(:funcionario) do
    Usuario.create!(
      nome: "Funcionário Teste",
      matricula: "123456789",
      email: "painel@ru.unb.br",
      password: "senha123",
      papel: "funcionario",
      ativo: true
    )
  end

  describe "GET /painel_controle" do
    context "quando o funcionário está autenticado e ativo" do
      before do
        post login_path, params: {
          matricula: funcionario.matricula,
          password: "senha123"
        }
      end

      it "permite o acesso ao painel" do
        get painel_controle_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Painel da Aplicação de Controle")
        expect(response.body).to include("Funcionário Teste")
        expect(response.body).to include("123456789")
      end

      it "exibe o botão de sair" do
        get painel_controle_path

        expect(response.body).to include("Sair")
      end
    end

    context "quando não existe usuário autenticado" do
      it "redireciona para o login e limpa a sessão" do
        get painel_controle_path

        expect(response).to redirect_to(login_path)
        expect(session[:usuario_id]).to be_nil
        expect(flash[:alert]).to eq(
          "Acesso restrito. Faça login para continuar."
        )
      end
    end

    context "quando o usuário não é funcionário" do
      before do
        funcionario.update!(papel: "estudante")

        post login_path, params: {
          matricula: funcionario.matricula,
          password: "senha123"
        }
      end

      it "impede o acesso e limpa a sessão" do
        get painel_controle_path

        expect(response).to redirect_to(login_path)
        expect(session[:usuario_id]).to be_nil
        expect(flash[:alert]).to eq(
          "Acesso restrito. Faça login para continuar."
        )
      end
    end

    context "quando a conta do funcionário está inativa" do
      before do
        post login_path, params: {
          matricula: funcionario.matricula,
          password: "senha123"
        }

        funcionario.update!(ativo: false)
      end

      it "impede o acesso e limpa a sessão" do
        get painel_controle_path

        expect(response).to redirect_to(login_path)
        expect(session[:usuario_id]).to be_nil
        expect(flash[:alert]).to eq(
          "Acesso restrito. Faça login para continuar."
        )
      end
    end
  end
end
