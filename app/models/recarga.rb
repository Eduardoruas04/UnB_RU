class Recarga < ApplicationRecord
  belongs_to :usuario
  belongs_to :carteira

  validates :quantidade_refeicoes, :valor_centavos, :status, :metodo_pagamento, presence: true
  validates :valor_centavos, numericality: { greater_than: 0 }
end
