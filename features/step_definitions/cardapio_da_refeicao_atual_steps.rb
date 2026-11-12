# Issue #10 - Cardápio da refeição atual
module CardapioAtualSteps
  # Semana de 09/11/2026 (segunda-feira) a 15/11/2026 (domingo)
  DIAS = %w[segunda-feira terça-feira quarta-feira quinta-feira sexta-feira sábado domingo].freeze
  REFEICOES = {
    "café da manhã" => { nome: "Café da Manhã", inicio: "07:00", fim: "09:00", hora: "08:00", chave: "cafe_da_manha", tipo: "complemento" },
    "almoço" => { nome: "Almoço", inicio: "11:00", fim: "14:00", hora: "12:00", chave: "almoco", tipo: "prato_principal" },
    "jantar" => { nome: "Jantar", inicio: "17:30", fim: "20:00", hora: "18:00", chave: "jantar", tipo: "prato_principal" }
  }.freeze

  def criar_turnos
    REFEICOES.each_value do |r|
      Turno.create!(nome: r[:nome], horario_inicio: r[:inicio], horario_fim: r[:fim], valor_refeicao_centavos: 450)
    end
    @restaurante = Restaurante.create!(nome: "RU Darcy Ribeiro", campus: "Darcy Ribeiro", ativo: true)
  end

  def data_do_dia(dia)
    Date.new(2026, 11, 9) + DIAS.index(dia)
  end

  def json_da_refeicao(dia, refeicao)
    JSON.parse(File.read(Rails.root.join("cardapio.json")))[dia][REFEICOES[refeicao][:chave]]
  end

  def cadastrar_cardapio(dia, refeicao)
    r = REFEICOES[refeicao]
    cardapio = Cardapio.create!(restaurante: @restaurante, turno: Turno.find_by!(nome: r[:nome]), data_refeicao: data_do_dia(dia))
    json = json_da_refeicao(dia, refeicao)
    ItemCardapio::OPCOES.each_key do |opcao|
      categoria = "#{r[:tipo]}_#{opcao}"
      cardapio.itens_cardapio.create!(categoria: categoria, descricao: json[categoria])
    end
    cardapio
  end

  def opcao_deve_apresentar(opcao, descricao, tipo)
    within("[data-opcao='#{opcao}']") do
      expect(page).to have_content(descricao)
      expect(page).to have_content(/#{Regexp.escape(tipo)}/i)
    end
  end
end
World(CardapioAtualSteps)
World(ActiveSupport::Testing::TimeHelpers)

After { travel_back }

Dado("que é {string} e a refeição {string} está em atendimento") do |dia, refeicao|
  criar_turnos
  @dia = dia
  @refeicao = refeicao
  travel_to Time.find_zone("America/Sao_Paulo").parse("#{data_do_dia(dia)} #{CardapioAtualSteps::REFEICOES[refeicao][:hora]}")
end

Dado("o cardápio dessa refeição está cadastrado e acessível") do
  cadastrar_cardapio(@dia, @refeicao)
end

Dado("os cardápios de {string}, {string} e {string} desse dia estão cadastrados e acessíveis") do |*refeicoes|
  refeicoes.each { |refeicao| cadastrar_cardapio(@dia, refeicao) }
end

Dado("o cardápio dessa refeição está não cadastrado") do
  expect(Cardapio.count).to eq(0)
end

Dado("o cardápio dessa refeição está inacessível") do
  cadastrar_cardapio(@dia, @refeicao)
  @restaurante.update!(ativo: false)
end

Dado("que nenhuma refeição está em atendimento") do
  criar_turnos
  travel_to Time.find_zone("America/Sao_Paulo").parse("#{data_do_dia('segunda-feira')} 15:30")
end

Quando("o estudante consulta o cardápio da refeição atual") do
  visit cardapio_atual_path
end

Então("deve ser exibido o cardápio de {string} para {string}") do |dia, refeicao|
  within("#cardapio-atual h2") do
    expect(page).to have_content(dia)
    expect(page).to have_content(/#{Regexp.escape(refeicao)}/i)
  end
end

Então("a opção padrão deve apresentar {string} como {}") do |descricao, tipo|
  opcao_deve_apresentar("padrao", descricao, tipo)
end

Então("a opção ovolactovegetariana deve apresentar {string} como {}") do |descricao, tipo|
  opcao_deve_apresentar("ovolactovegetariano", descricao, tipo)
end

Então("a opção vegetariana estrita deve apresentar {string} como {}") do |descricao, tipo|
  opcao_deve_apresentar("vegetariano_estrito", descricao, tipo)
end

Então("os cardápios de {string} e {string} não devem ser exibidos como cardápio da refeição atual") do |*refeicoes|
  refeicoes.each do |refeicao|
    json = json_da_refeicao(@dia, refeicao)
    tipo = CardapioAtualSteps::REFEICOES[refeicao][:tipo]
    ItemCardapio::OPCOES.each_key { |opcao| expect(page).not_to have_content(json["#{tipo}_#{opcao}"]) }
  end
end

Então("deve ser informada a indisponibilidade do cardápio da refeição atual") do
  expect(page).to have_content("Cardápio da refeição atual indisponível")
end

Então("nenhum cardápio deve ser exibido como cardápio da refeição atual") do
  expect(page).not_to have_css("[data-opcao]")
end

Então("deve ser informado que não há refeição em atendimento") do
  expect(page).to have_content("Não há refeição em atendimento no momento")
end
