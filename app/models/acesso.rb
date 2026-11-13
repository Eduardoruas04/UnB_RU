class Acesso < ApplicationRecord
  belongs_to :usuario
  belongs_to :catraca
  belongs_to :turno
  has_one :avaliacao, dependent: :destroy

  validates :data_hora, presence: true
  validates :valor_pago_centavos, numericality: { greater_than_or_equal_to: 0 }
  validates :forma_acesso, presence: true

  def aguardando_passagem?
    autorizado? && valor_pago_centavos.to_i.zero? && motivo_recusa.nil?
  end

  # Débito da refeição no momento da passagem pela catraca.
  def confirmar_passagem!
    carteira = usuario.carteira
    preco = turno.valor_refeicao_centavos
    return false unless aguardando_passagem? && carteira && carteira.saldo_centavos >= preco

    transaction do
      carteira.update!(saldo_centavos: carteira.saldo_centavos - preco)
      update!(valor_pago_centavos: preco, data_hora: Time.current)
    end
    true
  end

  def encerrar_sem_passagem!
    return false unless aguardando_passagem?

    update!(autorizado: false, motivo_recusa: "Passagem não confirmada")
  end
end
