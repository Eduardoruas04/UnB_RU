class Carteira < ApplicationRecord
  belongs_to :usuario
  has_many :recargas, dependent: :destroy

  validates :saldo_centavos, numericality: { greater_than_or_equal_to: 0 }

  def cobre?(valor_centavos)
    saldo_centavos >= valor_centavos
  end

  def debitar!(valor_centavos)
    update!(saldo_centavos: saldo_centavos - valor_centavos)
  end
end
