
require "rails_helper"

RSpec.describe "Sessões", type: :request do
  let!(:funcionario) do
    Usuario.create!(
      nome: "Funcionário Teste",
      matricula: "123456789",
      email: "funcionario@ru.unb.br",
      password: "senha123",
      papel: "funcionario",
      ativo: true
    )
  end

  describe "GET /login" do
    it "exibe a página de login" do
      get login_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Login da Aplicação de Controle")
      expect(response.body).to include("Matrícula")
      expect(response.body).to include("Senha")
    end
  end

  describe "POST /login" do
    context "quando as credenciais são válidas" do
      it "autentica o funcionário e redireciona para o painel" do
        post login_path, params: {
          matricula: funcionario.matricula,
          password: "senha123"
        }

        expect(response).to redirect_to(painel_controle_path)
        expect(session[:usuario_id]).to eq(funcionario.id)
        expect(flash[:notice]).to eq("Login realizado com sucesso")
      end
    end

    context "quando matrícula ou senha estão vazias" do
      it "impede o login e exibe uma mensagem" do
        post login_path, params: {
          matricula: "",
          password: ""
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(
          "Matrícula e senha são obrigatórias"
        )
        expect(session[:usuario_id]).to be_nil
      end
    end

    context "quando o funcionário não existe" do
      it "impede o login" do
        post login_path, params: {
          matricula: "999999999",
          password: "senha123"
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Matrícula ou senha inválidos")
        expect(session[:usuario_id]).to be_nil
      end
    end

    context "quando a senha está incorreta" do
      it "impede o login" do
        post login_path, params: {
          matricula: funcionario.matricula,
          password: "senha_errada"
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Matrícula ou senha inválidos")
        expect(session[:usuario_id]).to be_nil
      end
    end

    context "quando o usuário não é funcionário" do
      it "impede o login" do
        funcionario.update!(papel: "estudante")

        post login_path, params: {
          matricula: funcionario.matricula,
          password: "senha123"
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Matrícula ou senha inválidos")
        expect(session[:usuario_id]).to be_nil
      end
    end

    context "quando a conta está inativa" do
      it "impede o login e informa que a conta está inativa" do
        funcionario.update!(ativo: false)

        post login_path, params: {
          matricula: funcionario.matricula,
          password: "senha123"
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Conta de funcionário inativa")
        expect(session[:usuario_id]).to be_nil
      end
    end
  end

  describe "DELETE /logout" do
    it "encerra a sessão e redireciona para o login" do
      post login_path, params: {
        matricula: funcionario.matricula,
        password: "senha123"
      }

      delete logout_path

      expect(response).to redirect_to(login_path)
      expect(session[:usuario_id]).to be_nil
      expect(flash[:notice]).to eq("Sessão encerrada com sucesso")
    end
  end
end
