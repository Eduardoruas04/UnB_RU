# ---------- Contexto ----------
Given("que eu estou autenticado como administrador") do
  entrar_como(criar_usuario(nome: "Administrador RU", matricula: "000000001", papel: "administrador"))
end

Given("eu estou na página de gestão de restaurantes e catracas") do
  visit restaurantes_path
  @restaurantes_antes = Restaurante.count
end

# ---------- Dados prévios ----------
Given("que já existe o restaurante {string}") do |nome|
  Restaurante.find_or_create_by!(nome: nome)
  recarregar_gestao
end

Given("que já existe o restaurante {string} sem catracas") do |nome|
  Restaurante.find_or_create_by!(nome: nome)
  recarregar_gestao
end

Given("que já existem os restaurantes {string} e {string}") do |nome1, nome2|
  Restaurante.find_or_create_by!(nome: nome1)
  Restaurante.find_or_create_by!(nome: nome2)
  recarregar_gestao
end

Given("que já existe a catraca {string} no restaurante {string}") do |codigo, nome|
  restaurante = Restaurante.find_or_create_by!(nome: nome)
  Catraca.find_or_create_by!(codigo_identificador: codigo) { |c| c.restaurante = restaurante }
  recarregar_gestao
end

Given("já existe a catraca {string}") do |codigo|
  restaurante = Restaurante.first || Restaurante.create!(nome: "Restaurante Padrão")
  Catraca.find_or_create_by!(codigo_identificador: codigo) { |c| c.restaurante = restaurante }
  recarregar_gestao
end

Given("que já existem as catracas {string} e {string} no restaurante {string}") do |cod1, cod2, nome|
  restaurante = Restaurante.find_or_create_by!(nome: nome)
  [ cod1, cod2 ].each do |codigo|
    Catraca.find_or_create_by!(codigo_identificador: codigo) { |c| c.restaurante = restaurante }
  end
  recarregar_gestao
end

Given("que a catraca {string} do restaurante {string} foi removida") do |codigo, nome|
  restaurante = Restaurante.find_or_create_by!(nome: nome)
  Catraca.create!(codigo_identificador: codigo, restaurante: restaurante).destroy
  recarregar_gestao
end

# ---------- Ações: restaurantes ----------
When("eu preencho o nome do restaurante com {string}") do |nome|
  fill_in "Nome do restaurante", with: nome
end


When("eu edito o restaurante {string} e altero o nome para {string}") do |atual, novo|
  editar_restaurante(atual, novo)
end

When("eu edito o restaurante {string} e apago o nome") do |atual|
  editar_restaurante(atual, "")
end

When("eu removo o restaurante {string}") do |nome|
  within(secao_do_restaurante(nome)) { first(:button, "Remover").click }
end

# ---------- Ações: catracas ----------
When("eu preencho o identificador da catraca com {string}") do |codigo|
  fill_in "Identificador da catraca", with: codigo
end

When("eu seleciono o restaurante {string}") do |nome|
  select nome, from: "Restaurante"
end

When("eu edito a catraca {string} e altero o identificador para {string}") do |atual, novo|
  catraca = Catraca.find_by!(codigo_identificador: atual)
  within("#restaurante_#{catraca.restaurante_id} li", text: atual) { click_link "Editar" }
  fill_in "Identificador da catraca", with: novo
  click_button "Atualizar catraca"
end

When("eu removo a catraca {string}") do |codigo|
  catraca = Catraca.find_by!(codigo_identificador: codigo)
  within("#restaurante_#{catraca.restaurante_id} li", text: codigo) { click_button "Remover" }
end

# ---------- Verificações ----------
Then("nenhum restaurante deve ser criado") do
  expect(Restaurante.count).to eq(@restaurantes_antes)
end

Then("{string} deve aparecer/continuar na lista de restaurantes") do |nome|
  visit restaurantes_path
  expect(page).to have_css("section h3", text: nome)
end

Then("{string} não deve aparecer na lista de restaurantes") do |nome|
  visit restaurantes_path
  expect(page).to have_no_css("section h3", text: nome)
end

Then("{string} deve aparecer na lista de catracas de {string}") do |codigo, nome|
  visit restaurantes_path
  expect(page).to have_css("#{secao_do_restaurante(nome)} li", text: codigo)
end

Then("{string} não deve aparecer na lista de catracas de {string}") do |codigo, nome|
  visit restaurantes_path
  expect(page).to have_no_css("#{secao_do_restaurante(nome)} li", text: codigo)
end

# ---------- Uso pelos funcionários ----------
Given("que eu estou autenticado como funcionário sem perfil de administrador") do
  entrar_como(criar_usuario(nome: "Operador de Catraca", matricula: "000000002", papel: "funcionario"))
end

When("eu tento acessar a página de gestão de restaurantes e catracas") do
  visit restaurantes_path
end

When("um funcionário autenticado abre a seleção de catraca na aplicação de controle") do
  entrar_como(criar_usuario(nome: "Operador de Catraca", matricula: "000000002", papel: "funcionario"))
  visit historico_local_path
end

Then("ele deve ver {string} na lista de catracas do restaurante {string}") do |codigo, nome|
  expect(page).to have_select("Catraca", with_options: [ "#{codigo} - #{nome}" ])
end

Then("ele não deve ver {string} na lista de catracas") do |codigo|
  expect(page).to have_no_content(codigo)
end
