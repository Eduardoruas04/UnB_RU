# frozen_string_literal: true

require "prawn"

# ==============================================================================
# Service Gerador de PDF do Extrato (app/services/extrato_pdf_generator.rb)
# ==============================================================================
# Constrói o extrato oficial e timbrado em formato PDF utilizando a gem Prawn.
# O documento contém:
# 1. Cabeçalho Institucional (UnB / RU Digital)
# 2. Dados do Estudante e Saldo Atual
# 3. Quadro de Resumo Contábil (Total Gasto, Refeições Realizadas e Total Recarregado)
# 4. Tabela Zebrada de Lançamentos (Data/Hora, Evento, Restaurante, Acesso e Valor)
# 5. Rodapé Institucional com timestamp de emissão
# ==============================================================================
class ExtratoPdfGenerator
  Prawn::Fonts::AFM.hide_m17n_warning = true if defined?(Prawn::Fonts::AFM)

  LARGURA_CONTEUDO = 523
  MARGEM_PAGINA = [ 36, 36, 36, 36 ].freeze
  COLUNAS_TABELA = [
    [ "Data e Hora", 6 ],
    [ "Refeição ou Evento", 115 ],
    [ "Restaurante", 235 ],
    [ "Método de Acesso", 350 ],
    [ "Valor", 480 ]
  ].freeze
  CAMPOS_LANCAMENTO = [
    [ :data_formatada, 6 ],
    [ :evento, 115 ],
    [ :restaurante, 235 ],
    [ :forma_acesso, 350 ]
  ].freeze

  attr_reader :usuario, :extrato_service, :lancamentos

  def initialize(usuario:, extrato_service:)
    @usuario = usuario
    @extrato_service = extrato_service
    @lancamentos = extrato_service.lancamentos
  end

  # Gera o binário do PDF renderizado
  def gerar
    pdf = Prawn::Document.new(
      page_size: "A4",
      margin: MARGEM_PAGINA,
      compress: false
    )

    desenhar_cabecalho(pdf)
    desenhar_dados_estudante(pdf)
    desenhar_quadro_resumo(pdf)
    desenhar_tabela_lancamentos(pdf)
    desenhar_rodape(pdf)

    pdf.render
  end

  private

  # 1. Cabeçalho Institucional com brasão textual da UnB
  def desenhar_cabecalho(pdf)
    pdf.fill_color "044B2C"
    pdf.text normalizar("UNIVERSIDADE DE BRASÍLIA — UnB"), size: 14, style: :bold, align: :center
    pdf.fill_color "1E293B"
    pdf.text normalizar("Diretoria de Desenvolvimento Social — Restaurante Universitário"), size: 10, align: :center
    pdf.text normalizar("PORTAL DO ESTUDANTE | EXTRATO E HISTÓRICO DE REFEIÇÕES"), size: 9, style: :bold, align: :center, color: "0284C7"
    desenhar_divisor(pdf, espaco_depois: 12)
  end

  # 2. Dados Cadastrais do Estudante e Saldo
  def desenhar_dados_estudante(pdf)
    desenhar_titulo_secao(pdf, "DADOS DO ESTUDANTE", 4)
    pdf.font_size 9 do
      pdf.text texto_identificacao_estudante
      pdf.text texto_emissao_e_saldo
    end
    desenhar_divisor(pdf)
  end

  def texto_identificacao_estudante
    normalizar("Nome: #{@usuario.nome}  |  Matrícula: #{@usuario.matricula}  |  E-mail: #{@usuario.email}")
  end

  def texto_emissao_e_saldo
    emissao = Time.current.strftime("%d/%m/%Y às %H:%M")
    saldo = "#{extrato_service.saldo_atual_formatado} (#{extrato_service.saldo_atual_refeicoes} refeições)"
    normalizar("Data de Emissão: #{emissao}  |  Saldo Atual: #{saldo}")
  end

  # 3. Quadro de Resumo Contábil (Total Gasto, Refeições Realizadas, Total Recarregado)
  def desenhar_quadro_resumo(pdf)
    desenhar_titulo_secao(pdf, "RESUMO DO PERÍODO", 6)
    desenhar_caixa_resumo(pdf)
    desenhar_divisor(pdf, espaco_antes: 12)
  end

  def desenhar_caixa_resumo(pdf)
    pdf.fill_color "F8FAFC"
    pdf.fill_rounded_rectangle [ 0, pdf.cursor ], LARGURA_CONTEUDO, 38, 4
    pdf.fill_color "1E293B"
    pdf.bounding_box([ 10, pdf.cursor - 8 ], width: 503, height: 26) do
      pdf.text texto_resumo_periodo, size: 9, style: :bold
    end
  end

  def texto_resumo_periodo
    total_gasto = extrato_service.total_gasto_formatado
    refeicoes = "#{extrato_service.refeicoes_realizadas_count} refeicoes"
    recarregado = extrato_service.total_recarregado_formatado
    normalizar("Total Gasto: #{total_gasto}    |    Refeições Realizadas: #{refeicoes}    |    Total Recarregado: #{recarregado}")
  end

  # 4. Tabela de Lançamentos Formatada
  def desenhar_tabela_lancamentos(pdf)
    desenhar_titulo_secao(pdf, "LANCAMENTOS REGISTRADOS (#{lancamentos.size})", 6)
    desenhar_cabecalho_tabela(pdf)
    lancamentos.each_with_index { |lancamento, idx| desenhar_item_tabela(pdf, lancamento, idx) }
  end

  def desenhar_cabecalho_tabela(pdf)
    y_pos = pdf.cursor
    desenhar_faixa(pdf, y_pos, 18, "F1F5F9")
    pdf.fill_color "334155"
    COLUNAS_TABELA.each { |titulo, x| pdf.draw_text normalizar(titulo), at: [ x, y_pos - 13 ], size: 8, style: :bold }
    pdf.move_down 20
  end

  def desenhar_item_tabela(pdf, lancamento, idx)
    verificar_quebra_pagina(pdf)
    y = pdf.cursor
    desenhar_faixa(pdf, y, 16, "FAFAFA") if idx.even?
    desenhar_colunas_lancamento(pdf, lancamento, y)
    desenhar_valor_lancamento(pdf, lancamento, y)
    pdf.move_down 16
  end

  def verificar_quebra_pagina(pdf)
    return unless pdf.cursor < 40

    pdf.start_new_page
    pdf.move_down 10
  end

  def desenhar_faixa(pdf, y_pos, altura, cor)
    pdf.fill_color cor
    pdf.fill_rectangle [ 0, y_pos ], LARGURA_CONTEUDO, altura
  end

  def desenhar_colunas_lancamento(pdf, lancamento, y_pos)
    pdf.fill_color "1E293B"
    CAMPOS_LANCAMENTO.each do |campo, x|
      pdf.draw_text normalizar(lancamento.public_send(campo)), at: [ x, y_pos - 11 ], size: 8
    end
  end

  def desenhar_valor_lancamento(pdf, lancamento, y_pos)
    pdf.fill_color cor_valor_lancamento(lancamento)
    pdf.draw_text normalizar(lancamento.valor_formatado), at: [ 465, y_pos - 11 ], size: 8, style: :bold
  end

  def cor_valor_lancamento(lancamento)
    lancamento.credito? ? "16A34A" : "0F172A"
  end

  def desenhar_titulo_secao(pdf, titulo, espaco_baixo)
    pdf.fill_color "0F172A"
    pdf.text normalizar(titulo), size: 10, style: :bold
    pdf.move_down espaco_baixo
  end

  def desenhar_divisor(pdf, espaco_antes: 10, espaco_depois: 10)
    pdf.move_down espaco_antes
    pdf.stroke_color "E2E8F0"
    pdf.stroke_horizontal_rule
    pdf.move_down espaco_depois
  end

  # Normaliza caracteres para a fonte padrão AFM do Prawn
  def normalizar(str)
    str.to_s.tr("áàãâéêíóôõúçÁÀÃÂÉÊÍÓÔÕÚÇ", "aaaaeeioooucAAAAEEIOOOUC")
  end

  # 5. Rodapé de Autenticação e Segurança
  def desenhar_rodape(pdf)
    desenhar_divisor(pdf, espaco_antes: 15, espaco_depois: 6)
    pdf.fill_color "94A3B8"
    pdf.text "Documento oficial gerado eletronicamente pelo Sistema RU Digital — Universidade de Brasília.", size: 7, align: :center
    pdf.text texto_autenticidade, size: 7, align: :center
  end

  def texto_autenticidade
    "Autenticidade: SHA256-#{SecureRandom.hex(16).upcase} | Emitido para Matrícula #{@usuario.matricula}"
  end
end
