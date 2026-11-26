# frozen_string_literal: true

# Modelo ActiveRecord que representa uma operação de recarga de créditos de
# refeições na carteira de um estudante do Restaurante Universitário (Issue #2).
#
# Associações:
# * +belongs_to :usuario+ - Estudante titular da recarga.
# * +belongs_to :carteira+ - Carteira que receberá o crédito em centavos.
#
# Validações:
# * Presença obrigatória de +quantidade_refeicoes+, +valor_centavos+, +status+
#   e +metodo_pagamento+.
# * +valor_centavos+ deve ser um valor numérico estritamente positivo (> 0).
class Recarga < ApplicationRecord
  belongs_to :usuario
  belongs_to :carteira

  validates :quantidade_refeicoes, :valor_centavos, :status, :metodo_pagamento, presence: true
  validates :valor_centavos, numericality: { greater_than: 0 }
end
