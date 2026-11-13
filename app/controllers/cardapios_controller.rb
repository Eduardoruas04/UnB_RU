# Issue #10 - Cardápio da refeição atual
class CardapiosController < ApplicationController
  DIAS_DA_SEMANA = %w[domingo segunda-feira terça-feira quarta-feira quinta-feira sexta-feira sábado].freeze

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
