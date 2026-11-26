# Modelo que representa um restaurante universitário e suas associações com
# catracas e cardápios, aplicando regras de unicidade de nome e proteção
# contra exclusão quando há catracas associadas.
class Restaurante < ApplicationRecord
  has_many :catracas
  has_many :cardapios, dependent: :destroy

  before_validation { self.ativo = true if ativo.nil? }
  before_destroy :nao_remover_com_catracas, prepend: true

  validates :nome, presence: { message: "não pode ficar em branco" }
  validate :nome_unico

  private

  # :doc:
  # Verifica se já existe outro restaurante cadastrado com o mesmo nome,
  # ignorando diferenças de maiúsculas/minúsculas e espaços nas extremidades.
  #
  # Argumentos::
  #   Nenhum.
  # Retorno::
  #   Retorna +nil+ antecipadamente se +nome+ estiver em branco; caso contrário,
  #   retorna o resultado da avaliação de +errors.add+ (verdadeiro, falso ou
  #   +nil+).
  # Efeitos colaterais::
  #   Consulta a tabela de restaurantes no banco e adiciona uma mensagem de
  #   erro em +errors[:base]+ caso encontre duplicidade.
  def nome_unico
    return if nome.blank?

    outros = Restaurante.where("LOWER(nome) = ?", nome.strip.downcase)
    outros = outros.where.not(id: id) if persisted?
    errors.add(:base, "Já existe um restaurante com este nome") if outros.exists?
  end

  # :doc:
  # Bloqueia a exclusão do restaurante caso existam catracas vinculadas a ele.
  #
  # Argumentos::
  #   Nenhum.
  # Retorno::
  #   Retorna +nil+ se não houver catracas vinculadas; caso contrário,
  #   interrompe o callback de destruição via +throw :abort+.
  # Efeitos colaterais::
  #   Consulta as catracas associadas no banco, adiciona erro em
  #   +errors[:base]+ e aborta a remoção do registro quando existem catracas.
  def nao_remover_com_catracas
    return unless catracas.exists?

    errors.add(:base, "Remova as catracas deste restaurante antes de excluí-lo")
    throw :abort
  end
end