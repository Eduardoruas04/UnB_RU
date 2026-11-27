
require "rails_helper"

RSpec.describe "Avaliações", type: :request do
  let!(:restaurante) do
    Restaurante.create!(
      nome: "RU Darcy Ribeiro",
      campus: "Darcy Ribeiro",
      ativo: true
    )
  end

  let!(:catraca) do
    Catraca.create!(
      restaurante: restaurante,
      codigo_identificador: "CAT-AV-01",
      status: "ativa"
    )
  end

  let!(:turno) do
    Turno.create!(
      nome: "Almoço",
      horario_inicio: "11:00",
      horario_fim: "14:00",
      valor_refeicao_centavos: 500
    )
  end

  let!(:usuario) do
    Usuario.create!(
      nome: "Aluno Teste",
      matricula: "221045991",
      email: "avaliacao@aluno.unb.br",
      password: "senha123",
      papel: "estudante",
      ativo: true
    )
  end

  let!(:acesso) do
    Acesso.create!(
      usuario: usuario,
      catraca: catraca,
      turno: turno,
      data_hora: Time.current,
      autorizado: true,
      valor_pago_centavos: 500,
      forma_acesso: "Carteira"
    )
  end

  before do
    post "/dev_login", params: { usuario_id: usuario.id }
  end

  describe "GET /avaliacoes/new" do
    it "exibe o formulário de avaliação" do
      get new_avaliacao_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /avaliacoes" do
    context "quando os dados são válidos" do
      it "cria uma avaliação associada ao usuário e ao acesso" do
        expect {
          post avaliacoes_path, params: {
            avaliacao: {
              nota: 5,
              comentario: "Refeição muito boa"
            }
          }
        }.to change(Avaliacao, :count).by(1)

        expect(Avaliacao.last.usuario).to eq(usuario)
        expect(Avaliacao.last.acesso).to eq(acesso)
        expect(response).to redirect_to(new_avaliacao_path)
      end
    end

    context "quando não existe acesso autorizado hoje" do
      it "impede a criação da avaliação" do
        acesso.update!(autorizado: false)

        expect {
          post avaliacoes_path, params: {
            avaliacao: { nota: 5 }
          }
        }.not_to change(Avaliacao, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(
          "Você precisa ter consumido uma refeição hoje para avaliar"
        )
      end
    end

    context "quando a nota não é informada" do
      it "impede a criação da avaliação" do
        expect {
          post avaliacoes_path, params: {
            avaliacao: { comentario: "Sem nota" }
          }
        }.not_to change(Avaliacao, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(
          "Selecione uma nota para a refeição"
        )
      end
    end

    context "quando a nota está fora do intervalo permitido" do
      it "impede a criação da avaliação" do
        expect {
          post avaliacoes_path, params: {
            avaliacao: { nota: 9 }
          }
        }.not_to change(Avaliacao, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "quando o acesso já foi avaliado" do
      it "impede uma segunda avaliação para o mesmo acesso" do
        Avaliacao.create!(
          usuario: usuario,
          acesso: acesso,
          nota: 4
        )

        expect {
          post avaliacoes_path, params: {
            avaliacao: { nota: 5 }
          }
        }.not_to change(Avaliacao, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "autenticação" do
    it "redireciona para o login quando o usuário não está autenticado" do
      delete "/dev_logout"

      get new_avaliacao_path

      expect(response).to redirect_to(login_path)
    end
  end
end
