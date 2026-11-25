# frozen_string_literal: true

# ==============================================================================
# Service de Consolidação Contábil do Extrato (app/services/extrato_service.rb)
# ==============================================================================
# Responsável por unificar, em tempo de execução e conforme a 3FN do banco,
# as movimentações financeiras do estudante:
# - Créditos: Recargas pagas (status == 'paga')
# - Débitos: Acessos autorizados aos restaurantes (autorizado == true)
#
# Aplica filtros de período, tipo de refeição/evento e forma de acesso,
# calculando ainda os agregadores dos cards do Figma US04.
# ==============================================================================
class ExtratoService
  TARIFA_UNITARIA_CENTAVOS = 450
  PERIODOS = {
    /30/ => -> { 30.days.ago.beginning_of_day },
    /7/ => -> { 7.days.ago.beginning_of_day },
    /m[eê]s/ => -> { Time.current.beginning_of_month }
  }.freeze

  # Estrutura unificada representando um lançamento contábil no extrato
  Lancamento = Struct.new(
    :id,
    :tipo_registro, # :recarga ou :acesso
    :data_hora,     # DateTime
    :evento,        # "Recarga de Saldo", "Almoço", "Jantar", "Café da Manhã"
    :restaurante,   # "RU Darcy Ribeiro", "Portal Online"
    :forma_acesso,  # "QR Code App", "Carteirinha Física", "PIX Instantâneo", "Cartão de Crédito"
    :tipo_fluxo,    # :credito (+) ou :debito (-)
    :valor_centavos # integer
  ) do
    # Formata o valor monetário com sinal e padrão brasileiro (ex: "+ R$ 45,00" ou "- R$ 4,50")
    def valor_formatado
      reais = valor_centavos / 100.0
      sinal = credito? ? "+" : "-"
      "#{sinal} R$ #{sprintf('%.2f', reais).tr('.', ',')}"
    end

    def credito?
      tipo_fluxo == :credito
    end

    def debito?
      tipo_fluxo == :debito
    end

    def data_formatada
      data_hora.strftime("%d/%m/%Y às %H:%M")
    end
  end

  attr_reader :usuario, :filtros

  def initialize(usuario, filtros = {})
    @usuario = usuario
    @filtros = filtros.to_h.symbolize_keys
  end

  # Retorna a lista consolidada e filtrada de lançamentos ordenada do mais recente ao mais antigo
  def lancamentos
    @lancamentos ||= consolidar_lancamentos
  end

  # Indicador 1: Total gasto em acessos autorizados no mês atual (ou no período filtrado)
  def total_gasto_centavos
    lancamentos.select(&:debito?).sum(&:valor_centavos)
  end

  def total_gasto_formatado
    formatar_moeda(total_gasto_centavos)
  end

  # Indicador 2: Quantidade de refeições consumidas (acessos) no período
  def refeicoes_realizadas_count
    lancamentos.select(&:debito?).size
  end

  # Indicador 3: Total recarregado em dinheiro no período
  def total_recarregado_centavos
    lancamentos.select(&:credito?).sum(&:valor_centavos)
  end

  def total_recarregado_formatado
    formatar_moeda(total_recarregado_centavos)
  end

  # Saldo atual da carteira do estudante
  def saldo_atual_formatado
    saldo = @usuario.carteira&.saldo_centavos || 0
    formatar_moeda(saldo)
  end

  def saldo_atual_refeicoes
    saldo = @usuario.carteira&.saldo_centavos || 0
    saldo / TARIFA_UNITARIA_CENTAVOS
  end

  private

  # Unifica recargas e acessos em memória e aplica os filtros ativos
  def consolidar_lancamentos
    lista = carregar_recargas + carregar_acessos
    lista.sort_by! { |l| l.data_hora || Time.zone.at(0) }.reverse!
    aplicar_filtros(lista)
  end

  def carregar_recargas
    usuario.recargas.where(status: "paga").map { |recarga| montar_lancamento_recarga(recarga) }
  end

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

  def carregar_acessos
    usuario.acessos.where(autorizado: true).includes(:turno, catraca: :restaurante).map do |acesso|
      montar_lancamento_acesso(acesso)
    end
  end

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

  def restaurante_do_acesso(acesso)
    formatar_restaurante(acesso.catraca&.restaurante)
  end

  def aplicar_filtros(lista)
    lista = filtrar_por_periodo(lista)
    lista = filtrar_por_tipo(lista)
    filtrar_por_forma_acesso(lista)
  end

  def filtrar_por_periodo(lista)
    data_limite = calcular_data_limite(filtros[:periodo])
    return lista unless data_limite

    lista.select { |l| l.data_hora && l.data_hora >= data_limite }
  end

  def calcular_data_limite(periodo)
    return nil if periodo.blank?

    texto = periodo.to_s.downcase
    _, calculo = PERIODOS.find { |padrao, _| texto.match?(padrao) }
    calculo&.call
  end

  def filtrar_por_tipo(lista)
    return lista unless filtro_ativo?(:tipo_refeicao)

    tipo = filtros[:tipo_refeicao].to_s.downcase
    lista.select { |l| corresponde_ao_tipo?(l, tipo) }
  end

  def corresponde_ao_tipo?(lancamento, tipo)
    return lancamento.credito? if tipo.include?("recarga")

    lancamento.evento.to_s.downcase.include?(tipo)
  end

  def filtrar_por_forma_acesso(lista)
    return lista unless filtro_ativo?(:forma_acesso)

    forma = filtros[:forma_acesso].to_s.downcase
    lista.select { |l| l.forma_acesso.to_s.downcase.include?(forma) }
  end

  def filtro_ativo?(chave)
    filtros[chave].present? && filtros[chave] != "Todas"
  end

  # Simplifica o nome do restaurante removendo prefixos longos (ex: "Restaurante Universitário - ")
  def formatar_restaurante(restaurante)
    return "Darcy Ribeiro" unless restaurante

    nome = restaurante.campus.presence || restaurante.nome.to_s
    nome.sub(/\A(Restaurante\s+Universit[aá]rio\s*-\s*|RU\s*-\s*|RU\s+)/i, "").strip
  end

  def formatar_moeda(centavos)
    reais = (centavos || 0) / 100.0
    "R$ #{sprintf('%.2f', reais).tr('.', ',')}"
  end
end
