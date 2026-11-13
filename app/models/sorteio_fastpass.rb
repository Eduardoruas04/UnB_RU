class SorteioFastpass < ApplicationRecord
  belongs_to :turno
  has_many :inscricoes_fastpass, dependent: :destroy
  has_many :notificacoes, dependent: :destroy

  validates :data_sorteio, :status, :vagas_disponiveis, presence: true
  validates :vagas_disponiveis, numericality: { greater_than_or_equal_to: 0 }
  # A data do sorteio representa o dia do turno ao qual o resultado se refere.
  def horario_fastpass
    horario = turno.horario_inicio.utc
    Time.use_zone("America/Sao_Paulo") do
      Time.zone.local(data_sorteio.year, data_sorteio.month, data_sorteio.day,
        horario.hour, horario.min, horario.sec)
    end
  end

  def horario_notificacao
    horario_fastpass - 1.hour
  end
end
