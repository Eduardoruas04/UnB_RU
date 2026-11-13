class Turno < ApplicationRecord
  has_many :cardapios, dependent: :destroy
  has_many :acessos, dependent: :destroy
  has_many :sorteios_fastpass, dependent: :destroy

  validates :nome, :horario_inicio, :horario_fim, presence: true
  validates :valor_refeicao_centavos, numericality: { greater_than: 0 }

  # Turno que está sendo servido no momento informado (horário de Brasília).
  def self.em_atendimento(momento = Time.current)
    hora = momento.in_time_zone("America/Sao_Paulo").strftime("%H:%M")
    all.find { |turno| hora >= turno.horario_inicio.strftime("%H:%M") && hora < turno.horario_fim.strftime("%H:%M") }
  end
end
