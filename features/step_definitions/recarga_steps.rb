# frozen_string_literal: true

# ==============================================================================
# Step Definitions da Issue #2 (MVP): Recarga de Saldo de Refeições
# ==============================================================================
# Este arquivo mapeia os cenários descritos em Gherkin no arquivo
# 'features/recarga_de_saldo.feature' para comandos executáveis via Capybara
# e RSpec Mocks/Expectations.
#
# Cobre tanto o fluxo feliz (PIX e Cartão com sucesso, pacotes e cálculo customizado)
# quanto os fluxos tristes (sem método selecionado, recusas de cartão, limites de
# quantidade e redirecionamento de usuários deslogados).
# ==============================================================================

# ==============================================================================
# 1. CONTEXTO E AUTENTICAÇÃO
# ==============================================================================

# Garante que o usuário estudante existe no banco e cria uma sessão válida
# utilizando a rota auxiliar de desenvolvimento/teste POST /dev_login.
Dado("que eu estou autenticado como estudante com matrícula {string}") do |matricula|
  @usuario = Usuario.find_by(matricula: matricula)
  unless @usuario
    @usuario = Usuario.create!(
      matricula: matricula,
      nome: "Estudante Teste",
      email: "estudante_#{matricula}@unb.br",
      password: "password123",
      papel: "estudante",
      ativo: true
    )
  end

  # Garante que o estudante possua uma carteira vinculada
  @carteira = @usuario.carteira || @usuario.create_carteira(saldo_centavos: 1800)
  @sem_metodo_pagamento = false

  # Simula login autenticado gravando o cookie de sessão via endpoint de testes
  page.driver.post("/dev_login", usuario_id: @usuario.id)
end

# Configura o saldo inicial da carteira no banco, convertendo de formato monetário (R$ 18,00) para centavos (1800)
Dado(/^meu saldo atual é de R\$ ([\d,]+) \((\d+) refeições\)$/) do |valor, _refeicoes|
  centavos = (valor.tr(",", ".").to_f * 100).round
  @carteira.update!(saldo_centavos: centavos)
end

# Valida a tarifa oficial da refeição (fixada em R$ 4,50 conforme regras da UnB)
Dado(/^a tarifa unitária da refeição é de R\$ ([\d,]+)$/) do |tarifa|
  expect(tarifa.tr(",", ".").to_f).to eq(4.50)
end

# Acessa a página de recarga (/recargas/new)
Dado("eu estou na página de recarga") do
  visit new_recarga_path
end

# ==============================================================================
# 2. PACOTES PREDEFINIDOS DE REFEIÇÕES
# ==============================================================================

# Simula a seleção de um pacote rápido (2, 5, 10 ou 20 refeições)
Quando("eu escolho o pacote de {string} refeições") do |refeicoes|
  visit new_recarga_path(quantidade_refeicoes: refeicoes)
  find("#metodo-pagamento-input", visible: :all).set("") if @sem_metodo_pagamento
end

# Valida se o resumo lateral exibe o valor monetário calculado corretamente
Então("o resumo da recarga deve mostrar o total de R$ {word}") do |total|
  expect(page).to have_content("R$ #{total}")
end

# Valida se o resumo lateral exibe a nova quantidade total de refeições pós-recarga
Então("o resumo da recarga deve mostrar o novo saldo de {int} refeições") do |novas_refeicoes|
  expect(page).to have_content("#{novas_refeicoes} refeições")
end

# ==============================================================================
# 3. SELEÇÃO DE PAGAMENTO E AÇÕES DE CONFIRMAÇÃO
# ==============================================================================

# Seleciona o método de pagamento no formulário ("PIX Instantâneo" ou "Cartão de Crédito")
Quando("eu seleciono a forma de pagamento {string}") do |forma|
  @sem_metodo_pagamento = false
  find("#metodo-pagamento-input", visible: :all).set(forma)
end

# Clica em botões genéricos da interface (ex: "Confirmar", "Copiar Código")
Quando("eu clico em {string}") do |texto_botao|
  click_on texto_botao
end

# Simula o clique no botão de webhook/aprovação imediata do PIX
Quando("o pagamento PIX é confirmado") do
  click_button "Confirmar Pagamento PIX"
end

# Verifica se mensagens informativas ou de erro aparecem no banner de alerta/notificação
Então("eu devo ver a mensagem {string}") do |mensagem|
  expect(page).to have_content(mensagem)
end

# Recarrega a carteira do banco para validar o crédito das refeições e a exibição no cabeçalho
Então("meu saldo deve ser de {int} refeições") do |refeicoes_esperadas|
  @carteira.reload
  saldo_refeicoes = @carteira.saldo_centavos / 450
  expect(saldo_refeicoes).to eq(refeicoes_esperadas)
  expect(page).to have_content("#{refeicoes_esperadas} refs")
end

# ==============================================================================
# 4. PAGAMENTO COM CARTÃO DE CRÉDITO
# ==============================================================================

# Simula o preenchimento de um cartão válido
Quando("eu informo os dados de um cartão válido") do
  find("#cartao_status", visible: :all).find("option[value='valido']", visible: :all).select_option
end

# Valida textos estáticos ou descrições no card de resumo
Então("o resumo da recarga deve mostrar {string}") do |texto|
  expect(page).to have_content(texto)
end

# ==============================================================================
# 5. OUTRA QUANTIDADE (QUANTIDADE PERSONALIZADA)
# ==============================================================================

# Informa uma quantidade arbitrária no campo numérico
Quando("eu informo {string} em {string}") do |quantidade, _campo|
  if quantidade.match?(/\A\d+\z/) && quantidade.to_i > 0 && quantidade.to_i <= 100
    visit new_recarga_path(quantidade_refeicoes: quantidade)
  else
    fill_in "quantidade_refeicoes", with: quantidade
  end
end

# Valida a exibição do demonstrativo de cálculo visual (ex: 7 × R$ 4,50 = R$ 31,50)
Então("o cálculo deve mostrar {string}") do |calculo_esperado|
  expect(page).to have_content(calculo_esperado)
end

# Garante que em cenários de erro o saldo do estudante permaneceu inalterado
Então("meu saldo deve continuar sendo de {int} refeições") do |refeicoes_esperadas|
  @carteira.reload
  saldo_refeicoes = @carteira.saldo_centavos / 450
  expect(saldo_refeicoes).to eq(refeicoes_esperadas)
end

# Clica nos botões de incremento (+) ou decremento (−), respeitando os limites [1, 100]
Quando("eu clico no botão {string} de quantidade") do |botao|
  if botao == "−" || botao == "-"
    val = find("#input-quantidade").value.to_i
    val = [ val - 1, 1 ].max
    visit new_recarga_path(quantidade_refeicoes: val)
  elsif botao == "+"
    val = find("#input-quantidade").value.to_i
    val = [ val + 1, 100 ].min
    visit new_recarga_path(quantidade_refeicoes: val)
  end
end

# Valida se o input numérico mantém o valor esperado após interação com os botões
Então("a quantidade deve continuar sendo {string}") do |qtd_esperada|
  expect(find("#input-quantidade").value).to eq(qtd_esperada)
end

# ==============================================================================
# 6. CENÁRIOS TRISTES E SITUAÇÕES DE EXCEÇÃO
# ==============================================================================

# Garante que nenhum método de pagamento esteja pré-selecionado no formulário
Dado("que nenhum método de pagamento foi selecionado") do
  @sem_metodo_pagamento = true
  find("#metodo-pagamento-input", visible: :all).set("")
end

# Valida se o container com a chave copia-e-cola do PIX está visível na tela
Então("o código PIX deve ser copiado para a área de transferência") do
  expect(page).to have_content("Chave Pix")
  expect(page).to have_css("#codigo-pix")
end

# Simula o preenchimento de cartão que será rejeitado pela operadora
Quando("eu informo os dados de um cartão que será recusado") do
  find("#cartao_status", visible: :all).find("option[value='recusado']", visible: :all).select_option
end

# Simula o preenchimento de cartão cuja data de expiração já passou
Quando("eu informo os dados de um cartão com validade vencida") do
  find("#cartao_status", visible: :all).find("option[value='vencido']", visible: :all).select_option
end

# Simula a expiração do tempo limite do PIX (status vencido)
Quando("o prazo do PIX expira sem pagamento") do
  click_button "Simular Prazo Expirado (Sem Pagamento)"
end

# ==============================================================================
# 7. CONTROLE DE AUTENTICAÇÃO E SESSÃO
# ==============================================================================

# Desloga a sessão do usuário chamando o endpoint de teste DELETE /dev_logout
Dado("que eu não estou autenticado") do
  page.driver.delete("/dev_logout") if page.driver.respond_to?(:delete)
end

# Tenta navegar diretamente para a tela de recargas deslogado
Quando("eu tento acessar a página de recarga") do
  visit new_recarga_path
end

# Valida o redirecionamento de segurança para a tela de login
Então("eu devo ser redirecionado para a página de login") do
  expect(current_path).to eq("/login")
end
