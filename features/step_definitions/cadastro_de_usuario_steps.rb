Dado("que eu estou na página de cadastro") do
  visit new_usuario_path
end

Quando("eu preencho o nome com {string}") do |nome|
  fill_in "Nome", with: nome
end

Quando("eu preencho a matrícula com {string}") do |matricula|
  fill_in "Matrícula", with: matricula
end

Quando("eu preencho o e-mail com {string}") do |email|
  fill_in "E-mail", with: email
end

Quando("eu preencho a senha com {string}") do |senha|
  fill_in "Senha", with: senha
end

Quando("eu deixo o campo senha em branco") do
  fill_in "Senha", with: ""
end

Quando("eu deixo o campo nome em branco") do
  fill_in "Nome", with: ""
end

Dado("que já existe um usuário com a matrícula {string}") do |matricula|
  usuario = Usuario.create!(
    nome: "Estudante existente", matricula: matricula,
    email: "existente@aluno.unb.br", password: "senha1234",
    papel: "estudante", ativo: true
  )
  usuario.create_carteira!(saldo_centavos: 0)
end

Quando("eu clico em {string}") do |botao|
  @usuarios_antes_do_cadastro = Usuario.count
  @carteiras_antes_do_cadastro = Carteira.count
  @contas_por_matricula_antes = Usuario.group(:matricula).count
  click_link_or_button botao
end

Então("eu devo ver a mensagem {string}") do |mensagem|
  expect(page).to have_content(mensagem)
end

Então("uma conta deve existir para a matrícula {string}") do |matricula|
  expect(Usuario.where(matricula: matricula).count).to eq(1)
  expect(Usuario.count).to eq(@usuarios_antes_do_cadastro + 1)
end

Então("a conta da matrícula {string} deve possuir uma única carteira com saldo zero") do |matricula|
  usuario = Usuario.find_by!(matricula: matricula)
  expect(usuario.papel).to eq("estudante")
  expect(Carteira.where(usuario: usuario).count).to eq(1)
  expect(usuario.carteira.saldo_centavos).to eq(0)
end

Então("nenhuma conta deve ser criada") do
  expect(Usuario.count).to eq(@usuarios_antes_do_cadastro)
  expect(Carteira.count).to eq(@carteiras_antes_do_cadastro)
end

Então("nenhuma nova conta deve ser criada para a matrícula {string}") do |matricula|
  expect(Usuario.where(matricula: matricula).count).to eq(@contas_por_matricula_antes.fetch(matricula, 0))
  expect(Usuario.count).to eq(@usuarios_antes_do_cadastro)
  expect(Carteira.count).to eq(@carteiras_antes_do_cadastro)
end
