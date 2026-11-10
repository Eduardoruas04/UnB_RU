class Turno < ApplicationRecord
  has_many :cardapios, dependent: :destroy
  has_many :acessos, dependent: :destroy
  has_many :sorteios_fastpass, dependent: :destroy

  validates :nome, :horario_inicio, :horario_fim, presence: true
  validates :valor_refeicao_centavos, numericality: { greater_than: 0 }
end
