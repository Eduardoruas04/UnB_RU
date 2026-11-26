# Modelo que representa uma catraca de acesso vinculada a um restaurante,
# controlando seu status padrão e validando vínculo e unicidade do código.
class Catraca < ApplicationRecord
  belongs_to :restaurante, optional: true
  has_many :acessos, dependent: :destroy

  before_validation { self.status = "ativa" if status.blank? }

  validates :status, presence: true
  validate :validar_restaurante_e_identificador

  private

  # :doc:
  # Valida se há um restaurante associado e se o +codigo_identificador+ está
  # preenchido e não é duplicado entre outras catracas.
  #
  # Argumentos::
  #   Nenhum.
  # Retorno::
  #   O resultado da última expressão avaliada no bloco condicional
  #   (verdadeiro, falso ou +nil+).
  # Efeitos colaterais::
  #   Consulta a tabela de catracas no banco para checar duplicidade de
  #   +codigo_identificador+ e adiciona mensagens em +errors[:base]+ quando
  #   alguma validação falha.
  def validar_restaurante_e_identificador
    errors.add(:base, "Selecione um restaurante") if restaurante.blank?

    if codigo_identificador.blank?
      errors.add(:base, "Identificador não pode ficar em branco")
    elsif Catraca.where.not(id: id).exists?(codigo_identificador: codigo_identificador)
      errors.add(:base, "Já existe uma catraca com este identificador")
    end
  end
end
