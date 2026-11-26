# Mantém o saldo em centavos associado a um usuário.
class Carteira < ApplicationRecord
  belongs_to :usuario
  has_many :recargas, dependent: :destroy

  validates :saldo_centavos, numericality: { greater_than_or_equal_to: 0 }

  # Diz se o saldo da carteira paga um valor.
  #
  # Argumentos::
  #   +valor_centavos+ - o valor a pagar, em centavos.
  # Retorno::
  #   +true+ se o saldo é maior ou igual ao valor; +false+ caso contrário.
  # Efeitos colaterais::
  #   Nenhum.
  def cobre?(valor_centavos)
    saldo_centavos >= valor_centavos
  end

  # Desconta um valor do saldo da carteira.
  #
  # Argumentos::
  #   +valor_centavos+ - o valor a debitar, em centavos.
  # Retorno::
  #   +true+ quando o débito é gravado.
  # Efeitos colaterais::
  #   Atualiza +saldo_centavos+ no banco. Levanta
  #   ActiveRecord::RecordInvalid, sem gravar, se o saldo ficaria
  #   negativo.
  def debitar!(valor_centavos)
    update!(saldo_centavos: saldo_centavos - valor_centavos)
  end
end
