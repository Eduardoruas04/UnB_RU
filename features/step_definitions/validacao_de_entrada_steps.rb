# Issue #6 - Validação de entrada
module ValidacaoEntradaSteps
  def centavos(valor)
    (valor.to_s.tr(",", ".").to_f * 100).round
  end

  def ler_identificacao(matricula)
    visit catraca_operacao_path
    fill_in "Matrícula", with: matricula
    click_button "Ler identificação"
  end
end
World(ValidacaoEntradaSteps)
World(ActiveSupport::Testing::TimeHelpers)

After { travel_back }

Dado(/^que o preço da refeição é de R\$ ([\d,]+)$/) do |preco|
  @preco = centavos(preco)
  Turno.create!(nome: "Almoço", horario_inicio: "11:00", horario_fim: "14:00", valor_refeicao_centavos: @preco)
  travel_to Time.find_zone("America/Sao_Paulo").parse("2026-11-09 12:00")
end

Dado("existe uma catraca ativa no restaurante") do
  restaurante = Restaurante.create!(nome: "RU Darcy Ribeiro", campus: "Darcy Ribeiro", ativo: true)
  Catraca.create!(restaurante: restaurante, codigo_identificador: "CAT-01", status: "ativa")
end

Dado(/^que o aluno "(\d+)" está cadastrado e tem saldo de R\$ ([\d,]+)$/) do |matricula, saldo|
  @aluno = Usuario.create!(nome: "Aluno #{matricula}", matricula: matricula, email: "#{matricula}@aluno.unb.br",
                           password: "senha123", papel: "estudante", ativo: true)
  @saldo_inicial = centavos(saldo)
  Carteira.create!(usuario: @aluno, saldo_centavos: @saldo_inicial)
end

Dado("a catraca ainda não confirmou a passagem do aluno") do
  expect(Acesso.where(usuario: @aluno).where("valor_pago_centavos > 0")).to be_empty
end

Dado("a leitura de sua identificação já resultou no envio do comando de liberação para a catraca") do
  ler_identificacao(@aluno.matricula)
  expect(page).to have_content("Comando de liberação enviado")
end

Dado("nenhum débito foi efetuado nesta tentativa de entrada") do
  expect(@aluno.carteira.reload.saldo_centavos).to eq(@saldo_inicial)
end

Dado("que não existe aluno cadastrado com a identificação {string}") do |matricula|
  expect(Usuario.find_by(matricula: matricula)).to be_nil
end

Quando("a identificação do aluno {string} é lida na catraca") do |matricula|
  ler_identificacao(matricula)
end

Quando("a identificação {string} é lida na catraca") do |matricula|
  ler_identificacao(matricula)
end

Quando("a catraca confirma a passagem do aluno {string}") do |_matricula|
  click_button "Confirmar passagem"
end

Quando("a tentativa de entrada é encerrada sem confirmação de passagem pela catraca") do
  click_button "Encerrar sem passagem"
end

Então("o comando de liberação deve ser enviado para a catraca") do
  expect(page).to have_content("Comando de liberação enviado")
  expect(Acesso.last.aguardando_passagem?).to be true
end

Então("nenhum débito deve ser efetuado antes da confirmação da passagem") do
  expect(@aluno.carteira.reload.saldo_centavos).to eq(@saldo_inicial)
end

Então("o preço da refeição deve ser debitado do saldo do aluno") do
  expect(page).to have_content("Passagem confirmada")
  expect(@aluno.carteira.reload.saldo_centavos).to eq(@saldo_inicial - @preco)
end

Então(/^o saldo do aluno deve (?:continuar sendo|ser) de R\$ ([\d,]+)$/) do |saldo|
  expect(@aluno.carteira.reload.saldo_centavos).to eq(centavos(saldo))
end

Então("nenhum comando de liberação deve ser enviado") do
  expect(page).not_to have_content("Comando de liberação enviado")
  expect(Acesso.where(autorizado: true)).to be_empty
end

Então("deve ser exibida a mensagem {string}") do |mensagem|
  expect(page).to have_content(mensagem)
end

Então("nenhum débito deve ser efetuado") do
  expect(page).to have_content("Entrada encerrada sem passagem")
  expect(@aluno.carteira.reload.saldo_centavos).to eq(@saldo_inicial)
end
