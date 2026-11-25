# Registro de uma tentativa de entrada de um aluno pela catraca.
#
# Um acesso nasce liberado (aguardando passagem) ou recusado. Quando
# liberado, termina com a passagem confirmada (e a refeição debitada) ou
# encerrado sem passagem.
class Acesso < ApplicationRecord
  belongs_to :usuario
  belongs_to :catraca
  belongs_to :turno
  has_one :avaliacao, dependent: :destroy

  validates :data_hora, presence: true
  validates :valor_pago_centavos, numericality: { greater_than_or_equal_to: 0 }
  validates :forma_acesso, presence: true

  # Registra a leitura da matrícula na catraca, liberando a entrada se o
  # saldo do aluno cobre a refeição.
  #
  # Argumentos::
  #   +usuario+ - o Usuario (estudante) lido na catraca.
  #   +catraca+ - a Catraca onde a leitura aconteceu.
  #   +turno+ - o Turno em atendimento, que define o preço da refeição.
  # Retorno::
  #   O Acesso criado. Vem com +autorizado+ verdadeiro se o saldo cobre o
  #   preço; senão, +autorizado+ falso e +motivo_recusa+ "Saldo
  #   insuficiente" (inclusive quando o aluno não tem carteira).
  # Efeitos colaterais::
  #   Grava um Acesso no banco. Não debita a carteira: o débito só
  #   acontece em #confirmar_passagem!.
  def self.registrar_leitura!(usuario:, catraca:, turno:)
    liberado = usuario.carteira&.cobre?(turno.valor_refeicao_centavos) || false
    create!(usuario: usuario, catraca: catraca, turno: turno, autorizado: liberado,
            valor_pago_centavos: 0, motivo_recusa: ("Saldo insuficiente" unless liberado),
            data_hora: Time.current)
  end

  # Diz se o acesso foi liberado e ainda espera o aluno passar.
  #
  # Argumentos::
  #   Nenhum.
  # Retorno::
  #   +true+ se está autorizado, sem valor pago e sem motivo de recusa;
  #   +false+ caso contrário.
  # Efeitos colaterais::
  #   Nenhum.
  def aguardando_passagem?
    autorizado? && valor_pago_centavos.to_i.zero? && motivo_recusa.nil?
  end

  # Confirma a passagem do aluno e debita a refeição da carteira.
  #
  # Argumentos::
  #   Nenhum.
  # Retorno::
  #   +true+ se a passagem foi confirmada; +false+ se o acesso não está
  #   aguardando passagem ou se o saldo deixou de cobrir o preço.
  # Efeitos colaterais::
  #   Em uma transação, debita o preço do turno da carteira e grava o
  #   valor pago e o horário da passagem no acesso. Quando retorna
  #   +false+, não altera nada.
  def confirmar_passagem!
    carteira = usuario.carteira
    preco = turno.valor_refeicao_centavos
    return false unless aguardando_passagem? && carteira&.cobre?(preco)

    transaction do
      carteira.debitar!(preco)
      update!(valor_pago_centavos: preco, data_hora: Time.current)
    end
    true
  end

  # Encerra um acesso liberado em que o aluno não passou pela catraca.
  #
  # Argumentos::
  #   Nenhum.
  # Retorno::
  #   +true+ se o acesso foi encerrado; +false+ se ele não estava
  #   aguardando passagem.
  # Efeitos colaterais::
  #   Marca o acesso como não autorizado, com motivo "Passagem não
  #   confirmada". Não debita a carteira.
  def encerrar_sem_passagem!
    return false unless aguardando_passagem?

    update!(autorizado: false, motivo_recusa: "Passagem não confirmada")
  end
end
