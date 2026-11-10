class SorteioFastpass < ApplicationRecord
  belongs_to :turno
  has_many :inscricoes_fastpass, dependent: :destroy
  has_many :notificacoes, dependent: :destroy

  validates :data_sorteio, :status, :vagas_disponiveis, presence: true
  validates :vagas_disponiveis, numericality: { greater_than_or_equal_to: 0 }
end
