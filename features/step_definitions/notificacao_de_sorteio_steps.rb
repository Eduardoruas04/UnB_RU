Dado("que existe um turno de almoço às {string}") do |horario|
  @turno_fastpass = Turno.create!(nome: "Almoço", horario_inicio: horario,
    horario_fim: "14:00", valor_refeicao_centavos: 450)
  @sorteio_fastpass = SorteioFastpass.create!(turno: @turno_fastpass,
    data_sorteio: Date.new(2026, 11, 12), status: "pendente", vagas_disponiveis: 1)
end

Dado("que o horário programado da notificação é {string}") do |horario|
  expect(@sorteio_fastpass.horario_notificacao.strftime("%H:%M")).to eq(horario)
end

Dado("que o sorteio do FastPass foi realizado") do
  @sorteio_fastpass.update!(status: "realizado")
end

Dado("que o sorteio do FastPass ainda não foi realizado") do
  @sorteio_fastpass.update!(status: "pendente")
end

module EstudantesFastpassSteps
  include ActiveSupport::Testing::TimeHelpers
  def estudante_fastpass(matricula)
    Usuario.find_or_create_by!(matricula: matricula) do |usuario|
      usuario.assign_attributes(nome: "Estudante FastPass", email: "#{matricula}@aluno.unb.br",
        password: "senha1234", papel: "estudante", ativo: true)
    end
  end

  def processar_fastpass_no_horario(horario)
    agora = Time.find_zone!("America/Sao_Paulo").parse("2026-11-12 #{horario}")
    travel_to(agora) do
      NotificarFastpassJob.perform_now
    end
  end
end
World(EstudantesFastpassSteps)

Dado("que o estudante {string} está inscrito no sorteio") do |matricula|
  @sorteio_fastpass.inscricoes_fastpass.create!(usuario: estudante_fastpass(matricula), status: "pendente")
end

Dado("que o estudante {string} não está inscrito no sorteio") do |matricula|
  estudante_fastpass(matricula)
end

Dado("que o estudante {string} foi sorteado") do |matricula|
  @sorteio_fastpass.inscricoes_fastpass.find_by!(usuario: estudante_fastpass(matricula)).update!(status: "sorteado")
end

Dado("que o estudante {string} não foi sorteado") do |matricula|
  @sorteio_fastpass.inscricoes_fastpass.find_by!(usuario: estudante_fastpass(matricula)).update!(status: "nao_sorteado")
end

Quando("o horário atual for {string}") do |horario|
  processar_fastpass_no_horario(horario)
end

Dado("que o estudante já recebeu a notificação desse sorteio") do
  processar_fastpass_no_horario("11:00")
  @notificacoes_fastpass_antes = Notificacao.count
end

Quando("o sistema processar novamente as notificações às {string}") do |horario|
  processar_fastpass_no_horario(horario)
end

Então("o sistema deve enviar uma notificação ao estudante {string}") do |matricula|
  usuario = estudante_fastpass(matricula)
  @notificacao_fastpass = usuario.notificacoes.find_by!(sorteio_fastpass: @sorteio_fastpass, tipo: "fastpass")
  expect(@notificacao_fastpass.status_envio).to eq("enviada")
  expect(@notificacao_fastpass.enviado_em).to eq(@sorteio_fastpass.horario_notificacao)
  visit root_path
  click_button "👤 #{usuario.nome} (Saldo: R$ 0.00)"
  click_link "Notificações FastPass (#15)"
  expect(page).to have_content(@notificacao_fastpass.mensagem)
end

Então("a notificação deve informar {string}") do |mensagem|
  expect(page).to have_content(mensagem)
end

Então("a notificação deve informar o horário do FastPass") do
  expect(page).to have_content("Horário do FastPass: 12/11/2026 às 12:00")
end

Então("o sistema não deve enviar a notificação ao estudante {string}") do |matricula|
  expect(estudante_fastpass(matricula).notificacoes.where(sorteio_fastpass: @sorteio_fastpass)).to be_empty
end

Então("nenhuma nova notificação deve ser enviada ao estudante {string}") do |matricula|
  expect(Notificacao.count).to eq(@notificacoes_fastpass_antes)
  expect(estudante_fastpass(matricula).notificacoes.where(sorteio_fastpass: @sorteio_fastpass).count).to eq(1)
end
