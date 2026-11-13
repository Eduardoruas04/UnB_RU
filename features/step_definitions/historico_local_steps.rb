# ---------- Contexto ----------
Given("que eu estou autenticado como funcionário") do
  entrar_como(criar_usuario(nome: "Operador de Catraca", matricula: "000000002", papel: "funcionario"))
end

Given("existem as catracas {string} e {string} no restaurante {string}") do |cod1, cod2, nome|
  restaurante = Restaurante.find_or_create_by!(nome: nome)
  [ cod1, cod2 ].each do |codigo|
    Catraca.find_or_create_by!(codigo_identificador: codigo) { |c| c.restaurante = restaurante }
  end
end

# ---------- Dados prévios ----------
Given("que a catraca {string} registrou os acessos dos alunos {string} e {string}") do |codigo, mat1, mat2|
  registrar_acesso(codigo, mat1)
  registrar_acesso(codigo, mat2)
end

Given("que a catraca {string} registrou o acesso do aluno {string}") do |codigo, matricula|
  registrar_acesso(codigo, matricula)
end

Given("a catraca {string} registrou o acesso do aluno {string}") do |codigo, matricula|
  registrar_acesso(codigo, matricula)
end

Given("que a catraca {string} registrou um acesso às {int}:{int} e outro às {int}:{int}") do |codigo, h1, m1, h2, m2|
  registrar_acesso(codigo, "190012345", horario(h1, m1))
  registrar_acesso(codigo, "190012345", horario(h2, m2))
end

Given("que a catraca {string} ainda não registrou nenhum acesso") do |codigo|
  Catraca.find_by!(codigo_identificador: codigo).acessos.destroy_all
end

Given("que a catraca {string} foi removida") do |codigo|
  catraca = Catraca.find_by!(codigo_identificador: codigo)
  @id_catraca_removida = catraca.id
  catraca.destroy
end

Given("eu estou vendo o histórico local da catraca {string}") do |codigo|
  selecionar_catraca(codigo)
end

Given("que eu não estou autenticado") do
  visit root_path
  click_button "Encerrar Sessão (Logout)"
end

# ---------- Ações ----------
When("eu seleciono a catraca {string} na aplicação de controle") do |codigo|
  selecionar_catraca(codigo)
end

When("eu abro o histórico local") do
  visit historico_local_path
end

When("eu atualizo o histórico local") do
  visit historico_local_path
end

When("eu abro o histórico local sem selecionar uma catraca") do
  visit historico_local_path
end

When("o aluno {string} passa pela catraca {string}") do |matricula, codigo|
  registrar_acesso(codigo, matricula)
end

When("eu tento abrir o histórico local da catraca {string}") do |_codigo|
  visit historico_local_path(catraca_id: @id_catraca_removida)
end

# Não segue o redirecionamento, para não depender da rota /login (issue #4)
When("eu tento acessar o histórico local de uma catraca") do
  page.driver.browser.get historico_local_path
end

# ---------- Verificações ----------
Then("eu devo ver os acessos dos alunos {string} e {string}") do |mat1, mat2|
  expect(page).to have_css("tbody td", text: mat1)
  expect(page).to have_css("tbody td", text: mat2)
end

Then("eu devo ver o acesso do aluno {string}") do |matricula|
  expect(page).to have_css("tbody td", text: matricula)
end

Then("eu não devo ver o acesso do aluno {string}") do |matricula|
  expect(page).to have_no_css("tbody td", text: matricula)
end

Then("cada acesso deve mostrar a data e a hora do registro") do
  linhas = all("tbody tr")
  expect(linhas).not_to be_empty
  linhas.each do |linha|
    expect(linha.text).to match(%r{\d{2}/\d{2}/\d{4} \d{2}:\d{2}})
  end
end

Then("o acesso das {int}:{int} deve aparecer antes do acesso das {int}:{int}") do |h1, m1, h2, m2|
  linhas = all("tbody tr").map(&:text)
  primeiro = linhas.index { |l| l.include?(format("%02d:%02d", h1, m1)) }
  segundo = linhas.index { |l| l.include?(format("%02d:%02d", h2, m2)) }
  expect(primeiro).not_to be_nil
  expect(segundo).not_to be_nil
  expect(primeiro).to be < segundo
end

Then("eu devo ver o acesso do aluno {string} no topo da lista") do |matricula|
  expect(first("tbody tr").text).to include(matricula)
end

Then("eu devo ser redirecionado para a página de login") do
  resposta = page.driver.browser.last_response
  expect(resposta.status).to eq(302)
  expect(resposta.headers["Location"]).to end_with("/login")
end
