Dado(/^que existe um funcionário ativo com matrícula "([^"]*)" e senha "([^"]*)"$/) do |matricula, senha|
  matricula_valida = matricula.gsub(/\D/, "").rjust(9, "1")
  @mapa_matriculas ||= {}
  @mapa_matriculas[matricula] = matricula_valida

  usuario = Usuario.find_or_initialize_by(matricula: matricula_valida)
  usuario.update!(
    nome: "Funcionário #{matricula}",
    email: "#{matricula.downcase}@unb.br",
    password: senha,
    papel: "funcionario",
    ativo: true
  )
end

Dado(/^existe um funcionário inativo com matrícula "([^"]*)" e senha "([^"]*)"$/) do |matricula, senha|
  matricula_valida = matricula.gsub(/\D/, "").rjust(9, "2")
  @mapa_matriculas ||= {}
  @mapa_matriculas[matricula] = matricula_valida

  usuario = Usuario.find_or_initialize_by(matricula: matricula_valida)
  usuario.update!(
    nome: "Funcionário Inativo #{matricula}",
    email: "#{matricula.downcase}@unb.br",
    password: senha,
    papel: "funcionario",
    ativo: false
  )
end

Dado(/^eu estou na página de login da aplicação de controle$/) do
  visit login_path
end

Dado(/^que eu estou autenticado no painel com a matrícula "([^"]*)"$/) do |matricula|
  matricula_real = (@mapa_matriculas && @mapa_matriculas[matricula]) || matricula
  visit login_path
  fill_in "Matrícula", with: matricula_real
  fill_in "Senha", with: "senhaSegura1"
  click_button "Entrar"
end

Dado(/^que eu não estou autenticado$/) do
  Capybara.reset_sessions!
end

Quando(/^eu clico no botão "([^"]*)"$/) do |botao|
  click_button botao
end

Quando(/^eu tento acessar o painel da aplicação de controle$/) do
  visit painel_controle_path
end

Então(/^eu devo ser redirecionado para o painel da aplicação de controle$/) do
  expect(page).to have_current_path(painel_controle_path)
end

Então(/^a minha sessão deve ser encerrada$/) do
  expect(page).not_to have_button("Sair")
end

Então(/^eu devo ser redirecionado para a página de login com a mensagem "([^"]*)"$/) do |mensagem|
  expect(page).to have_current_path(login_path)
  expect(page).to have_content(mensagem)
end

Então(/^eu devo continuar na página de login$/) do
  expect(page).to have_current_path(login_path)
end

Então(/^eu devo ser redirecionado para a página de login$/) do
  expect(page).to have_current_path(login_path)
end
