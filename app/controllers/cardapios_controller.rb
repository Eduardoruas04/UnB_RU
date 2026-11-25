# Cardápio da refeição que está sendo servida agora (Issue #10).
class CardapiosController < ApplicationController
  # Nomes dos dias da semana, na ordem de Date#wday (0 = domingo).
  DIAS_DA_SEMANA = %w[domingo segunda-feira terça-feira quarta-feira quinta-feira sexta-feira sábado].freeze

  # Mostra o cardápio do turno em atendimento, no horário de Brasília.
  #
  # Argumentos::
  #   Nenhum.
  # Retorno::
  #   Nenhum valor útil; renderiza a view +atual+.
  #   - Sem turno em atendimento: só +@turno+ é definido, como +nil+.
  #   - Com turno: define +@turno+, +@dia+ (nome do dia da semana) e
  #     +@cardapio+, o cardápio do dia em um restaurante ativo, que pode
  #     ser +nil+ se ainda não foi cadastrado.
  # Efeitos colaterais::
  #   Nenhum. Só faz consultas ao banco.
  def atual
    agora = Time.current.in_time_zone("America/Sao_Paulo")
    @turno = Turno.em_atendimento(agora)
    return if @turno.nil?

    @dia = DIAS_DA_SEMANA[agora.wday]
    @cardapio = Cardapio.joins(:restaurante)
                        .where(turno: @turno, data_refeicao: agora.to_date, restaurantes: { ativo: true })
                        .first
  end
end
