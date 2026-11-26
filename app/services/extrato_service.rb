# frozen_string_literal: true

# Service de consolidação contábil do extrato do estudante (Issue #11).
# Unifica em tempo de execução, conforme a 3FN do banco de dados, as recargas
# pagas (créditos) e os acessos autorizados aos restaurantes (débitos), aplicando
# filtros de período, tipo de refeição/evento e forma de acesso, além de calcular
# os totalizadores dos cards do Figma US04.
class ExtratoService
  # Tarifa padrão da refeição em centavos (R$ 4,50) usada como fallback e conversão de saldo.
  TARIFA_UNITARIA_CENTAVOS = 450

  # Mapeamento de expressões regulares de período de filtro para lambdas que calculam a data de corte.
  PERIODOS = {
    /30/ => -> { 30.days.ago.beginning_of_day },
    /7/ => -> { 7.days.ago.beginning_of_day },
    /m[eê]s/ => -> { Time.current.beginning_of_month }
  }.freeze

  # Estrutura unificada que representa um lançamento contábil individual (crédito ou débito) no extrato.
  Lancamento = Struct.new(
    :id,
    :tipo_registro,
    :data_hora,
    :evento,
    :restaurante,
    :forma_acesso,
    :tipo_fluxo,
    :valor_centavos
  ) do
    # Formata o valor monetário do lançamento com sinal (+/-) no padrão brasileiro.
    #
    # Argumentos:
    # * Nenhum (lê +valor_centavos+ e +credito?+).
    #
    # Retorno:
    # * [String] Valor formatado com sinal (ex: +"+ R$ 45,00"+ ou +"- R$ 4,50"+).
    #
    # Efeitos colaterais:
    # * Nenhum.
    def valor_formatado
      reais = valor_centavos / 100.0
      sinal = credito? ? "+" : "-"
      "#{sinal} R$ #{sprintf('%.2f', reais).tr('.', ',')}"
    end

    # Indica se o lançamento representa uma entrada de créditos (recarga).
    #
    # Argumentos:
    # * Nenhum.
    #
    # Retorno:
    # * [Boolean] +true+ quando +tipo_fluxo == :credito+; +false+ caso contrário.
    #
    # Efeitos colaterais:
    # * Nenhum.
    def credito?
      tipo_fluxo == :credito
    end

    # Indica se o lançamento representa uma saída de créditos (consumo de refeição).
    #
    # Argumentos:
    # * Nenhum.
    #
    # Retorno:
    # * [Boolean] +true+ quando +tipo_fluxo == :debito+; +false+ caso contrário.
    #
    # Efeitos colaterais:
    # * Nenhum.
    def debito?
      tipo_fluxo == :debito
    end

    # Formata a data e hora do lançamento no padrão brasileiro (+dd/mm/aaaa às HH:MM+).
    #
    # Argumentos:
    # * Nenhum (lê +data_hora+).
    #
    # Retorno:
    # * [String] Data e hora formatadas (ex: +"25/11/2026 às 12:30"+).
    #
    # Efeitos colaterais:
    # * Nenhum.
    def data_formatada
      data_hora.strftime("%d/%m/%Y às %H:%M")
    end
  end

  # Estudante titular do extrato consultado.
  attr_reader :usuario

  # Hash simbolizado com os filtros recebidos (+:periodo+, +:tipo_refeicao+, +:forma_acesso+).
  attr_reader :filtros

  # Inicializa o serviço de extrato para um estudante e um conjunto opcional de filtros.
  #
  # Argumentos:
  # * +usuario+ [Usuario] - Estudante cujos lançamentos serão consolidados.
  # * +filtros+ [Hash, ActionController::Parameters] - Filtros opcionais de consulta (padrão: +{}+).
  #
  # Retorno:
  # * [ExtratoService] Nova instância configurada do serviço.
  #
  # Efeitos colaterais:
  # * Armazena +@usuario+ e +@filtros+ simbolizados na instância.
  def initialize(usuario, filtros = {})
    @usuario = usuario
    @filtros = filtros.to_h.symbolize_keys
  end

  # Retorna a lista consolidada, ordenada e filtrada de lançamentos do estudante (com memoização).
  #
  # Argumentos:
  # * Nenhum.
  #
  # Retorno:
  # * [Array<Lancamento>] Lista de lançamentos ordenada do mais recente para o mais antigo.
  #
  # Efeitos colaterais:
  # * Na primeira chamada, consulta o banco (+recargas+ e +acessos+) e armazena o resultado em +@lancamentos+.
  def lancamentos
    @lancamentos ||= consolidar_lancamentos
  end

  # Soma o valor total gasto em acessos autorizados dentro dos lançamentos filtrados.
  #
  # Argumentos:
  # * Nenhum.
  #
  # Retorno:
  # * [Integer] Total gasto em centavos.
  #
  # Efeitos colaterais:
  # * Pode acionar o carregamento memoizado de +lancamentos+.
  def total_gasto_centavos
    lancamentos.select(&:debito?).sum(&:valor_centavos)
  end

  # Retorna o total gasto no período formatado em reais no padrão brasileiro.
  #
  # Argumentos:
  # * Nenhum.
  #
  # Retorno:
  # * [String] Valor monetário formatado (ex: +"R$ 9,00"+).
  #
  # Efeitos colaterais:
  # * Pode acionar o carregamento memoizado de +lancamentos+.
  def total_gasto_formatado
    formatar_moeda(total_gasto_centavos)
  end

  # Conta quantas refeições (lançamentos de débito) foram realizadas nos lançamentos filtrados.
  #
  # Argumentos:
  # * Nenhum.
  #
  # Retorno:
  # * [Integer] Quantidade de acessos autorizados no conjunto filtrado.
  #
  # Efeitos colaterais:
  # * Pode acionar o carregamento memoizado de +lancamentos+.
  def refeicoes_realizadas_count
    lancamentos.select(&:debito?).size
  end

  # Soma o valor total recarregado (créditos pagos) dentro dos lançamentos filtrados.
  #
  # Argumentos:
  # * Nenhum.
  #
  # Retorno:
  # * [Integer] Total recarregado em centavos.
  #
  # Efeitos colaterais:
  # * Pode acionar o carregamento memoizado de +lancamentos+.
  def total_recarregado_centavos
    lancamentos.select(&:credito?).sum(&:valor_centavos)
  end

  # Retorna o total recarregado no período formatado em reais no padrão brasileiro.
  #
  # Argumentos:
  # * Nenhum.
  #
  # Retorno:
  # * [String] Valor monetário formatado (ex: +"R$ 45,00"+).
  #
  # Efeitos colaterais:
  # * Pode acionar o carregamento memoizado de +lancamentos+.
  def total_recarregado_formatado
    formatar_moeda(total_recarregado_centavos)
  end

  # Retorna o saldo atual da carteira do estudante formatado em reais.
  #
  # Argumentos:
  # * Nenhum.
  #
  # Retorno:
  # * [String] Saldo formatado (ex: +"R$ 18,00"+), ou +"R$ 0,00"+ se não houver carteira.
  #
  # Efeitos colaterais:
  # * Pode consultar a associação +carteira+ do estudante.
  def saldo_atual_formatado
    saldo = @usuario.carteira&.saldo_centavos || 0
    formatar_moeda(saldo)
  end

  # Converte o saldo atual da carteira do estudante para o número inteiro de refeições.
  #
  # Argumentos:
  # * Nenhum.
  #
  # Retorno:
  # * [Integer] Quantidade inteira de refeições disponíveis (ou +0+ sem carteira).
  #
  # Efeitos colaterais:
  # * Pode consultar a associação +carteira+ do estudante.
  def saldo_atual_refeicoes
    saldo = @usuario.carteira&.saldo_centavos || 0
    saldo / TARIFA_UNITARIA_CENTAVOS
  end

  private

  # Unifica recargas pagas e acessos autorizados em memória, ordena por data decrescente e aplica filtros.
  #
  # Argumentos:
  # * Nenhum.
  #
  # Retorno:
  # * [Array<Lancamento>] Lista final consolidada, ordenada e filtrada.
  #
  # Efeitos colaterais:
  # * Executa consultas de leitura nas tabelas +recargas+ e +acessos+.
  def consolidar_lancamentos
    lista = carregar_recargas + carregar_acessos
    lista.sort_by! { |l| l.data_hora || Time.zone.at(0) }.reverse!
    aplicar_filtros(lista)
  end

  # Busca todas as recargas pagas do estudante e converte cada registro em +Lancamento+.
  #
  # Argumentos:
  # * Nenhum.
  #
  # Retorno:
  # * [Array<Lancamento>] Lista de lançamentos de crédito.
  #
  # Efeitos colaterais:
  # * Executa consulta de leitura na tabela +recargas+.
  def carregar_recargas
    usuario.recargas.where(status: "paga").map { |recarga| montar_lancamento_recarga(recarga) }
  end

  # Constrói a struct +Lancamento+ de crédito a partir de um registro +Recarga+.
  #
  # Argumentos:
  # * +recarga+ [Recarga] - Registro pago de recarga do estudante.
  #
  # Retorno:
  # * [Lancamento] Struct preenchida com tipo +:recarga+ e fluxo +:credito+.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def montar_lancamento_recarga(recarga)
    Lancamento.new(
      "recarga-#{recarga.id}",
      :recarga,
      recarga.created_at,
      "Recarga de Saldo",
      "Portal Online",
      recarga.metodo_pagamento || "PIX Instantâneo",
      :credito,
      recarga.valor_centavos
    )
  end

  # Busca todos os acessos autorizados do estudante com eager loading e converte cada registro em +Lancamento+.
  #
  # Argumentos:
  # * Nenhum.
  #
  # Retorno:
  # * [Array<Lancamento>] Lista de lançamentos de débito.
  #
  # Efeitos colaterais:
  # * Executa consulta de leitura nas tabelas +acessos+, +turnos+, +catracas+ e +restaurantes+.
  def carregar_acessos
    usuario.acessos.where(autorizado: true).includes(:turno, catraca: :restaurante).map do |acesso|
      montar_lancamento_acesso(acesso)
    end
  end

  # Constrói a struct +Lancamento+ de débito a partir de um registro +Acesso+.
  #
  # Argumentos:
  # * +acesso+ [Acesso] - Registro autorizado de acesso ao restaurante.
  #
  # Retorno:
  # * [Lancamento] Struct preenchida com tipo +:acesso+ e fluxo +:debito+.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def montar_lancamento_acesso(acesso)
    Lancamento.new(
      "acesso-#{acesso.id}",
      :acesso,
      acesso.data_hora || acesso.created_at,
      acesso.turno&.nome || "Refeição",
      restaurante_do_acesso(acesso),
      acesso.forma_acesso.presence || "QR Code App",
      :debito,
      acesso.valor_pago_centavos || TARIFA_UNITARIA_CENTAVOS
    )
  end

  # Obtém e formata o nome resumido do restaurante associado a um acesso.
  #
  # Argumentos:
  # * +acesso+ [Acesso] - Registro de acesso com catraca e restaurante associados.
  #
  # Retorno:
  # * [String] Nome simplificado do campus/restaurante (ou +"Darcy Ribeiro"+ como fallback).
  #
  # Efeitos colaterais:
  # * Nenhum.
  def restaurante_do_acesso(acesso)
    formatar_restaurante(acesso.catraca&.restaurante)
  end

  # Aplica em sequência os filtros de período, tipo de refeição/evento e forma de acesso.
  #
  # Argumentos:
  # * +lista+ [Array<Lancamento>] - Lista consolidada de lançamentos.
  #
  # Retorno:
  # * [Array<Lancamento>] Subconjunto de lançamentos que atendem a todos os filtros ativos.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def aplicar_filtros(lista)
    lista = filtrar_por_periodo(lista)
    lista = filtrar_por_tipo(lista)
    filtrar_por_forma_acesso(lista)
  end

  # Filtra a lista de lançamentos mantendo apenas os ocorridos a partir da data limite do período.
  #
  # Argumentos:
  # * +lista+ [Array<Lancamento>] - Lista de lançamentos a filtrar.
  #
  # Retorno:
  # * [Array<Lancamento>] Lista filtrada por período, ou a lista original se não houver período válido.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def filtrar_por_periodo(lista)
    data_limite = calcular_data_limite(filtros[:periodo])
    return lista unless data_limite

    lista.select { |l| l.data_hora && l.data_hora >= data_limite }
  end

  # Determina a data inicial de corte correspondente ao texto do filtro de período.
  #
  # Argumentos:
  # * +periodo+ [String, nil] - Texto do filtro de período (ex: +"Últimos 30 dias"+, +"Últimos 7 dias"+, +"Mês Atual"+).
  #
  # Retorno:
  # * [ActiveSupport::TimeWithZone, nil] Instante de início do período correspondente, ou +nil+ quando ausente/desconhecido.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def calcular_data_limite(periodo)
    return nil if periodo.blank?

    texto = periodo.to_s.downcase
    _, calculo = PERIODOS.find { |padrao, _| texto.match?(padrao) }
    calculo&.call
  end

  # Filtra a lista pelo tipo de refeição ou evento selecionado (+:tipo_refeicao+).
  #
  # Argumentos:
  # * +lista+ [Array<Lancamento>] - Lista de lançamentos a filtrar.
  #
  # Retorno:
  # * [Array<Lancamento>] Lista filtrada por tipo/evento, ou a lista original se o filtro não estiver ativo.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def filtrar_por_tipo(lista)
    return lista unless filtro_ativo?(:tipo_refeicao)

    tipo = filtros[:tipo_refeicao].to_s.downcase
    lista.select { |l| corresponde_ao_tipo?(l, tipo) }
  end

  # Avalia se um lançamento individual corresponde ao termo de filtro de tipo/evento.
  #
  # Argumentos:
  # * +lancamento+ [Lancamento] - Lançamento avaliado.
  # * +tipo+ [String] - Termo de busca já convertido para minúsculas.
  #
  # Retorno:
  # * [Boolean] +true+ se for crédito (quando busca recarga) ou se o evento contiver +tipo+; +false+ caso contrário.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def corresponde_ao_tipo?(lancamento, tipo)
    return lancamento.credito? if tipo.include?("recarga")

    lancamento.evento.to_s.downcase.include?(tipo)
  end

  # Filtra a lista pela forma de acesso ou pagamento selecionada (+:forma_acesso+).
  #
  # Argumentos:
  # * +lista+ [Array<Lancamento>] - Lista de lançamentos a filtrar.
  #
  # Retorno:
  # * [Array<Lancamento>] Lista filtrada por forma de acesso, ou a lista original se o filtro não estiver ativo.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def filtrar_por_forma_acesso(lista)
    return lista unless filtro_ativo?(:forma_acesso)

    forma = filtros[:forma_acesso].to_s.downcase
    lista.select { |l| l.forma_acesso.to_s.downcase.include?(forma) }
  end

  # Verifica se uma chave de filtro está preenchida e difere da opção neutra +"Todas"+.
  #
  # Argumentos:
  # * +chave+ [Symbol] - Nome da chave em +filtros+ (ex: +:tipo_refeicao+, +:forma_acesso+).
  #
  # Retorno:
  # * [Boolean] +true+ se o filtro deve ser aplicado; +false+ caso contrário.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def filtro_ativo?(chave)
    filtros[chave].present? && filtros[chave] != "Todas"
  end

  # Simplifica o nome do restaurante removendo prefixos institucionais longos.
  #
  # Argumentos:
  # * +restaurante+ [Restaurante, nil] - Instância do restaurante associado à catraca.
  #
  # Retorno:
  # * [String] Nome enxuto do campus/restaurante, ou +"Darcy Ribeiro"+ quando +restaurante+ é +nil+.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def formatar_restaurante(restaurante)
    return "Darcy Ribeiro" unless restaurante

    nome = restaurante.campus.presence || restaurante.nome.to_s
    nome.sub(/\A(Restaurante\s+Universit[aá]rio\s*-\s*|RU\s*-\s*|RU\s+)/i, "").strip
  end

  # Formata um valor em centavos para string monetária brasileira com prefixo +"R$ "+.
  #
  # Argumentos:
  # * +centavos+ [Integer, nil] - Valor financeiro em centavos.
  #
  # Retorno:
  # * [String] Valor formatado (ex: +"R$ 18,00"+).
  #
  # Efeitos colaterais:
  # * Nenhum.
  def formatar_moeda(centavos)
    reais = (centavos || 0) / 100.0
    "R$ #{sprintf('%.2f', reais).tr('.', ',')}"
  end
end
