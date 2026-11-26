# ==============================================================================
# Testes de Requisição HTTP (RSpec): HomeController (spec/requests/home_spec.rb)
# ==============================================================================
# Valida a rota raiz (root_path /) da aplicação do Portal do RU UnB,
# garantindo que a página inicial responda com status HTTP 200 (OK).
# ==============================================================================

require "rails_helper"

RSpec.describe "Homes", type: :request do
  describe "GET /" do
    let(:estudante) do
      Usuario.create!(nome: "Mariana Silva", matricula: "221045991", email: "mariana@aluno.unb.br",
                      password: "senha123", papel: "estudante", ativo: true)
    end

    before { estudante.create_carteira!(saldo_centavos: 900) }

    it "mostra a conta ativa, o saldo e a opção de encerrar a sessão" do
      post dev_login_path, params: { usuario_id: estudante.id }
      get root_path

      assert_select "p strong", text: estudante.nome
      assert_select "p code", text: estudante.matricula
      assert_select "p strong", text: "R$ 9.00"
      assert_select "form[action=?] input[name=_method][value=delete]", dev_logout_path
    end

    it "oferece login rápido para o estudante quando não há sessão ativa" do
      get root_path

      assert_select "p", text: "Nenhum usuário logado no momento."
      assert_select "form[action=?][method=post] button", dev_login_path(usuario_id: estudante.id),
                    text: "👤 Mariana Silva (Saldo: R$ 9.00)"
    end

    it "returns http success" do
      get root_path
      expect(response).to have_http_status(:success)
    end
  end
end
