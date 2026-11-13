Dado(/^que estou autenticado no sistema$/) do
  @estudante_avaliador = Usuario.find_or_initialize_by(matricula: "221045999")
  @estudante_avaliador.update!(
    nome: "Estudante Avaliador",
    email: "avaliador@aluno.unb.br",
    password: "senha123",
    papel: "estudante",
    ativo: true
  )

  @avaliacoes_antes = Avaliacao.where(usuario: @estudante_avaliador).count
  page.driver.post(dev_login_path, usuario_id: @estudante_avaliador.id)
  visit new_avaliacao_path
end

Dado(/^que consumi uma refeição no RU na data de hoje$/) do
  restaurante = Restaurante.find_or_create_by!(nome: "RU Darcy Ribeiro") do |r|
    r.campus = "Darcy Ribeiro"
    r.ativo = true
  end

  catraca = Catraca.find_or_create_by!(codigo_identificador: "CAT-01") do |c|
    c.restaurante = restaurante
    c.status = "ativa"
  end

  turno = Turno.find_or_create_by!(nome: "Almoço") do |t|
    t.horario_inicio = "11:00"
    t.horario_fim = "14:00"
    t.valor_refeicao_centavos = 450
  end

  Acesso.create!(
    usuario: @estudante_avaliador,
    catraca: catraca,
    turno: turno,
    valor_pago_centavos: 450,
    autorizado: true,
    data_hora: Time.current
  )

  visit new_avaliacao_path
end

Dado(/^que não consumi nenhuma refeição no RU na data de hoje$/) do
  @estudante_avaliador.acessos.destroy_all
  visit new_avaliacao_path
end

Quando(/^eu seleciono a nota "([^"]*)"$/) do |nota|
  select nota, from: "Nota"
end

Quando(/^eu preencho o comentário com "([^"]*)"$/) do |comentario|
  fill_in "Comentário", with: comentario
end

Quando(/^eu deixo o campo comentário em branco$/) do
  fill_in "Comentário", with: ""
end

Quando(/^eu deixo o campo nota em branco$/) do
  select "Selecione uma nota", from: "Nota"
end

Quando(/^eu tento enviar uma avaliação$/) do
  select "5", from: "Nota"
  fill_in "Comentário", with: "Tentando avaliar sem consumo"
  click_button "Enviar Avaliação"
end

Então(/^o sistema deve registrar a minha avaliação$/) do
  expect(Avaliacao.where(usuario: @estudante_avaliador).count).to eq(@avaliacoes_antes + 1)
end

Então(/^o sistema deve impedir o envio$/) do
  expect(Avaliacao.where(usuario: @estudante_avaliador).count).to eq(@avaliacoes_antes)
end
