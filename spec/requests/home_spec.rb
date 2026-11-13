# ==============================================================================
# Testes de Requisição HTTP (RSpec): HomeController (spec/requests/home_spec.rb)
# ==============================================================================
# Valida a rota raiz (root_path /) da aplicação do Portal do RU UnB,
# garantindo que a página inicial responda com status HTTP 200 (OK).
# ==============================================================================

require "rails_helper"

RSpec.describe "Homes", type: :request do
  describe "GET /" do
    it "returns http success" do
      get root_path
      expect(response).to have_http_status(:success)
    end
  end
end
