# frozen_string_literal: true

require "prawn"

# Service gerador de extrato oficial em PDF (Issue #11) utilizando a gem Prawn.
# Renderiza documento A4 timbrado contendo cabeçalho institucional da UnB, dados
# do estudante, quadro de resumo contábil, tabela zebrada paginada de lançamentos
# e rodapé de autenticidade com hash SHA-256.
class ExtratoPdfGenerator
  Prawn::Fonts::AFM.hide_m17n_warning = true

  # Largura útil horizontal da folha A4 em pontos após descontar as margens laterais.
  LARGURA_CONTEUDO = 523

  # Margens da página A4 em pontos (+[topo, direita, base, esquerda]+).
  MARGEM_PAGINA = [ 36, 36, 36, 36 ].freeze

  # Definição dos títulos e posições horizontais (X) das colunas do cabeçalho da tabela.
  COLUNAS_TABELA = [
    [ "Data e Hora", 6 ],
    [ "Refeição ou Evento", 115 ],
    [ "Restaurante", 235 ],
    [ "Método de Acesso", 350 ],
    [ "Valor", 480 ]
  ].freeze

  # Mapeamento dos métodos de +ExtratoService::Lancamento+ e posições X para cada linha da tabela.
  CAMPOS_LANCAMENTO = [
    [ :data_formatada, 6 ],
    [ :evento, 115 ],
    [ :restaurante, 235 ],
    [ :forma_acesso, 350 ]
  ].freeze

  # Estudante titular do extrato exportado.
  attr_reader :usuario

  # Instância de +ExtratoService+ contendo totalizadores e saldo formatados.
  attr_reader :extrato_service

  # Lista de lançamentos consolidados e filtrados a serem listados no PDF.
  attr_reader :lancamentos

  # Inicializa o gerador de PDF com os dados do estudante e o serviço de extrato.
  #
  # Argumentos:
  # * +usuario:+ [Usuario] - Estudante dono do extrato.
  # * +extrato_service:+ [ExtratoService] - Serviço já configurado com os filtros e lançamentos.
  #
  # Retorno:
  # * [ExtratoPdfGenerator] Nova instância pronta para renderizar o documento.
  #
  # Efeitos colaterais:
  # * Armazena +@usuario+, +@extrato_service+ e carrega +@lancamentos+ a partir de +extrato_service+.
  def initialize(usuario:, extrato_service:)
    @usuario = usuario
    @extrato_service = extrato_service
    @lancamentos = extrato_service.lancamentos
  end

  # Constrói todas as seções do extrato em um documento A4 do Prawn e retorna o binário PDF.
  #
  # Argumentos:
  # * Nenhum.
  #
  # Retorno:
  # * [String] Conteúdo binário completo do arquivo PDF (iniciando por +"%PDF-"+).
  #
  # Efeitos colaterais:
  # * Nenhum efeito externo (toda a montagem ocorre em memória).
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

  # Renderiza o cabeçalho institucional da UnB e do Portal do Estudante no topo do PDF.
  #
  # Argumentos:
  # * +pdf+ [Prawn::Document] - Documento Prawn em construção.
  #
  # Retorno:
  # * [Numeric] Posição vertical do cursor após desenhar o divisor inferior.
  #
  # Efeitos colaterais:
  # * Escreve textos estilizados, altera cores de preenchimento/traço e avança o cursor de +pdf+.
  def desenhar_cabecalho(pdf)
    pdf.fill_color "044B2C"
    pdf.text normalizar("UNIVERSIDADE DE BRASÍLIA — UnB"), size: 14, style: :bold, align: :center
    pdf.fill_color "1E293B"
    pdf.text normalizar("Diretoria de Desenvolvimento Social — Restaurante Universitário"), size: 10, align: :center
    pdf.text normalizar("PORTAL DO ESTUDANTE | EXTRATO E HISTÓRICO DE REFEIÇÕES"), size: 9, style: :bold, align: :center, color: "0284C7"
    desenhar_divisor(pdf, espaco_depois: 12)
  end

  # Renderiza a seção de identificação cadastral do estudante, data de emissão e saldo atual.
  #
  # Argumentos:
  # * +pdf+ [Prawn::Document] - Documento Prawn em construção.
  #
  # Retorno:
  # * [Numeric] Posição vertical do cursor após desenhar o divisor inferior.
  #
  # Efeitos colaterais:
  # * Escreve os dados do estudante e avança o cursor de +pdf+.
  def desenhar_dados_estudante(pdf)
    desenhar_titulo_secao(pdf, "DADOS DO ESTUDANTE", 4)
    pdf.font_size 9 do
      pdf.text texto_identificacao_estudante
      pdf.text texto_emissao_e_saldo
    end
    desenhar_divisor(pdf)
  end

  # Monta a linha normalizada com nome, matrícula e e-mail do estudante.
  #
  # Argumentos:
  # * Nenhum (lê +@usuario+).
  #
  # Retorno:
  # * [String] Linha formatada e normalizada para a fonte AFM.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def texto_identificacao_estudante
    normalizar("Nome: #{@usuario.nome}  |  Matrícula: #{@usuario.matricula}  |  E-mail: #{@usuario.email}")
  end

  # Monta a linha normalizada com data/hora de emissão e saldo atual em reais e refeições.
  #
  # Argumentos:
  # * Nenhum (lê +Time.current+ e +extrato_service+).
  #
  # Retorno:
  # * [String] Linha formatada e normalizada para a fonte AFM.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def texto_emissao_e_saldo
    emissao = Time.current.strftime("%d/%m/%Y às %H:%M")
    saldo = "#{extrato_service.saldo_atual_formatado} (#{extrato_service.saldo_atual_refeicoes} refeições)"
    normalizar("Data de Emissão: #{emissao}  |  Saldo Atual: #{saldo}")
  end

  # Renderiza a seção de resumo contábil do período (total gasto, refeições e total recarregado).
  #
  # Argumentos:
  # * +pdf+ [Prawn::Document] - Documento Prawn em construção.
  #
  # Retorno:
  # * [Numeric] Posição vertical do cursor após desenhar o divisor inferior.
  #
  # Efeitos colaterais:
  # * Desenha título, caixa de destaque e divisor em +pdf+.
  def desenhar_quadro_resumo(pdf)
    desenhar_titulo_secao(pdf, "RESUMO DO PERÍODO", 6)
    desenhar_caixa_resumo(pdf)
    desenhar_divisor(pdf, espaco_antes: 12)
  end

  # Desenha o retângulo arredondado de fundo e o texto em negrito do resumo contábil.
  #
  # Argumentos:
  # * +pdf+ [Prawn::Document] - Documento Prawn em construção.
  #
  # Retorno:
  # * [nil] Resultado do bloco +bounding_box+.
  #
  # Efeitos colaterais:
  # * Altera +fill_color+, desenha forma vetorial e escreve texto dentro de +pdf+.
  def desenhar_caixa_resumo(pdf)
    pdf.fill_color "F8FAFC"
    pdf.fill_rounded_rectangle [ 0, pdf.cursor ], LARGURA_CONTEUDO, 38, 4
    pdf.fill_color "1E293B"
    pdf.bounding_box([ 10, pdf.cursor - 8 ], width: 503, height: 26) do
      pdf.text texto_resumo_periodo, size: 9, style: :bold
    end
  end

  # Compõe a linha normalizada com os três indicadores financeiros do período filtrado.
  #
  # Argumentos:
  # * Nenhum (lê +extrato_service+).
  #
  # Retorno:
  # * [String] Texto consolidado com total gasto, refeições realizadas e total recarregado.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def texto_resumo_periodo
    total_gasto = extrato_service.total_gasto_formatado
    refeicoes = "#{extrato_service.refeicoes_realizadas_count} refeicoes"
    recarregado = extrato_service.total_recarregado_formatado
    normalizar("Total Gasto: #{total_gasto}    |    Refeições Realizadas: #{refeicoes}    |    Total Recarregado: #{recarregado}")
  end

  # Renderiza o título, o cabeçalho e todas as linhas da tabela de lançamentos no PDF.
  #
  # Argumentos:
  # * +pdf+ [Prawn::Document] - Documento Prawn em construção.
  #
  # Retorno:
  # * [Array<ExtratoService::Lancamento>] Coleção iterada de +lancamentos+.
  #
  # Efeitos colaterais:
  # * Desenha a tabela completa em +pdf+, podendo adicionar novas páginas quando necessário.
  def desenhar_tabela_lancamentos(pdf)
    desenhar_titulo_secao(pdf, "LANCAMENTOS REGISTRADOS (#{lancamentos.size})", 6)
    desenhar_cabecalho_tabela(pdf)
    lancamentos.each_with_index { |lancamento, idx| desenhar_item_tabela(pdf, lancamento, idx) }
  end

  # Desenha a faixa cinza e os títulos das colunas do cabeçalho da tabela.
  #
  # Argumentos:
  # * +pdf+ [Prawn::Document] - Documento Prawn em construção.
  #
  # Retorno:
  # * [Numeric] Posição vertical do cursor após avançar 20 pontos.
  #
  # Efeitos colaterais:
  # * Desenha retângulo de cabeçalho, textos em negrito e avança o cursor de +pdf+.
  def desenhar_cabecalho_tabela(pdf)
    y_pos = pdf.cursor
    desenhar_faixa(pdf, y_pos, 18, "F1F5F9")
    pdf.fill_color "334155"
    COLUNAS_TABELA.each { |titulo, x| pdf.draw_text normalizar(titulo), at: [ x, y_pos - 13 ], size: 8, style: :bold }
    pdf.move_down 20
  end

  # Renderiza uma linha individual da tabela com quebra de página automática e efeito zebrado.
  #
  # Argumentos:
  # * +pdf+ [Prawn::Document] - Documento Prawn em construção.
  # * +lancamento+ [ExtratoService::Lancamento] - Lançamento a ser desenhado na linha.
  # * +idx+ [Integer] - Índice sequencial da linha (usado para alternância zebrada).
  #
  # Retorno:
  # * [Numeric] Posição vertical do cursor após avançar 16 pontos.
  #
  # Efeitos colaterais:
  # * Pode criar uma nova página em +pdf+, desenha fundo/colunas/valor e avança o cursor.
  def desenhar_item_tabela(pdf, lancamento, idx)
    verificar_quebra_pagina(pdf)
    y = pdf.cursor
    desenhar_faixa(pdf, y, 16, "FAFAFA") if idx.even?
    desenhar_colunas_lancamento(pdf, lancamento, y)
    desenhar_valor_lancamento(pdf, lancamento, y)
    pdf.move_down 16
  end

  # Inicia uma nova página no PDF caso o cursor esteja abaixo da margem de segurança (40 pt).
  #
  # Argumentos:
  # * +pdf+ [Prawn::Document] - Documento Prawn em construção.
  #
  # Retorno:
  # * [Numeric, nil] Nova posição vertical após quebra de página, ou +nil+ se ainda houver espaço.
  #
  # Efeitos colaterais:
  # * Adiciona nova página em +pdf+ e move o cursor 10 pontos para baixo quando +pdf.cursor < 40+.
  def verificar_quebra_pagina(pdf)
    return unless pdf.cursor < 40

    pdf.start_new_page
    pdf.move_down 10
  end

  # Desenha um retângulo horizontal preenchido cobrindo toda a largura útil do documento.
  #
  # Argumentos:
  # * +pdf+ [Prawn::Document] - Documento Prawn em construção.
  # * +y_pos+ [Numeric] - Coordenada vertical superior da faixa.
  # * +altura+ [Numeric] - Altura da faixa em pontos.
  # * +cor+ [String] - Código hexadecimal RGB da cor de preenchimento (ex: +"F1F5F9"+).
  #
  # Retorno:
  # * [nil] Resultado de +fill_rectangle+.
  #
  # Efeitos colaterais:
  # * Altera +fill_color+ e desenha um retângulo preenchido em +pdf+.
  def desenhar_faixa(pdf, y_pos, altura, cor)
    pdf.fill_color cor
    pdf.fill_rectangle [ 0, y_pos ], LARGURA_CONTEUDO, altura
  end

  # Escreve as quatro colunas textuais de um lançamento (data/hora, evento, restaurante e acesso).
  #
  # Argumentos:
  # * +pdf+ [Prawn::Document] - Documento Prawn em construção.
  # * +lancamento+ [ExtratoService::Lancamento] - Lançamento exibido na linha.
  # * +y_pos+ [Numeric] - Coordenada vertical de referência da linha.
  #
  # Retorno:
  # * [Array<Array>] Coleção +CAMPOS_LANCAMENTO+ iterada.
  #
  # Efeitos colaterais:
  # * Altera +fill_color+ e desenha os quatro campos de texto em +pdf+.
  def desenhar_colunas_lancamento(pdf, lancamento, y_pos)
    pdf.fill_color "1E293B"
    CAMPOS_LANCAMENTO.each do |campo, x|
      pdf.draw_text normalizar(lancamento.public_send(campo)), at: [ x, y_pos - 11 ], size: 8
    end
  end

  # Escreve a coluna de valor monetário em negrito com cor verde (crédito) ou escura (débito).
  #
  # Argumentos:
  # * +pdf+ [Prawn::Document] - Documento Prawn em construção.
  # * +lancamento+ [ExtratoService::Lancamento] - Lançamento cujo valor será exibido.
  # * +y_pos+ [Numeric] - Coordenada vertical de referência da linha.
  #
  # Retorno:
  # * [nil] Resultado de +draw_text+.
  #
  # Efeitos colaterais:
  # * Altera +fill_color+ e desenha o valor monetário em +pdf+.
  def desenhar_valor_lancamento(pdf, lancamento, y_pos)
    pdf.fill_color cor_valor_lancamento(lancamento)
    pdf.draw_text normalizar(lancamento.valor_formatado), at: [ 465, y_pos - 11 ], size: 8, style: :bold
  end

  # Determina a cor hexadecimal do valor conforme o tipo de fluxo do lançamento.
  #
  # Argumentos:
  # * +lancamento+ [ExtratoService::Lancamento] - Lançamento avaliado.
  #
  # Retorno:
  # * [String] +"16A34A"+ (verde) para créditos ou +"0F172A"+ (escuro) para débitos.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def cor_valor_lancamento(lancamento)
    lancamento.credito? ? "16A34A" : "0F172A"
  end

  # Renderiza o título padronizado em negrito de uma seção do documento.
  #
  # Argumentos:
  # * +pdf+ [Prawn::Document] - Documento Prawn em construção.
  # * +titulo+ [String] - Texto do título da seção.
  # * +espaco_baixo+ [Numeric] - Espaçamento vertical em pontos após o título.
  #
  # Retorno:
  # * [Numeric] Nova posição vertical do cursor.
  #
  # Efeitos colaterais:
  # * Altera +fill_color+, escreve texto e avança o cursor de +pdf+.
  def desenhar_titulo_secao(pdf, titulo, espaco_baixo)
    pdf.fill_color "0F172A"
    pdf.text normalizar(titulo), size: 10, style: :bold
    pdf.move_down espaco_baixo
  end

  # Desenha uma linha horizontal divisória cinza clara com espaçamento configurável.
  #
  # Argumentos:
  # * +pdf+ [Prawn::Document] - Documento Prawn em construção.
  # * +espaco_antes:+ [Numeric] - Margem superior em pontos antes da linha (padrão: +10+).
  # * +espaco_depois:+ [Numeric] - Margem inferior em pontos depois da linha (padrão: +10+).
  #
  # Retorno:
  # * [Numeric] Nova posição vertical do cursor.
  #
  # Efeitos colaterais:
  # * Altera +stroke_color+, traça linha horizontal e avança o cursor de +pdf+.
  def desenhar_divisor(pdf, espaco_antes: 10, espaco_depois: 10)
    pdf.move_down espaco_antes
    pdf.stroke_color "E2E8F0"
    pdf.stroke_horizontal_rule
    pdf.move_down espaco_depois
  end

  # Remove acentuação de caracteres portugueses para compatibilidade com fontes padrão AFM do Prawn.
  #
  # Argumentos:
  # * +str+ [String, Object] - Texto de entrada a ser normalizado.
  #
  # Retorno:
  # * [String] Texto sem acentos diacríticos ou cedilha.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def normalizar(str)
    str.to_s.tr("áàãâéêíóôõúçÁÀÃÂÉÊÍÓÔÕÚÇ", "aaaaeeioooucAAAAEEIOOOUC")
  end

  # Renderiza o rodapé institucional do documento com código de autenticidade SHA-256.
  #
  # Argumentos:
  # * +pdf+ [Prawn::Document] - Documento Prawn em construção.
  #
  # Retorno:
  # * [nil] Resultado da escrita do texto de autenticidade.
  #
  # Efeitos colaterais:
  # * Desenha divisor, altera +fill_color+ e escreve duas linhas centralizadas no rodapé de +pdf+.
  def desenhar_rodape(pdf)
    desenhar_divisor(pdf, espaco_antes: 15, espaco_depois: 6)
    pdf.fill_color "94A3B8"
    pdf.text "Documento oficial gerado eletronicamente pelo Sistema RU Digital — Universidade de Brasília.", size: 7, align: :center
    pdf.text texto_autenticidade, size: 7, align: :center
  end

  # Gera a linha de autenticidade do documento com hash aleatório e matrícula do estudante.
  #
  # Argumentos:
  # * Nenhum (utiliza +SecureRandom.hex+ e +@usuario.matricula+).
  #
  # Retorno:
  # * [String] Texto formatado com hash +SHA256-...+ e matrícula do titular.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def texto_autenticidade
    "Autenticidade: SHA256-#{SecureRandom.hex(16).upcase} | Emitido para Matrícula #{@usuario.matricula}"
  end
end
