class Acesso < ApplicationRecord
  belongs_to :usuario
  belongs_to :catraca
  belongs_to :turno
  has_one :avaliacao, dependent: :destroy

  validates :data_hora, presence: true
  validates :valor_pago_centavos, numericality: { greater_than_or_equal_to: 0 }
  validates :forma_acesso, presence: true
end
