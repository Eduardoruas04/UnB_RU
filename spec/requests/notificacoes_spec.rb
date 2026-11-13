require "rails_helper"

RSpec.describe "Notificações FastPass", type: :request do
  let!(:usuario) { Usuario.create!(nome: "Maria", matricula: "190012345", email: "maria@unb.br", password: "senha1234", papel: "estudante") }

  it "redireciona visitantes sem sessão" do
    get notificacoes_path
    expect(response).to redirect_to(root_path)
  end

  it "nega acesso ao funcionário" do
    usuario.update!(papel: "funcionario")
    post dev_login_path, params: { usuario_id: usuario.id }
    get notificacoes_path
    expect(response).to have_http_status(:forbidden)
  end

  it "mostra somente notificações enviadas do estudante autenticado" do
    outro = Usuario.create!(nome: "Outro", matricula: "190012346", email: "outro@unb.br", password: "senha1234", papel: "estudante")
    turno = Turno.create!(nome: "Almoço", horario_inicio: "12:00", horario_fim: "14:00", valor_refeicao_centavos: 450)
    sorteio = SorteioFastpass.create!(turno: turno, data_sorteio: Date.current, status: "realizado", vagas_disponiveis: 1)
    outro_sorteio = SorteioFastpass.create!(turno: turno, data_sorteio: Date.tomorrow, status: "realizado", vagas_disponiveis: 1)
    dados = { sorteio_fastpass: sorteio, titulo: "FastPass", tipo: "fastpass", status_envio: "enviada", enviado_em: Time.current }
    usuario.notificacoes.create!(dados.merge(mensagem: "Resultado exclusivo da Maria"))
    outro.notificacoes.create!(dados.merge(mensagem: "Resultado privado do outro"))
    usuario.notificacoes.create!(dados.merge(sorteio_fastpass: outro_sorteio, status_envio: "pendente", mensagem: "Ainda não enviado"))
    post dev_login_path, params: { usuario_id: usuario.id }
    get notificacoes_path, params: { usuario_id: outro.id }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Resultado exclusivo da Maria")
    expect(response.body).not_to include("Resultado privado do outro", "Ainda não enviado")
  end

  it "mostra estado vazio" do
    post dev_login_path, params: { usuario_id: usuario.id }
    get notificacoes_path
    expect(response.body).to include("Você ainda não possui notificações")
  end
end
