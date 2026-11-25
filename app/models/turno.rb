# Período de refeição do restaurante (por exemplo, almoço ou jantar),
# com horário de início, horário de fim e preço da refeição.
class Turno < ApplicationRecord
  has_many :cardapios, dependent: :destroy
  has_many :acessos, dependent: :destroy
  has_many :sorteios_fastpass, dependent: :destroy

  validates :nome, :horario_inicio, :horario_fim, presence: true
  validates :valor_refeicao_centavos, numericality: { greater_than: 0 }

  # Encontra o turno que está sendo servido em um dado momento.
  #
  # Argumentos::
  #   +momento+ - o instante a verificar (padrão: agora). É convertido
  #   para o horário de Brasília antes da comparação.
  # Retorno::
  #   O primeiro Turno cujo horário vai do início (inclusive) ao fim
  #   (exclusive) e contém o momento, ou +nil+ se nenhum turno estiver
  #   em atendimento.
  # Efeitos colaterais::
  #   Nenhum. Só consulta o banco.
  def self.em_atendimento(momento = Time.current)
    hora = momento.in_time_zone("America/Sao_Paulo").strftime("%H:%M")
    all.find { |turno| hora >= turno.horario_inicio.strftime("%H:%M") && hora < turno.horario_fim.strftime("%H:%M") }
  end
end
