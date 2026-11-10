class Carteira < ApplicationRecord
  belongs_to :usuario
  has_many :recargas, dependent: :destroy

  validates :saldo_centavos, numericality: { greater_than_or_equal_to: 0 }
end
