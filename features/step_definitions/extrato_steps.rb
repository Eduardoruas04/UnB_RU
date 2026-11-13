# frozen_string_literal: true

# ==============================================================================
# Step Definitions da Issue #11 (Extra): Extrato e Exportação em PDF
# ==============================================================================
# Mapeia os 9 cenários descritos em Gherkin no arquivo
# 'features/exportacao_pdf_historico.feature' para comandos executáveis via
# Capybara e RSpec Mocks/Expectations.
#
# Cobre:
# 1. Geração e download de arquivo PDF timbrado (Content-Type: application/pdf)
# 2. Validação de conteúdo institucional e lançamentos contábeis no PDF
# 3. Filtros interativos (Período, Tipo de Refeição e Forma de Acesso)
# 4. Limpeza de filtros
# 5. Casos tristes (sem lançamentos, isolamento de alunos e falha do serviço)
# ==============================================================================

# Helper para decodificar texto dos streams uncompressed do Prawn em testes BDD
def extrair_texto_pdf(pdf_raw)
  hex_chunks = pdf_raw.to_s.scan(/<([0-9a-fA-F]+)>/).flatten
  hex_chunks.map { |h| [ h ].pack("H*").force_encoding("UTF-8").scrub }.join
end

def obter_texto_pdf
  @pdf_texto ||= extrair_texto_pdf(page.body)
end

# Variável de controle para simulação de serviço indisponível
$pdf_service_indisponivel = false

After do
  $pdf_service_indisponivel = false
  @pdf_texto = nil
end

# ==============================================================================
# 1. SETUP DE DADOS DO EXTRATO
# ==============================================================================

# Popula o banco com exatamente a quantidade de lançamentos solicitada no cenário (24)
Dado("eu possuo {int} lançamentos no extrato") do |qtd|
  restaurante = Restaurante.find_or_create_by!(nome: "Restaurante Universitário - Darcy Ribeiro") do |r|
    r.campus = "Darcy Ribeiro"
    r.ativo = true
  end

  catraca = Catraca.find_or_create_by!(codigo_identificador: "CAT-01") do |c|
    c.restaurante = restaurante
    c.status = "ativa"
  end

  turno_almoco = Turno.find_or_create_by!(nome: "Almoço") do |t|
    t.horario_inicio = "11:00"
    t.horario_fim = "14:00"
    t.valor_refeicao_centavos = 450
  end

  turno_jantar = Turno.find_or_create_by!(nome: "Jantar") do |t|
    t.horario_inicio = "17:30"
    t.horario_fim = "20:00"
    t.valor_refeicao_centavos = 450
  end

  # Limpa lançamentos anteriores do estudante de teste para garantir contagem exata
  @usuario.recargas.destroy_all
  @usuario.acessos.destroy_all

  carteira = @usuario.carteira || @usuario.create_carteira(saldo_centavos: 1800)

  # 4 Recargas Pagas (Créditos)
  4.times do |i|
    @usuario.recargas.create!(
      carteira: carteira,
      quantidade_refeicoes: 5,
      valor_centavos: 2250,
      status: "paga",
      metodo_pagamento: i.even? ? "PIX Instantâneo" : "Cartão de Crédito",
      created_at: (i + 1).days.ago
    )
  end

  # 20 Acessos Autorizados (Débitos) distribuídos entre turnos, datas e formas de acesso
  # - 10 Almoço com QR Code App (dentro dos últimos 30 dias)
  # - 6 Jantar com Carteirinha Física (dentro dos últimos 30 dias)
  # - 4 Almoço há mais de 35 dias (para testar o filtro de últimos 30 dias)
  10.times do |i|
    @usuario.acessos.create!(
      catraca: catraca,
      turno: turno_almoco,
      valor_pago_centavos: 450,
      autorizado: true,
      forma_acesso: "QR Code App",
      data_hora: (i + 2).days.ago
    )
  end

  6.times do |i|
    @usuario.acessos.create!(
      catraca: catraca,
      turno: turno_jantar,
      valor_pago_centavos: 450,
      autorizado: true,
      forma_acesso: "Carteirinha Física",
      data_hora: (i + 5).days.ago
    )
  end

  4.times do |i|
    @usuario.acessos.create!(
      catraca: catraca,
      turno: turno_almoco,
      valor_pago_centavos: 450,
      autorizado: true,
      forma_acesso: "Carteirinha Física",
      data_hora: (35 + i).days.ago
    )
  end

  expect(@usuario.recargas.where(status: "paga").count + @usuario.acessos.where(autorizado: true).count).to eq(qtd)
end

# Garante que o estudante não possua nenhuma recarga ou acesso
Dado("que eu não possuo lançamentos no extrato") do
  @usuario.recargas.destroy_all
  @usuario.acessos.destroy_all
end

# ==============================================================================
# 2. NAVEGAÇÃO E AÇÕES
# ==============================================================================

# Navega até a página de extrato do portal
Dado("eu estou na página {string}") do |titulo_pagina|
  visit extrato_path
  expect(page).to have_content(titulo_pagina)
end

# Tenta acessar diretamente a URL de download deslogado
Quando("eu tento acessar a exportação do extrato") do
  visit exportar_pdf_extrato_path
end

# ==============================================================================
# 3. VALIDAÇÃO DE DOWNLOAD E CONTEÚDO DO PDF
# ==============================================================================

# Valida se a resposta HTTP entregou um arquivo binário PDF com cabeçalhos corretos
Então("um arquivo PDF deve ser baixado") do
  expect(page.response_headers["Content-Type"]).to eq("application/pdf")
  expect(page.response_headers["Content-Disposition"]).to include("attachment")
  expect(page.body).to start_with("%PDF-")
  @pdf_texto = extrair_texto_pdf(page.body)
end

# Valida se o cabeçalho da tabela do PDF acusa a quantidade exata de lançamentos
Então("o PDF deve conter os {int} lançamentos") do |qtd|
  expect(obter_texto_pdf).to match(/LANC?AMENTOS\s*REGISTRADOS\s*\(#{qtd}\)/i)
end

# Valida os 3 indicadores do quadro de resumo no PDF
Então("o PDF deve conter o resumo com total gasto, refeições realizadas e total recarregado") do
  expect(obter_texto_pdf).to match(/Total\s*Gasto/i)
  expect(obter_texto_pdf).to match(/Refei[çc][oõ]es\s*Realizadas/i)
  expect(obter_texto_pdf).to match(/Total\s*Recarregado/i)
end

# Valida as 5 colunas obrigatórias de cada lançamento no PDF
Então("cada lançamento do PDF deve conter data e hora, refeição ou evento, restaurante, método de acesso e valor") do
  expect(obter_texto_pdf).to match(/Data\s*e\s*Hora/i)
  expect(obter_texto_pdf).to match(/Refei[çc][aã]o\s*ou\s*Evento/i)
  expect(obter_texto_pdf).to match(/Restaurante/i)
  expect(obter_texto_pdf).to match(/M[eé]todo\s*de\s*Acesso/i)
  expect(obter_texto_pdf).to match(/Valor/i)
end

# ==============================================================================
# 4. FILTROS E EXPORTAÇÃO SELETIVA
# ==============================================================================

# Seleciona uma opção em um dos selects de filtro na interface
Quando("eu seleciono {string} em {string}") do |valor, filtro|
  case filtro
  when /Período/i
    select valor, from: "periodo"
  when /Tipo de Refeição/i
    select valor, from: "tipo_refeicao"
  when /Forma de Acesso/i
    select valor, from: "forma_acesso"
  end
end

# Valida se o PDF contém apenas os registros que satisfazem o filtro aplicado
Então("o PDF deve conter apenas os lançamentos de {string}") do |valor_filtro|
  case valor_filtro
  when "Últimos 30 dias"
    # Lançamentos mais antigos (35+ dias) não devem estar presentes
    expect(obter_texto_pdf).to match(/LANC?AMENTOS\s*REGISTRADOS\s*\(20\)/i)
  when "Almoço"
    expect(obter_texto_pdf).to match(/LANC?AMENTOS\s*REGISTRADOS\s*\(14\)/i)
    expect(obter_texto_pdf).not_to match(/Jantar/i)
  when "QR Code App"
    expect(obter_texto_pdf).to match(/LANC?AMENTOS\s*REGISTRADOS\s*\(10\)/i)
    expect(obter_texto_pdf).not_to match(/Carteirinha/i)
  end
end

# Aplica um filtro previamente na tela de extrato
Dado("que eu apliquei o filtro {string} em {string}") do |valor, filtro|
  visit extrato_path
  case filtro
  when /Tipo de Refeição/i
    select valor, from: "tipo_refeicao"
  end
  click_button "Filtrar"
end

# Simula a aplicação de filtro sem resultados no banco
Dado("que eu apliquei um filtro que não retorna nenhum lançamento") do
  select "Café da Manhã", from: "tipo_refeicao"
  click_button "Filtrar"
end

# Assegura que nenhum download de PDF ocorreu
Então("nenhum arquivo PDF deve ser baixado") do
  expect(page.response_headers["Content-Type"]).not_to eq("application/pdf")
end

# ==============================================================================
# 5. PRIVACIDADE E TRATAMENTO DE ERROS
# ==============================================================================

# Cria lançamentos para outro estudante para testar isolamento de dados
Dado("que o estudante com matrícula {string} também possui lançamentos") do |matricula_outro|
  outro = Usuario.find_or_create_by!(matricula: matricula_outro) do |u|
    u.nome = "Outro Estudante"
    u.email = "outro_#{matricula_outro}@unb.br"
    u.password = "password123"
    u.papel = "estudante"
    u.ativo = true
  end

  carteira_outro = outro.carteira || outro.create_carteira(saldo_centavos: 900)
  outro.recargas.create!(
    carteira: carteira_outro,
    quantidade_refeicoes: 2,
    valor_centavos: 900,
    status: "paga",
    metodo_pagamento: "PIX Instantâneo"
  )
end

# Garante que dados de outros estudantes não aparecem no PDF gerado
Então("o PDF não deve conter lançamentos da matrícula {string}") do |matricula_outro|
  expect(obter_texto_pdf).not_to include(matricula_outro)
  expect(obter_texto_pdf).not_to match(/Outro\s*Estudante/i)
end

# Simula exceção em tempo de execução no gerador de PDF
Dado("que o serviço de geração de PDF está indisponível") do
  $pdf_service_indisponivel = true
end
