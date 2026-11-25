
require "rails_helper"

RSpec.describe "Histórico local", type: :request do
  let!(:restaurante) do
    Restaurante.create!(
      nome: "Restaurante Central",
      campus: "Darcy Ribeiro",
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

  let!(:turno) do
    Turno.create!(
      nome: "Almoço",
      horario_inicio: "11:00",
      horario_fim: "14:00",
      valor_refeicao_centavos: 1500
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

  describe "autenticação" do
    it "redireciona para o login quando não há usuário autenticado" do
      get historico_local_path

      expect(response).to redirect_to("/login")
    end

    it "bloqueia usuários que não são funcionários nem administradores" do
      estudante = Usuario.create!(
        matricula: "987654321",
        nome: "Estudante Teste",
        email: "estudante@teste.com",
        password: "senha123",
        papel: "funcionario",
        ativo: true
      )

      autenticar(estudante)
      estudante.update!(papel: "estudante")

      get historico_local_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Acesso restrito a funcionários")
    end

    it "permite acesso a administradores" do
      administrador = Usuario.create!(
        matricula: "111222333",
        nome: "Administrador",
        email: "admin@teste.com",
        password: "senha123",
        papel: "funcionario",
        ativo: true
      )

      autenticar(administrador)
      administrador.update!(papel: "administrador")

      get historico_local_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "seleção de catraca" do
    before do
      autenticar(funcionario)
    end

    it "exibe mensagem quando nenhuma catraca foi selecionada" do
      get historico_local_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        "Selecione uma catraca para ver o histórico"
      )
      expect(response.body).to include("CAT-001")
    end

    it "armazena a catraca selecionada na sessão" do
      get historico_local_path, params: { catraca_id: catraca.id }

      expect(session[:catraca_id]).to eq(catraca.id.to_s)
      expect(response.body).to include("Catraca CAT-001")
    end

    it "mantém a catraca selecionada em uma requisição posterior" do
      get historico_local_path, params: { catraca_id: catraca.id }
      get historico_local_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Catraca CAT-001")
    end

    it "limpa a sessão quando a catraca selecionada não existe" do
      get historico_local_path, params: { catraca_id: "999999" }

      expect(session[:catraca_id]).to be_nil
      expect(response.body).to include("Catraca não encontrada")
    end
  end

  describe "exibição do histórico" do
    before do
      autenticar(funcionario)
    end

    it "exibe mensagem quando a catraca não possui acessos" do
      get historico_local_path, params: { catraca_id: catraca.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        "Nenhum acesso registrado nesta catraca"
      )
    end

    it "exibe acessos autorizados e recusados" do
      Acesso.create!(
        usuario: funcionario,
        catraca: catraca,
        turno: turno,
        data_hora: 1.hour.ago,
        autorizado: true,
        valor_pago_centavos: 1500,
        forma_acesso: "QR Code App"
      )

      Acesso.create!(
        usuario: funcionario,
        catraca: catraca,
        turno: turno,
        data_hora: 2.hours.ago,
        autorizado: false,
        valor_pago_centavos: 0,
        motivo_recusa: "Saldo insuficiente",
        forma_acesso: "QR Code App"
      )

      get historico_local_path, params: { catraca_id: catraca.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Autorizado")
      expect(response.body).to include("Recusado")
      expect(response.body).to include("Saldo insuficiente")
      expect(response.body).to include(funcionario.matricula)

      expect(response.body.index("Autorizado")).to be <
        response.body.index("Recusado")
    end

    it "exibe o motivo apenas quando ele está presente" do
      Acesso.create!(
        usuario: funcionario,
        catraca: catraca,
        turno: turno,
        data_hora: Time.current,
        autorizado: false,
        valor_pago_centavos: 0,
        motivo_recusa: nil,
        forma_acesso: "QR Code App"
      )

      get historico_local_path, params: { catraca_id: catraca.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Recusado")
    end
  end
end
